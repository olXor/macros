#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>
#include "trivialdampingfilterFourier.cuh"
#include "trivialdampingfilterInterpolate.cuh"
#include <chrono>

#define datastring ""
//#define datastring "D:/trivialNetworkTest/peakbinpacker/"

#define NUM_INPUTS 512
#define NUM_OUTPUTS 4
#define NUM_SILENT_OUTPUTS 12
#define HEADER_SIZE 8

#define MATH_PI 3.14159265358979323846

#define DERIV_SMOOTHING_RANGE 3

#define REMOVE_FLATLINES
#define FLATLINE_SEQ_POINTS 7

#define PRIMARY_OUTPUT_INDEX 1

#define FOURIER_PATCH_WIDTH_POW 9
#define FOURIER_PATCH_WIDTH (pow(2,FOURIER_PATCH_WIDTH_POW))
#define FOURIER_PATCH_PEAK_EDGE_SHRINK 0.3
#define FOURIER_PATCH_VALLEY_EDGE_SHRINK 0.05
#define FOURIER_SCALE_FACTOR 60.0f

#define NUM_SAMPLES_PER_PERSON 5000

std::vector<float> fourierRe;
std::vector<float> fourierIm;
std::vector<float> fourierAvg;
std::vector<float> fourierPatch;
std::vector<float> fourierFit;
std::vector<float> fourierFitCoef;
float fourierFitMinAmp = 2.0f;
float fourierFitMinMean = 40.0f;
float fourierFitMaxMean = 1000.0f;
float fourierFitMaxSigma = 100.0f;
float fourierFitMinMagRatio = 0.7f;
float fourierFitMinWidthRatio = 0.1f;

std::chrono::system_clock::time_point markedStartTime;

template <typename T> void randomizeVector(std::vector<T>* vec) {
	for (size_t i = 0; i < vec->size(); i++) {
		size_t j = (RAND_MAX*rand() + rand()) % vec->size();
		T tmp = (*vec)[i];
		(*vec)[i] = (*vec)[j];
		(*vec)[j] = tmp;
	}
}

void markTime() {
	markedStartTime = std::chrono::high_resolution_clock::now();
}

long long getTimeSinceMark() {
	auto elapsed = std::chrono::high_resolution_clock::now() - markedStartTime;
	long long time = std::chrono::duration_cast<std::chrono::microseconds>(elapsed).count();
	return time / 1000000;
}

int main() {
	srand((size_t)time(NULL));

	std::string filelist = "filelist";
	std::ifstream infilelist(datastring + filelist);
	if (!infilelist.is_open()) {
		std::cout << "Couldn't open file list " << datastring << filelist << std::endl;
	}

	std::string dampfolder;
	std::cout << "Enter folder to store damped results: ";
	std::cin >> dampfolder;

	if (dampfolder == "") {
		std::cout << "Must enter non-empty dampfolder" << std::endl;
		system("pause");
		return;
	}

	std::string fileline;
	std::vector<float> waveform(NUM_INPUTS);
	std::vector<float> deriv1(NUM_INPUTS);
	std::vector<float> deriv2(NUM_INPUTS);
	std::vector<float> peaks(NUM_INPUTS);
	while (std::getline(infilelist, fileline)) {
		std::string fname;
		(std::stringstream(fileline)) >> fname;
		std::cout << "Reading file " << fname << ": ";
		markTime();

		char* buf[HEADER_SIZE];
		FILE* infile = fopen((datastring + fname).c_str(), "rb");
		_fseeki64(infile, 0, SEEK_SET);
		fread(&buf, HEADER_SIZE, 1, infile);

		FILE* outfile = fopen((datastring + dampfolder + "/" + fname).c_str(), "wb");
		fwrite(&buf, HEADER_SIZE, 1, outfile);

		size_t numColumns = 2*NUM_INPUTS + NUM_OUTPUTS + NUM_SILENT_OUTPUTS;	//Peak data must be included.

		std::vector<float> columns(numColumns);
		std::vector<size_t> sampleIndices;
		float avgOut = 0;
		while (fread(&columns[0], sizeof(float), numColumns, infile) == numColumns) {
			sampleIndices.push_back(sampleIndices.size());
			avgOut += columns[PRIMARY_OUTPUT_INDEX];
		}
		randomizeVector(&sampleIndices);
		avgOut /= sampleIndices.size();
		std::cout << "Average Output: " << avgOut << " ";

		size_t curSampleIndex = 0;

		size_t numUnderdampedEntries = 0;
		size_t numFlatEntries = 0;
		_fseeki64(infile, HEADER_SIZE, SEEK_SET);
		for (size_t ent = 0; ent < NUM_SAMPLES_PER_PERSON; ent++) {
			size_t curSample = sampleIndices[curSampleIndex];
			_fseeki64(infile, HEADER_SIZE + numColumns*curSample*sizeof(float), SEEK_SET);
			fread(&columns[0], numColumns, sizeof(float), infile);

			float curIndexFloat = (float)curSample;
			curSampleIndex++;
			if (curSampleIndex > sampleIndices.size()) {
				curSampleIndex = 0;
				randomizeVector(&sampleIndices);
			}

#ifdef REMOVE_FLATLINES
			float lastVal = 9999;
			size_t flatSize = 0;
			for (size_t in = 0; in < NUM_INPUTS; in++) {
				float val = columns[in + NUM_OUTPUTS + NUM_SILENT_OUTPUTS];
				if (val == lastVal)
					flatSize++;
				else {
					flatSize = 0;
					lastVal = val;
				}
				if (flatSize > FLATLINE_SEQ_POINTS)
					break;
			}
			if (flatSize > FLATLINE_SEQ_POINTS) {
				numFlatEntries++;
				ent--;
				continue;
			}
#endif
			//extract waveform and derivatives
			float minVal = 99999;
			float maxVal = -99999;
			for (size_t i = 0; i < NUM_INPUTS; i++) {
				waveform[i] = columns[NUM_OUTPUTS + NUM_SILENT_OUTPUTS + i];
				minVal = std::min(minVal, waveform[i]);
				maxVal = std::max(maxVal, waveform[i]);
				peaks[i] = columns[NUM_OUTPUTS + NUM_SILENT_OUTPUTS + NUM_INPUTS + i];
			}

			deriv1.clear();
			for (size_t i = 0; i < DERIV_SMOOTHING_RANGE; i++)
				deriv1.push_back(0);
			for (size_t i = 0; i < waveform.size() - 2 * DERIV_SMOOTHING_RANGE; i++) {
				float backAvg = 0;
				for (size_t j = 0; j < DERIV_SMOOTHING_RANGE; j++) {
					backAvg += waveform[i + j];
				}
				backAvg /= DERIV_SMOOTHING_RANGE;
				float forwardAvg = 0;
				for (size_t j = 0; j < DERIV_SMOOTHING_RANGE; j++) {
					forwardAvg += waveform[i + DERIV_SMOOTHING_RANGE + j + 1];
				}
				forwardAvg /= DERIV_SMOOTHING_RANGE;
				deriv1.push_back(forwardAvg - backAvg);
			}
			for (size_t i = 0; i < DERIV_SMOOTHING_RANGE; i++)
				deriv1.push_back(0);

			deriv2.clear();
			for (size_t i = 0; i < DERIV_SMOOTHING_RANGE; i++)
				deriv2.push_back(0);
			for (size_t i = 0; i < deriv1.size() - 2 * DERIV_SMOOTHING_RANGE; i++) {
				float backAvg = 0;
				for (size_t j = 0; j < DERIV_SMOOTHING_RANGE; j++) {
					backAvg += deriv1[i + j];
				}
				backAvg /= DERIV_SMOOTHING_RANGE;
				float forwardAvg = 0;
				for (size_t j = 0; j < DERIV_SMOOTHING_RANGE; j++) {
					forwardAvg += deriv1[i + DERIV_SMOOTHING_RANGE + j + 1];
				}
				forwardAvg /= DERIV_SMOOTHING_RANGE;
				deriv2.push_back(forwardAvg - backAvg);
			}
			for (size_t i = 0; i < DERIV_SMOOTHING_RANGE; i++)
				deriv2.push_back(0);

			//compute fourier transform
			fourierRe.clear();
			fourierRe.resize(FOURIER_PATCH_WIDTH);
			fourierIm.clear();
			fourierIm.resize(FOURIER_PATCH_WIDTH);
			fourierAvg.clear();
			fourierAvg.resize(FOURIER_PATCH_WIDTH);
			fourierPatch.clear();
			fourierPatch.resize(FOURIER_PATCH_WIDTH);
			fourierFit.clear();
			fourierFit.resize(FOURIER_PATCH_WIDTH / 2);

			std::vector<size_t> peakLocs;
			std::vector<size_t> valleyLocs;
			if (peaks.size() > 0) {
				for (size_t i = 0; i < peaks.size(); i++) {
					if (peaks[i] == 1)
						peakLocs.push_back(i);
					if (peaks[i] == -1)
						valleyLocs.push_back(i);
				}
			}

			size_t nextValley = 0;
			std::vector<float> waveformPatch;
			size_t numPatches = 0;
			for (size_t p = 0; p < peakLocs.size(); p++) {
				size_t patchStart = peakLocs[p];
				while (nextValley < valleyLocs.size() && valleyLocs[nextValley] < patchStart)
					nextValley++;

				if (nextValley >= valleyLocs.size())
					break;

				numPatches++;
				size_t patchEnd = valleyLocs[nextValley];
				size_t patchSize = patchEnd - patchStart;

				patchStart += patchSize*FOURIER_PATCH_PEAK_EDGE_SHRINK;
				patchEnd -= patchSize*FOURIER_PATCH_VALLEY_EDGE_SHRINK;
				patchSize = patchEnd - patchStart;

				waveformPatch.resize(patchSize);

				for (size_t i = 0; i < patchSize; i++) {
					waveformPatch[i] = deriv2[patchStart + i];
				}

				interpolate(&waveformPatch, &fourierRe, FOURIER_PATCH_WIDTH);

				FFT(1, FOURIER_PATCH_WIDTH_POW, &fourierRe[0], &fourierIm[0]);

				for (size_t i = 0; i < fourierRe.size(); i++) {
					fourierRe[i] = sqrt(fourierRe[i] * fourierRe[i] + fourierIm[i] * fourierIm[i]);
				}

				interpolate(&fourierRe, &fourierPatch, FOURIER_PATCH_WIDTH*FOURIER_PATCH_WIDTH / patchSize);
				for (size_t i = 0; i < fourierPatch.size(); i++) {
					fourierAvg[i] += fourierPatch[i];
				}
			}
			for (size_t i = 0; i < fourierAvg.size(); i++) {
				fourierAvg[i] /= numPatches;
			}

			for (size_t i = 0; i < fourierAvg.size(); i++) {
				if (maxVal > minVal)
					fourierAvg[i] = FOURIER_SCALE_FACTOR*fourierAvg[i] / (maxVal - minVal);// 2.0f*(fourierAvg[i] - minFour) / (maxFour - minFour) - 1.0f;
				else
					fourierAvg[i] = 0.0f;
			}

			fourierBWFit(&fourierAvg[0], &fourierFit[0], &fourierFitCoef, 128);// fourierAvg.size() / 2);

			float fourierFitMagRatio = (fourierFitCoef[8] > 0 ? fourierFitCoef[4] / fourierFitCoef[8] : 9999);
			float fourierFitWidthRatio = fourierFitCoef[4] / fourierFitCoef[3];
			if (fourierFitCoef[4] > fourierFitMinAmp && fourierFitCoef[2] > fourierFitMinMean && fourierFitCoef[2] < fourierFitMaxMean && fourierFitCoef[3] < fourierFitMaxSigma && fourierFitMagRatio > fourierFitMinMagRatio && fourierFitWidthRatio > fourierFitMinWidthRatio) {
				numUnderdampedEntries++;
				ent--;
				continue;
			}

			fwrite(&curIndexFloat, sizeof(float), 1, outfile);
			fwrite(&columns[0], sizeof(float), numColumns, outfile);
		}

		std::cout << "Done. (" << getTimeSinceMark() << " s) Total: " << sampleIndices.size() << " Flat: " << numFlatEntries << " Underdamped: " << numUnderdampedEntries << std::endl;
		fclose(outfile);
		fclose(infile);
	}

	system("pause");
	system("pause");
}
