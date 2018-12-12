#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>
#include <random>
#include "trivialbinconverterPeakFinder.cuh"

#define datastring ""
//#define datastring "D:/trivialNetworkTest/sethsensor/"

#define HEADER_SIZE 8
#define NUM_INPUTS_1 512	//includes peak information, if present
#define NUM_SHIFT_INPUTS_1 512	//does NOT include peak information, if present
#define NUM_OUTPUTS_1 2
#define NUM_INPUTS_2 512
std::vector<size_t> outputIndices = { 0, 1 };
#define NUM_EXTRA_OUTPUTS 0

#define MAX_INPUT_SHIFT 0

#define INTERPOLATE_INPUT_SCALING (116.0f/70.0f)
#define NUM_SCALE_SHIFT_INPUTS_1 ((size_t)(NUM_SHIFT_INPUTS_1*INTERPOLATE_INPUT_SCALING))

#define INCLUDE_INVERTED_WAVEFORM 0
#define INCLUDE_CALCULATED_PEAKS 0

int main() {
	srand((size_t)time(NULL));
	std::string outfname;
	std::cout << "Enter output file prefix: ";
	std::cin >> outfname;

	std::string filelist = "filelist";
	std::ifstream infilelist(datastring + filelist);
	if (!infilelist.is_open()) {
		std::cout << "Couldn't open file list " << datastring << filelist << std::endl;
	}

	std::string fname;
	size_t outNum = 0;
	std::vector<float> columns(NUM_INPUTS_1 + NUM_OUTPUTS_1);
	std::vector<float> unscaledWaveform;
	std::vector<float> waveform;
	std::vector<float> unscaledPeaks;
	std::vector<float> peaks;
	while (std::getline(infilelist, fname)) {
		std::cout << "Converting " << fname << std::endl;
		outNum++;
		FILE* infile = fopen((datastring + fname).c_str(), "rb");
		std::stringstream outss;
		outss << datastring << outfname << "_" << outNum;
		FILE* outfile = fopen(outss.str().c_str(), "wb");
		char* header[HEADER_SIZE];
		fread(&header, HEADER_SIZE, 1, infile);
		fwrite(&header, HEADER_SIZE, 1, outfile);

		while (fread(&columns[0], sizeof(float), NUM_OUTPUTS_1 + NUM_INPUTS_1, infile) == NUM_OUTPUTS_1 + NUM_INPUTS_1) {
			for (size_t inv = 0; inv < (INCLUDE_INVERTED_WAVEFORM ? 2 : 1); inv++) {
				size_t inputShift = 0;
				if (NUM_INPUTS_2 + 2*MAX_INPUT_SHIFT > NUM_SCALE_SHIFT_INPUTS_1) {
					std::cout << "NUM_INPUTS_2 + 2*MAX_INPUT_SHIFT > NUM_SCALE_SHIFT_INPUTS_1" << std::endl;
					system("pause");
					return 0;
				}
				if (MAX_INPUT_SHIFT > 0) {
					inputShift = NUM_SCALE_SHIFT_INPUTS_1 / 2 - NUM_INPUTS_2 / 2 + (rand() % 2 * MAX_INPUT_SHIFT) - MAX_INPUT_SHIFT;
					if (inputShift + NUM_INPUTS_2 > NUM_SCALE_SHIFT_INPUTS_1) {
						std::cout << "inputShift + NUM_INPUTS_2 > NUM_SCALE_SHIFT_INPUTS_1; inputShift: " << inputShift << std::endl;
						system("pause");
						return 0;
					}
				}
				else
					inputShift = NUM_SCALE_SHIFT_INPUTS_1 / 2 - NUM_INPUTS_2 / 2;
				for (size_t o = 0; o < outputIndices.size(); o++) {
					fwrite(&columns[outputIndices[o]], sizeof(float), 1, outfile);
				}
				float dum = 0;
				for (size_t o = 0; o < NUM_EXTRA_OUTPUTS; o++) {
					fwrite(&dum, sizeof(float), 1, outfile);
				}
				unscaledWaveform.clear();
				unscaledWaveform.resize(NUM_SHIFT_INPUTS_1);
				for (size_t w = 0; w < unscaledWaveform.size(); w++) {
					unscaledWaveform[w] = columns[NUM_OUTPUTS_1 + w];
				}
				waveform.clear();
				waveform.resize(NUM_SCALE_SHIFT_INPUTS_1);
				interpolate(&unscaledWaveform, &waveform, waveform.size());

				fwrite(&waveform[inputShift], sizeof(float), NUM_INPUTS_2, outfile);

				if (INCLUDE_CALCULATED_PEAKS) {
					peaks.clear();
					peaks.resize(waveform.size());
					findPeaksAndValleys(&waveform, &peaks);

					fwrite(&peaks[inputShift], sizeof(float), NUM_INPUTS_2, outfile);
				}

				if (inv < (INCLUDE_INVERTED_WAVEFORM ? 2 : 1) - 1) {
					for (size_t i = 0; i < NUM_INPUTS_1; i++) {
						columns[NUM_OUTPUTS_1 + i] = -columns[NUM_OUTPUTS_1 + i];
					}
				}
			}
		}

		fclose(infile);
		fclose(outfile);
	}

	system("pause");
}
