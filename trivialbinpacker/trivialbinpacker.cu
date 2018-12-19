#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>
#include "sort.cuh"
#include "trivialbinpackerPeakFinder.cuh"

#define datastring ""
//#define datastring "D:/trivialNetworkTest/sethsensor/"

#define NUM_INPUTS 512
#define NUM_OUTPUTS 3//5
#define NUM_SILENT_OUTPUTS 0//12
#define HEADER_SIZE 8
#define TEST_FRACTION 1.0f
#define NUM_SAMPLES_PER_PERSON 2000//2000
#define NUM_VAL_SAMPLES_PER_PERSON 0
#define NUM_TEST_SAMPLES_PER_PERSON 2000//2000
#define MIN_SAMPLES_PER_PERSON 1//200
#define CUT_ON_AVERAGE_BP false//true
#define MIN_AVERAGE_OUTPUT 1//0
#define MAX_AVERAGE_OUTPUT 1000//0250
#define OUT_AVERAGE_SAMPLES 10000
#define OUT_AVERAGE_INDEX 1

#define UPSCALE_SAMPLES_PER_PERSON false

#define REMOVE_FLATLINES
#define FLATLINE_SEQ_POINTS 10

#define REPLACE_OLD_TESTFILES true

//#define NORMALIZE_BY_FIRST_TWO_OUTPUTS
#define NORMALIZE_BY_STDEV
//#define OUTLIERS_TO_TRAINSET
//#define APPLY_POST_TRANSFORM

#define USE_ALL_OUTPUTS true
#define SKIP_FIRST_OUTPUT false
#define USE_CALCULATED_OUTPUTS false
#define SAVE_OUTPUT 2
//#define PEAK_DATA_INCLUDED
#define NUM_SIDE_OUTPUT_PEAK_HEIGHTS 0	//if non-zero, overwrites normal outputs ifdef PEAK_DATA_INCLUDED

#define WAVEFORM_SMOOTHING_RANGE 0
//#define BASELINE_SHIFT_DISCARD_RANGE 5
#define BASELINE_SHIFT_DISCARD_THRESH 0.5
#define DERIV_SMOOTHING_RANGE 5

#define CONV_PEAK_FEATURES_REJECT_LOW_PEAK_WAVEFORMS
#define USE_EXTRA_CONV_PEAK_FEATURES 1
#define CONV_PEAK_FEATURES_INCLUDE_WAVEFORM true
#define CONV_PEAK_FEATURES_INCLUDE_ALL_SLOPES false
#define CONV_PEAK_FEATURES_INCLUDE_NEAR_SLOPE false
#define CONV_PEAK_FEATURES_INCLUDE_FAR_SLOPE false
#define CONV_PEAK_FEATURES_INCLUDE_X_POS false
#define CONV_PEAK_FEATURES_INCLUDE_Y_POS false
#define CONV_PEAK_FEATURES_INCLUDE_SLOPE_DIFF false
#define CONV_PEAK_FEATURES_INCLUDE_FIRST_DERIV false
#define CONV_PEAK_FEATURES_INCLUDE_SECOND_DERIV false
#define CONV_PEAK_FEATURES_INCLUDE_NORM_BY_CENTER false
#define CONV_PEAK_FEATURES_INCLUDE_ALL_DERIV2_SLOPES true

//#define USE_FIXED_FEATURES

size_t NUM_CV_SETS = 16;
size_t FIRST_CV = 0;

void readOldTestfiles(std::vector<std::vector<std::string>>* testfiles);
void createNewTestfiles(std::string filelist, std::vector<std::vector<std::string>>* testfiles);
size_t createSecondaryFeatures(float* inputs, float* peaks, std::vector<float>* secondaryFeatures, std::vector<bool>* localScaleMask);
void scaleConvSecondaryFeatures(std::vector<FILE*> trainsets, std::vector<FILE*> valsets, std::vector<FILE*> testsets, size_t numFeatures, std::vector<bool>* globalScaleMask);
size_t createSecondaryFixedFeatures(float* inputs, float* peaks, std::vector<float>* secondaryFeatures);
void calculatePeakOutputs(float* inputs, float* peaks, std::vector<float>* outputs);
void createScaleMasks(std::vector<bool>* globalScaleMask, std::vector<bool>* localScaleMask);

float transformVariable(float in) {
	float inup = (in + 1.0f)/2.0f;
	return (inup*inup*2 - 1.0f);
}

int main() {
	srand((size_t)time(NULL));

	std::cout << "Enter number of CV sets: ";
	std::cin >> NUM_CV_SETS;

	std::cout << "Enter first CV number: ";
	std::cin >> FIRST_CV;
	FIRST_CV--;

	bool useOldTestsets = false;
	std::cout << "Use old testfile lists? ";
	std::cin >> useOldTestsets;

	std::string filelist = "filelist";
	std::ifstream infilelist(datastring + filelist);
	if (!infilelist.is_open()) {
		std::cout << "Couldn't open file list " << datastring << filelist << std::endl;
	}

	std::vector<std::vector<std::string>> listtestfiles;
	if (useOldTestsets)
		readOldTestfiles(&listtestfiles);
	else {
		listtestfiles.resize(NUM_CV_SETS);
		createNewTestfiles(datastring + filelist, &listtestfiles);
	}

	std::string trainfname = "trainset";
	std::string testfname = "testset";
	std::string valfname = "valset";

	std::vector<std::ofstream> trainfilelists(NUM_CV_SETS);
	std::vector<std::ofstream> testfilelists(NUM_CV_SETS);

	std::vector<FILE*> trainsets(NUM_CV_SETS);
	std::vector<FILE*> valsets(NUM_CV_SETS);
	std::vector<FILE*> testsets(NUM_CV_SETS);
	size_t dum = 0;
	for (size_t i = 0; i < NUM_CV_SETS; i++) {
		std::stringstream numss;
		numss << "_" << FIRST_CV + i + 1;
		trainsets[i] = fopen((datastring + trainfname + numss.str()).c_str(), "wb+");
		fwrite(&dum, sizeof(size_t), 1, trainsets[i]);
		valsets[i] = fopen((datastring + valfname + numss.str()).c_str(), "wb+");
		fwrite(&dum, sizeof(size_t), 1, valsets[i]);
		testsets[i] = fopen((datastring + testfname + numss.str()).c_str(), "wb+");
		fwrite(&dum, sizeof(size_t), 1, testsets[i]);

		std::stringstream trainss;
		trainss << datastring << "trainfiles_" << FIRST_CV + i + 1;
		trainfilelists[i].open(trainss.str());
		if (!useOldTestsets || REPLACE_OLD_TESTFILES) {
			std::stringstream testss;
			testss << datastring << "testfiles_" << FIRST_CV + i + 1;
			testfilelists[i].open(testss.str());
		}
	}

	std::vector<size_t> trainSamples(NUM_CV_SETS);
	std::vector<size_t> valSamples(NUM_CV_SETS);
	std::vector<size_t> testSamples(NUM_CV_SETS);

#if USE_EXTRA_CONV_PEAK_FEATURES
	std::vector<bool> globalScaleMask;
	std::vector<bool> localScaleMask;
	createScaleMasks(&globalScaleMask, &localScaleMask);
#endif

	float personIdentifier = 0;
	std::string line;
	size_t numFeatures = 0;
	while (std::getline(infilelist, line)) {
		std::string fname;
		std::stringstream lss(line);
		lss >> fname;
		std::string groupName;
		if (!(lss >> groupName))
			groupName = fname;
		std::cout << "Reading file " << fname << ": ";

		size_t choiceNum;
		choiceNum = 0;
		for (size_t i = 0; i < listtestfiles.size(); i++) {
			for (size_t j = 0; j < listtestfiles[i].size(); j++) {
				if (listtestfiles[i][j] == groupName) {
					choiceNum = FIRST_CV + i + 1;
					break;
				}
			}
		}

		personIdentifier += 1.0f;

		for (size_t cv = 0; cv < NUM_CV_SETS; cv++) {
			if (FIRST_CV + cv + 1 == choiceNum) {
				if ((!useOldTestsets || REPLACE_OLD_TESTFILES)) {
					if (groupName == fname)
						testfilelists[cv] << personIdentifier << " " << fname << std::endl;
					else
						testfilelists[cv] << personIdentifier << " " << groupName << " " << fname << std::endl;
				}
			}
			else {
				if (groupName == fname)
					trainfilelists[cv] << personIdentifier << " " << fname << std::endl;
				else
					trainfilelists[cv] << personIdentifier << " " << groupName << " " << fname << std::endl;

			}
		}

		size_t* choiceSamples;

		FILE* infile = fopen((datastring + fname).c_str(), "rb");

		_fseeki64(infile, HEADER_SIZE, SEEK_SET);

		size_t numColumns = NUM_INPUTS + NUM_OUTPUTS + NUM_SILENT_OUTPUTS;
#ifdef PEAK_DATA_INCLUDED
		numColumns += NUM_INPUTS;
#endif

		std::vector<float> columns(numColumns);
		std::vector<size_t> sampleIndices;
		while (fread(&columns[0], sizeof(float), numColumns, infile) == numColumns) {
			sampleIndices.push_back(sampleIndices.size());
		}
		randomizeVector(&sampleIndices);

		std::cout << sampleIndices.size() << " samples; going to CV set" << choiceNum;
		if (sampleIndices.size() < MIN_SAMPLES_PER_PERSON) {
			std::cout << " Sample count under threshold; excluding" << std::endl;
			fclose(infile);
			continue;
		}

		float avgOutput = 0;
		size_t numAvgSamples = 0;
		for (size_t i = 0; i < std::min((size_t)OUT_AVERAGE_SAMPLES, sampleIndices.size()); i++) {
			_fseeki64(infile, sampleIndices[i]*numColumns*sizeof(float) + HEADER_SIZE, SEEK_SET);
			fread(&columns[0], sizeof(float), NUM_OUTPUTS, infile);
			avgOutput += columns[OUT_AVERAGE_INDEX - 1];
			numAvgSamples++;
		}
		avgOutput /= numAvgSamples;
		std::cout << " Average output: " << avgOutput << std::endl;
		if (CUT_ON_AVERAGE_BP && (avgOutput < MIN_AVERAGE_OUTPUT || avgOutput > MAX_AVERAGE_OUTPUT)) {
			std::cout << "Average output outside of accepted range. ";
#ifdef OUTLIERS_TO_TRAINSET
			choiceNum = 0;
			std::cout << "Going to all trainsets." << std::endl;
#else
			std::cout << "Ignoring. " << std::endl;
			fclose(infile);
			continue;
#endif
		}

		size_t trainSampleNum = NUM_SAMPLES_PER_PERSON + NUM_VAL_SAMPLES_PER_PERSON;
		size_t testSampleNum = (NUM_TEST_SAMPLES_PER_PERSON == 0 ? sampleIndices.size() : (size_t)NUM_TEST_SAMPLES_PER_PERSON);

		size_t numSamplesRemoved;
		size_t numTestSamplesRemoved = 0;

		for (size_t cv = 0; cv < NUM_CV_SETS; cv++) {
			FILE* dataset;
			size_t sampleNum;
			if (FIRST_CV + cv + 1 == choiceNum) {
				dataset = testsets[cv];
				choiceSamples = &testSamples[cv];
				sampleNum = testSampleNum;
				if (NUM_TEST_SAMPLES_PER_PERSON == 0) {
					for (size_t i = 0; i < sampleIndices.size(); i++)
						sampleIndices[i] = i;
				}
			}
			else {
				dataset = trainsets[cv];
				choiceSamples = &trainSamples[cv];
				sampleNum = trainSampleNum;
				randomizeVector(&sampleIndices);
			}

			numSamplesRemoved = 0;

			for (size_t i = 0; i < (UPSCALE_SAMPLES_PER_PERSON && !(FIRST_CV + cv + 1 == choiceNum && NUM_TEST_SAMPLES_PER_PERSON == 0) ? sampleNum + numSamplesRemoved : std::min(sampleNum + numSamplesRemoved, sampleIndices.size())); i++) {
				if (FIRST_CV + cv + 1 != choiceNum && i - numSamplesRemoved >= NUM_SAMPLES_PER_PERSON) {
					dataset = valsets[cv];
					choiceSamples = &valSamples[cv];
				}

				_fseeki64(infile, sampleIndices[i % sampleIndices.size()] * numColumns*sizeof(float) + HEADER_SIZE, SEEK_SET);
				fread(&columns[0], sizeof(float), numColumns, infile);

#ifdef PEAK_DATA_INCLUDED
				std::vector<float> calcOutputs;
				if (NUM_SIDE_OUTPUT_PEAK_HEIGHTS > 0) {
					calculatePeakOutputs(&columns[NUM_OUTPUTS + NUM_SILENT_OUTPUTS], &columns[NUM_OUTPUTS + NUM_SILENT_OUTPUTS + NUM_INPUTS], &calcOutputs);
				}
#endif

				float minInput = 9999;
				float maxInput = -9999;
#ifdef NORMALIZE_BY_FIRST_TWO_OUTPUTS
				minInput = columns[0];
				maxInput = columns[1];
#elif defined(NORMALIZE_BY_STDEV)
				float stdev = 0;
				float avg = 0;
				for (size_t in = 0; in < NUM_INPUTS; in++) {
					float input = columns[in + NUM_OUTPUTS + NUM_SILENT_OUTPUTS];
					stdev += input*input;
					avg += input;
				}
				stdev /= NUM_INPUTS;
				avg /= NUM_INPUTS;
				stdev = sqrt(stdev - avg*avg);

				for (size_t in = 0; in < NUM_INPUTS; in++) {
					columns[in + NUM_OUTPUTS + NUM_SILENT_OUTPUTS] = (columns[in + NUM_OUTPUTS + NUM_SILENT_OUTPUTS] - avg)/stdev;
				}
#else
				for (size_t in = 0; in < NUM_INPUTS; in++) {
					minInput = std::min(minInput, columns[in + NUM_OUTPUTS + NUM_SILENT_OUTPUTS]);
					maxInput = std::max(maxInput, columns[in + NUM_OUTPUTS + NUM_SILENT_OUTPUTS]);
				}
#endif

#ifndef NORMALIZE_BY_STDEV
				for (size_t in = 0; in < NUM_INPUTS; in++) {
					columns[in + NUM_OUTPUTS + NUM_SILENT_OUTPUTS] = 2.0f*(columns[in + NUM_OUTPUTS + NUM_SILENT_OUTPUTS] - minInput) / (maxInput - minInput) - 1.0f;
				}
#endif

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
					numSamplesRemoved++;
					if (FIRST_CV + cv + 1 == choiceNum)
						numTestSamplesRemoved++;
					continue;
				}
#endif

#if defined(BASELINE_SHIFT_DISCARD_RANGE) && BASELINE_SHIFT_DISCARD_RANGE > 0
				float begAvg = 0;
				float endAvg = 0;
				float maxVal = -9999;
				float minVal = 9999;
				for (size_t in = 0; in < NUM_INPUTS; in++) {
					float val = columns[in + NUM_OUTPUTS];
					maxVal = std::max(maxVal, val);
					minVal = std::min(minVal, val);
					if(in < BASELINE_SHIFT_DISCARD_RANGE)
						begAvg += val;
					if(in > NUM_INPUTS - BASELINE_SHIFT_DISCARD_RANGE - 1)
						endAvg += val;
				}
				begAvg /= BASELINE_SHIFT_DISCARD_RANGE;
				endAvg /= BASELINE_SHIFT_DISCARD_RANGE;
				if (maxVal == minVal || fabs(endAvg - begAvg) / (maxVal - minVal) > BASELINE_SHIFT_DISCARD_THRESH) {
					numSamplesRemoved++;
					if (FIRST_CV + cv + 1 == choiceNum)
						numTestSamplesRemoved++;
					continue;
				}
#endif

#ifdef APPLY_POST_TRANSFORM
				for (size_t in = 0; in < NUM_INPUTS; in++) {
					columns[in + NUM_OUTPUTS] = transformVariable(columns[in + NUM_OUTPUTS]);
				}
#endif

#if defined(WAVEFORM_SMOOTHING_RANGE) && WAVEFORM_SMOOTHING_RANGE > 0
				std::vector<float> waveSmoothAverage(NUM_INPUTS);
				for (size_t in = 0; in < NUM_INPUTS; in++) {
					size_t count = 0;
					for (int j = -WAVEFORM_SMOOTHING_RANGE; j <= WAVEFORM_SMOOTHING_RANGE; j++) {
						if ((int)in + j >= 0 && (int)in + j < NUM_INPUTS) {
							count++;
							waveSmoothAverage[in] += columns[in + j + NUM_OUTPUTS];
						}
					}
					if (count > 0)
						waveSmoothAverage[in] /= count;
				}

				for (size_t in = 0; in < NUM_INPUTS; in++) {
					columns[in + NUM_OUTPUTS] = waveSmoothAverage[in];
				}
#endif

#if USE_EXTRA_CONV_PEAK_FEATURES
				std::vector<float> secondaryFeatures;
#ifdef PEAK_DATA_INCLUDED
				numFeatures = createSecondaryFeatures(&columns[NUM_OUTPUTS + NUM_SILENT_OUTPUTS], &columns[NUM_OUTPUTS + NUM_SILENT_OUTPUTS + NUM_INPUTS], &secondaryFeatures, &localScaleMask);
#else
				std::vector<float> waveform(NUM_INPUTS);
				for(size_t w=0;w<NUM_INPUTS;w++)
					waveform[w] = columns[NUM_OUTPUTS + NUM_SILENT_OUTPUTS + w];
				std::vector<float> genPeaks;
				findPeaksAndValleys(&waveform, &genPeaks);
				numFeatures = createSecondaryFeatures(&waveform[0], &genPeaks[0], &secondaryFeatures, &localScaleMask);
#endif
#elif defined(USE_FIXED_FEATURES)
				std::vector<float> secondaryFeatures;
				numFeatures = createSecondaryFixedFeatures(&columns[NUM_OUTPUTS + NUM_SILENT_OUTPUTS], &columns[NUM_OUTPUTS + NUM_SILENT_OUTPUTS + NUM_INPUTS], &secondaryFeatures);
#endif

				if (USE_ALL_OUTPUTS) {
					if (SKIP_FIRST_OUTPUT)
						fwrite(&columns[1], sizeof(float), NUM_OUTPUTS - 1, dataset);
					else
						fwrite(&columns[0], sizeof(float), NUM_OUTPUTS, dataset);
				}
#ifdef PEAK_DATA_INCLUDED
				else if (USE_CALCULATED_OUTPUTS && NUM_SIDE_OUTPUT_PEAK_HEIGHTS > 0) {
					fwrite(&calcOutputs[0], sizeof(float), calcOutputs.size(), dataset);
				}
#endif
				else
					fwrite(&columns[SAVE_OUTPUT - 1], sizeof(float), 1, dataset);
				fwrite(&personIdentifier, sizeof(float), 1, dataset);
#if USE_EXTRA_CONV_PEAK_FEATURES || defined(USE_FIXED_FEATURES)
				fwrite(&secondaryFeatures[0], sizeof(float), secondaryFeatures.size(), dataset);
#else
				fwrite(&columns[NUM_OUTPUTS + NUM_SILENT_OUTPUTS], sizeof(float), NUM_INPUTS, dataset);
#endif

				(*choiceSamples)++;
			}
		}
#if defined(REMOVE_FLATLINES) || (defined(BASELINE_SHIFT_DISCARD_RANGE) && BASELINE_SHIFT_DISCARD_RANGE > 0)
		std::cout << numTestSamplesRemoved << " samples discarded." << std::endl;
#endif
		fclose(infile);
	}
	for (size_t c = 0; c < NUM_CV_SETS; c++) {
		_fseeki64(trainsets[c], 0, SEEK_SET);
		fwrite(&trainSamples[c], sizeof(size_t), 1, trainsets[c]);

		_fseeki64(valsets[c], 0, SEEK_SET);
		fwrite(&valSamples[c], sizeof(size_t), 1, valsets[c]);

		_fseeki64(testsets[c], 0, SEEK_SET);
		fwrite(&testSamples[c], sizeof(size_t), 1, testsets[c]);
	}

#if USE_EXTRA_CONV_PEAK_FEATURES || defined(USE_FIXED_FEATURES)
	scaleConvSecondaryFeatures(trainsets, valsets, testsets, numFeatures, &globalScaleMask);
#endif
	
	for (size_t c = 0; c < NUM_CV_SETS; c++) {
		fclose(trainsets[c]);
		fclose(valsets[c]);
		fclose(testsets[c]);
	}

	std::cout << "Done. " << std::endl;
	std::cout << "Number of samples in first CV: trainset: " << trainSamples[0] << " testset: " << testSamples[0] << " valset: " << valSamples[0] << std::endl;

	system("pause");
}

void readOldTestfiles(std::vector<std::vector<std::string>>* testfiles) {
	testfiles->clear();
	for (size_t t = 0; t < NUM_CV_SETS; t++) {
		std::stringstream testss;
		testss << datastring << "testfiles_" << FIRST_CV + t + 1;
		std::ifstream testfile(testss.str());
		std::string line;
		std::vector<std::string> fnames;
		while (std::getline(testfile, line)) {
			size_t dum;
			std::string fname;
			std::stringstream lss(line);
			lss >> dum >> fname;
			if (std::find(fnames.begin(), fnames.end(), fname) == fnames.end())
				fnames.push_back(fname);
		}
		testfiles->push_back(fnames);
		testfile.close();
	}
}

void createNewTestfiles(std::string filelist, std::vector<std::vector<std::string>>* testfiles) {
	std::ifstream infile(filelist);
	std::vector<std::string> fnames;
	std::vector<size_t> ids;

	std::string line;
	size_t idNum = 0;
	while (std::getline(infile, line)) {
		std::stringstream lss(line);
		std::string idName;
		lss >> idName;
		std::string dum;
		if (lss >> dum)
			idName = dum;
		if (std::find(fnames.begin(), fnames.end(), idName) == fnames.end()) {
			fnames.push_back(idName);
			ids.push_back(idNum);
			idNum++;
		}
	}

	randomizeVector(&ids);

	for (size_t i = 0; i < testfiles->size(); i++) {
		std::vector<size_t> cvIds;
		for (size_t j = ids.size()*i / testfiles->size(); j < ids.size()*(i + 1) / testfiles->size(); j++)
			cvIds.push_back(ids[j]);

		(*testfiles)[i].clear();
		for (size_t j = 0; j < cvIds.size(); j++) {
			(*testfiles)[i].push_back(fnames[cvIds[j]]);
		}
	}
}

void createScaleMasks(std::vector<bool>* globalScaleMask, std::vector<bool>* localScaleMask) {
	globalScaleMask->clear();
	localScaleMask->clear();
	if (CONV_PEAK_FEATURES_INCLUDE_WAVEFORM) {
		globalScaleMask->push_back(false);
		localScaleMask->push_back(false);
	}

	if (CONV_PEAK_FEATURES_INCLUDE_ALL_SLOPES) {
		for (size_t i = 0; i < 4; i++) {
			globalScaleMask->push_back(true);
			localScaleMask->push_back(false);
		}
	}

	if (CONV_PEAK_FEATURES_INCLUDE_NEAR_SLOPE) {
		for (size_t i = 0; i < 2; i++) {
			globalScaleMask->push_back(true);
			localScaleMask->push_back(false);
		}
	}

	if (CONV_PEAK_FEATURES_INCLUDE_FAR_SLOPE) {
		for (size_t i = 0; i < 2; i++) {
			globalScaleMask->push_back(true);
			localScaleMask->push_back(false);
		}
	}

	if (CONV_PEAK_FEATURES_INCLUDE_X_POS) {
		for (size_t i = 0; i < 2; i++) {
			globalScaleMask->push_back(true);
			localScaleMask->push_back(false);
		}
	}

	if (CONV_PEAK_FEATURES_INCLUDE_Y_POS) {
		for (size_t i = 0; i < 2; i++) {
			globalScaleMask->push_back(true);
			localScaleMask->push_back(false);
		}
	}

	if (CONV_PEAK_FEATURES_INCLUDE_SLOPE_DIFF) {
		globalScaleMask->push_back(true);
		localScaleMask->push_back(false);
	}

	if (CONV_PEAK_FEATURES_INCLUDE_FIRST_DERIV) {
		globalScaleMask->push_back(false);
		localScaleMask->push_back(true);
	}

	if (CONV_PEAK_FEATURES_INCLUDE_SECOND_DERIV) {
		globalScaleMask->push_back(false);
		localScaleMask->push_back(true);
	}

	if (CONV_PEAK_FEATURES_INCLUDE_NORM_BY_CENTER) {
		globalScaleMask->push_back(false);
		localScaleMask->push_back(false);
	}

	if (CONV_PEAK_FEATURES_INCLUDE_ALL_DERIV2_SLOPES) {
		for (size_t i = 0; i < 4; i++) {
			globalScaleMask->push_back(true);
			localScaleMask->push_back(false);
		}
	}
}

size_t createSecondaryFeatures(float* inputs, float* peaks, std::vector<float>* secondaryFeatures, std::vector<bool>* localScaleMask) {
	size_t numFeatures = (CONV_PEAK_FEATURES_INCLUDE_ALL_SLOPES ? 4 : 0) + (CONV_PEAK_FEATURES_INCLUDE_NEAR_SLOPE ? 2 : 0) + (CONV_PEAK_FEATURES_INCLUDE_FAR_SLOPE ? 2 : 0) + (CONV_PEAK_FEATURES_INCLUDE_X_POS ? 2 : 0) + (CONV_PEAK_FEATURES_INCLUDE_Y_POS ? 2 : 0) + (CONV_PEAK_FEATURES_INCLUDE_WAVEFORM ? 1 : 0) + (CONV_PEAK_FEATURES_INCLUDE_SLOPE_DIFF ? 1 : 0) + (CONV_PEAK_FEATURES_INCLUDE_FIRST_DERIV ? 1 : 0) + (CONV_PEAK_FEATURES_INCLUDE_SECOND_DERIV ? 1 : 0) + (CONV_PEAK_FEATURES_INCLUDE_NORM_BY_CENTER ? 1 : 0) + (CONV_PEAK_FEATURES_INCLUDE_ALL_DERIV2_SLOPES ? 4 : 0);
	secondaryFeatures->clear();

	std::vector<size_t> peakLocs;
	std::vector<size_t> valleyLocs;
	float minVal = 9999;
	float maxVal = -9999;

	for (size_t i = 0; i < NUM_INPUTS; i++) {
		if (peaks[i] > 0)
			peakLocs.push_back(i);
		else if (peaks[i] < 0)
			valleyLocs.push_back(i);
		minVal = std::min(minVal, inputs[i]);
		maxVal = std::max(maxVal, inputs[i]);
	}
	float minPeakDistance = 9999;
	float minValleyDistance = 9999;
	size_t centerPeak = 0;
	size_t centerValley = 0;
	for (size_t i = 0; i < peakLocs.size(); i++) {
		int dist = abs((int)peakLocs[i] - NUM_INPUTS / 2);
		if (dist < minPeakDistance) {
			minPeakDistance = dist;
			centerPeak = peakLocs[i];
		}
	}
	for (size_t i = 0; i < valleyLocs.size(); i++) {
		int dist = abs((int)valleyLocs[i] - NUM_INPUTS / 2);
		if (dist < minValleyDistance) {
			minValleyDistance = dist;
			centerValley = valleyLocs[i];
		}
	}

#ifdef CONV_PEAK_FEATURES_REJECT_LOW_PEAK_WAVEFORMS
	if (peakLocs.size() < 2 || valleyLocs.size() < 2) {
		/*
		std::cout << "Found pulse with less than 2 peaks or valleys detected" << std::endl;
		for (size_t i = 0; i < NUM_INPUTS; i++) {
			std::cout << inputs[i] << " ";
		}
		std::cout << std::endl;
		for (size_t i = 0; i < NUM_INPUTS; i++) {
			std::cout << peaks[i] << " ";
		}
		std::cout << std::endl;
		*/
		for (size_t i = 0; i < NUM_INPUTS; i++) {
			for (size_t f = 0; f < numFeatures; f++) {
				(*secondaryFeatures).push_back(0);
			}
		}
		return numFeatures;
	}
#endif

	std::vector<float> waveform(NUM_INPUTS);
	std::vector<float> deriv1;
	std::vector<float> deriv2;

	for (size_t w = 0; w < NUM_INPUTS; w++)
		waveform[w] = inputs[w];

	if (CONV_PEAK_FEATURES_INCLUDE_FIRST_DERIV || CONV_PEAK_FEATURES_INCLUDE_SECOND_DERIV || CONV_PEAK_FEATURES_INCLUDE_ALL_DERIV2_SLOPES) {
		computeDerivative(&waveform, &deriv1, DERIV_SMOOTHING_RANGE);
	}

	if (CONV_PEAK_FEATURES_INCLUDE_SECOND_DERIV || CONV_PEAK_FEATURES_INCLUDE_ALL_DERIV2_SLOPES) {
		computeDerivative(&deriv1, &deriv2, DERIV_SMOOTHING_RANGE);
	}

	float maxDeriv1 = -99999;
	float minDeriv1 = 99999;
	float maxDeriv2 = -99999;
	float minDeriv2 = 99999;

	for (size_t i = 0; i < NUM_INPUTS; i++) {
		minDeriv1 = std::min(minDeriv1, deriv1[i]);
		maxDeriv1 = std::max(maxDeriv1, deriv1[i]);
		minDeriv2 = std::min(minDeriv2, deriv2[i]);
		maxDeriv2 = std::max(maxDeriv2, deriv2[i]);
	}

	size_t lastPeak = 0;
	size_t lastValley = 0;

	for (size_t i = 0; i < NUM_INPUTS; i++) {
		bool hasBackPeak = i > peakLocs[0];
		bool hasForwardPeak = i < peakLocs[peakLocs.size() - 1];
		bool hasBackValley = i > valleyLocs[0];
		bool hasForwardValley = i < valleyLocs[valleyLocs.size() - 1];

		if (lastPeak < peakLocs.size() - 1 && i > peakLocs[lastPeak + 1])
			lastPeak++;
		if (lastValley < valleyLocs.size() - 1 && i > valleyLocs[lastValley + 1])
			lastValley++;

		float pulseWidth = (lastPeak < peakLocs.size() - 1 ? 1.0f*(peakLocs[lastPeak + 1] - peakLocs[lastPeak]) : 1.0f*(peakLocs[lastPeak] - peakLocs[lastPeak - 1]));
		float peakXDiffBack;
		float peakYDiffBack;
		if (i > peakLocs[0]) {
			peakXDiffBack = 1.0f*(i - peakLocs[lastPeak]) / pulseWidth;
			peakYDiffBack = (maxVal > minVal ? (inputs[i] - inputs[peakLocs[lastPeak]]) / (maxVal - minVal) : 0.0f);
		}
		else {
			peakXDiffBack = 0;
			peakYDiffBack = 0;
		}

		float peakXDiffFor;
		float peakYDiffFor;
		if (i < peakLocs[peakLocs.size() - 1]) {
			peakXDiffFor = 1.0f*(peakLocs[lastPeak + 1] - i) / pulseWidth;
			peakYDiffFor = (maxVal > minVal ? (inputs[peakLocs[lastPeak + 1]] - inputs[i]) / (maxVal - minVal) : 0.0f);
		}
		else {
			peakXDiffFor = 0;
			peakYDiffFor = 0;
		}

		float valleyXDiffBack;
		float valleyYDiffBack;
		if (i > valleyLocs[0]) {
			valleyXDiffBack = 1.0f*(i - valleyLocs[lastValley]) / pulseWidth;
			valleyYDiffBack = (maxVal > minVal ? (inputs[i] - inputs[valleyLocs[lastValley]]) / (maxVal - minVal) : 0.0f);
		}
		else {
			valleyXDiffBack = 0;
			valleyYDiffBack = 0;
		}


		float valleyXDiffFor;
		float valleyYDiffFor;
		if (i < valleyLocs[valleyLocs.size() - 1]) {
			valleyXDiffFor = 1.0f*(valleyLocs[lastValley + 1] - i) / pulseWidth;
			valleyYDiffFor = (maxVal > minVal ? (inputs[valleyLocs[lastValley + 1]] - inputs[i]) / (maxVal - minVal) : 0.0f);
		}
		else {
			valleyXDiffFor = 0;
			valleyYDiffFor = 0;
		}

		float peakBackHypo = sqrt(peakXDiffBack*peakXDiffBack + peakYDiffBack*peakYDiffBack);
		float peakForHypo = sqrt(peakXDiffFor*peakXDiffFor + peakYDiffFor*peakYDiffFor);
		float valleyBackHypo = sqrt(valleyXDiffBack*valleyXDiffBack + valleyYDiffBack*valleyYDiffBack);
		float valleyForHypo = sqrt(valleyXDiffFor*valleyXDiffFor + valleyYDiffFor*valleyYDiffFor);

		if (CONV_PEAK_FEATURES_INCLUDE_WAVEFORM) {
			secondaryFeatures->push_back(inputs[i]);
		}

		if (CONV_PEAK_FEATURES_INCLUDE_ALL_SLOPES) {
			if (peakBackHypo != 0)
				secondaryFeatures->push_back(peakYDiffBack / peakBackHypo);
			else
				secondaryFeatures->push_back(0.0f);

			if (peakForHypo != 0)
				secondaryFeatures->push_back(peakYDiffFor / peakForHypo);
			else
				secondaryFeatures->push_back(0.0f);

			if (valleyBackHypo != 0)
				secondaryFeatures->push_back(valleyYDiffBack / valleyBackHypo);
			else
				secondaryFeatures->push_back(0.0f);

			if (valleyForHypo != 0)
				secondaryFeatures->push_back(valleyYDiffFor / valleyForHypo);
			else
				secondaryFeatures->push_back(0.0f);
		}

		if (CONV_PEAK_FEATURES_INCLUDE_NEAR_SLOPE) {
			if (i > peakLocs[0] && (i <= valleyLocs[0] || peakLocs[lastPeak] > valleyLocs[lastValley]) && peakBackHypo != 0)
				secondaryFeatures->push_back(peakYDiffBack / peakBackHypo);
			else if (i > valleyLocs[0] && (i <= peakLocs[0] || valleyLocs[lastValley] > peakLocs[lastPeak]) && valleyBackHypo != 0)
				secondaryFeatures->push_back(valleyYDiffBack / valleyBackHypo);
			else
				secondaryFeatures->push_back(0);
				
			if (i < peakLocs[peakLocs.size() - 1] && (i >= valleyLocs[valleyLocs.size() - 1] || peakLocs[lastPeak + 1] < valleyLocs[lastValley + 1]) && peakForHypo != 0)
				secondaryFeatures->push_back(peakYDiffFor / peakForHypo);
			else if (i < valleyLocs[valleyLocs.size() - 1] && (i >= peakLocs[peakLocs.size() - 1] || valleyLocs[lastValley + 1] < peakLocs[lastPeak + 1]) && valleyForHypo != 0)
				secondaryFeatures->push_back(valleyYDiffFor / valleyForHypo);
			else
				secondaryFeatures->push_back(0);
		}

		if (CONV_PEAK_FEATURES_INCLUDE_FAR_SLOPE) {
			if (i > peakLocs[0] && i > valleyLocs[0] && (peakLocs[lastPeak] < valleyLocs[lastValley]) && peakBackHypo != 0)
				secondaryFeatures->push_back(peakYDiffBack / peakBackHypo);
			else if (i > peakLocs[0] && i > valleyLocs[0] && (valleyLocs[lastValley] < peakLocs[lastPeak]) && valleyBackHypo != 0)
				secondaryFeatures->push_back(valleyYDiffBack / valleyBackHypo);
			else
				secondaryFeatures->push_back(0);
				
			if (i < peakLocs[peakLocs.size() - 1] && i < valleyLocs[valleyLocs.size() - 1] && (peakLocs[lastPeak + 1] > valleyLocs[lastValley + 1]) && peakForHypo != 0)
				secondaryFeatures->push_back(peakYDiffFor / peakForHypo);
			else if (i < peakLocs[peakLocs.size() -1] && i < valleyLocs[valleyLocs.size() - 1] && (valleyLocs[lastValley + 1] > peakLocs[lastPeak + 1]) && valleyForHypo != 0)
				secondaryFeatures->push_back(valleyYDiffFor / valleyForHypo);
			else
				secondaryFeatures->push_back(0);
		}

		if (CONV_PEAK_FEATURES_INCLUDE_X_POS) {
			//peakXBack
			if (i > peakLocs[0])
				secondaryFeatures->push_back(i - peakLocs[lastPeak]);
			else
				secondaryFeatures->push_back(0);

			//peakXFor
			if (i < peakLocs[peakLocs.size() - 1])
				secondaryFeatures->push_back(peakLocs[lastPeak + 1] - i);
			else
				secondaryFeatures->push_back(0);
		}

		if (CONV_PEAK_FEATURES_INCLUDE_Y_POS) {
			//peakY
			if (i <= peakLocs[0])
				secondaryFeatures->push_back(inputs[peakLocs[0]] - inputs[i]);
			else if (i >= peakLocs[peakLocs.size() - 1])
				secondaryFeatures->push_back(inputs[peakLocs[peakLocs.size() - 1]] - inputs[i]);
			else
				secondaryFeatures->push_back((inputs[peakLocs[lastPeak]] + inputs[peakLocs[lastPeak + 1]]) / 2 - inputs[i]);

			//valleyY
			if (i <= valleyLocs[0])
				secondaryFeatures->push_back(inputs[valleyLocs[0]] - inputs[i]);
			else if (i >= valleyLocs[valleyLocs.size() - 1])
				secondaryFeatures->push_back(inputs[valleyLocs[valleyLocs.size() - 1]] - inputs[i]);
			else
				secondaryFeatures->push_back((inputs[valleyLocs[lastValley]] + inputs[valleyLocs[lastValley + 1]]) / 2 - inputs[i]);
		}

		if (CONV_PEAK_FEATURES_INCLUDE_SLOPE_DIFF) {
			size_t backPoint = std::max((i > peakLocs[0] ? peakLocs[lastPeak] : 0), (i > valleyLocs[0] ? valleyLocs[lastValley] : 0));
			size_t forwardPoint = std::min((i <= peakLocs[peakLocs.size() - 1] ? (i > peakLocs[0] ? peakLocs[lastPeak + 1] : peakLocs[0]) : 9999), (i <= valleyLocs[valleyLocs.size() - 1] ? (i > valleyLocs[0] ? valleyLocs[lastValley + 1] : valleyLocs[0]) : 9999));
			if (backPoint == 0 || forwardPoint == 9999 || forwardPoint <= backPoint || inputs[forwardPoint] == inputs[backPoint]) {
				secondaryFeatures->push_back(0);
			}
			else {
				float slopeHeight = inputs[backPoint] + (inputs[forwardPoint] - inputs[backPoint]) * (i - backPoint) / (forwardPoint - backPoint);
				secondaryFeatures->push_back((inputs[i] - slopeHeight) / fabs(inputs[forwardPoint] - inputs[backPoint]));
			}
		}

		if (CONV_PEAK_FEATURES_INCLUDE_FIRST_DERIV) {
			secondaryFeatures->push_back(deriv1[i]);
		}

		if (CONV_PEAK_FEATURES_INCLUDE_SECOND_DERIV) {
			secondaryFeatures->push_back(deriv2[i]);
		}

		if (CONV_PEAK_FEATURES_INCLUDE_NORM_BY_CENTER) {
			if (inputs[centerPeak] > inputs[centerValley])
				secondaryFeatures->push_back(2.0f*(inputs[i] - inputs[centerValley]) / (inputs[centerPeak] - inputs[centerValley]) - 1.0f);
			else
				secondaryFeatures->push_back(0);
		}

		if (CONV_PEAK_FEATURES_INCLUDE_ALL_DERIV2_SLOPES) {
			float derivPeakYDiffBack;
			if (i > peakLocs[0]) {
				derivPeakYDiffBack = (maxDeriv2 > minDeriv2 ? (deriv2[i] - deriv2[peakLocs[lastPeak]]) / (maxDeriv2 - minDeriv2) : 0.0f);
			}
			else {
				derivPeakYDiffBack = 0;
			}

			float derivPeakYDiffFor;
			if (i < peakLocs[peakLocs.size() - 1]) {
				derivPeakYDiffFor = (maxDeriv2 > minDeriv2 ? (deriv2[peakLocs[lastPeak + 1]] - deriv2[i]) / (maxDeriv2 - minDeriv2) : 0.0f);
			}
			else {
				derivPeakYDiffFor = 0;
			}

			float derivValleyYDiffBack;
			if (i > valleyLocs[0]) {
				derivValleyYDiffBack = (maxDeriv2 > minDeriv2 ? (deriv2[i] - deriv2[valleyLocs[lastValley]]) / (maxDeriv2 - minDeriv2) : 0.0f);
			}
			else {
				derivValleyYDiffBack = 0;
			}


			float derivValleyYDiffFor;
			if (i < valleyLocs[valleyLocs.size() - 1]) {
				derivValleyYDiffFor = (maxDeriv2 > minDeriv2 ? (deriv2[valleyLocs[lastValley + 1]] - deriv2[i]) / (maxDeriv2 - minDeriv2) : 0.0f);
			}
			else {
				derivValleyYDiffFor = 0;
			}

			float derivPeakBackHypo = sqrt(peakXDiffBack*peakXDiffBack + derivPeakYDiffBack*derivPeakYDiffBack);
			float derivPeakForHypo = sqrt(peakXDiffFor*peakXDiffFor + derivPeakYDiffFor*derivPeakYDiffFor);
			float derivValleyBackHypo = sqrt(valleyXDiffBack*valleyXDiffBack + derivValleyYDiffBack*derivValleyYDiffBack);
			float derivValleyForHypo = sqrt(valleyXDiffFor*valleyXDiffFor + derivValleyYDiffFor*derivValleyYDiffFor);

			if (derivPeakBackHypo != 0)
				secondaryFeatures->push_back(derivPeakYDiffBack / derivPeakBackHypo);
			else
				secondaryFeatures->push_back(0.0f);

			if (derivPeakForHypo != 0)
				secondaryFeatures->push_back(derivPeakYDiffFor / derivPeakForHypo);
			else
				secondaryFeatures->push_back(0.0f);

			if (derivValleyBackHypo != 0)
				secondaryFeatures->push_back(derivValleyYDiffBack / derivValleyBackHypo);
			else
				secondaryFeatures->push_back(0.0f);

			if (derivValleyForHypo != 0)
				secondaryFeatures->push_back(derivValleyYDiffFor / derivValleyForHypo);
			else
				secondaryFeatures->push_back(0.0f);
		}
	}

	//local scaling
	for (size_t f = 0; f < numFeatures; f++) {
		if (!(*localScaleMask)[f])
			continue;
		float mean = 0;
		float stdev = 0;
		for (size_t i = 0; i < NUM_INPUTS; i++) {
			float val = (*secondaryFeatures)[f + i*numFeatures];
			mean += val;
			stdev += val*val;
		}
		mean /= NUM_INPUTS;
		stdev /= NUM_INPUTS;
		stdev = sqrt(stdev - mean*mean);
		for (size_t i = 0; i < NUM_INPUTS; i++) {
			(*secondaryFeatures)[f + i*numFeatures] = (stdev > 0 ? ((*secondaryFeatures)[f + i*numFeatures] - mean) / stdev : 0);
		}
	}

	return secondaryFeatures->size() / NUM_INPUTS;
}

size_t createSecondaryFixedFeatures(float* inputs, float* peaks, std::vector<float>* secondaryFeatures) {
	secondaryFeatures->clear();

	std::vector<size_t> peakLocs;
	std::vector<size_t> valleyLocs;
	float minVal = 9999;
	float maxVal = -9999;

	for (size_t i = 0; i < NUM_INPUTS; i++) {
		if (peaks[i] == 1)
			peakLocs.push_back(i);
		else if (peaks[i] == -1)
			valleyLocs.push_back(i);
		minVal = std::min(minVal, inputs[i]);
		maxVal = std::max(maxVal, inputs[i]);
	}

	//heartrate features
	float pulseWidthMean = 0;
	float pulseWidthStdev = 0;
	size_t numPulseWidths = 0;
	for (size_t i = 0; i + 1 < peakLocs.size(); i++) {
		float width = peakLocs[i + 1] - peakLocs[i];
		pulseWidthMean += width;
		pulseWidthStdev += width*width;
		numPulseWidths++;
	}
	for (size_t i = 0; i + 1 < valleyLocs.size(); i++) {
		float width = valleyLocs[i + 1] - valleyLocs[i];
		pulseWidthMean += width;
		pulseWidthStdev += width*width;
		numPulseWidths++;
	}
	pulseWidthMean /= numPulseWidths;
	pulseWidthStdev /= numPulseWidths;
	pulseWidthStdev = sqrt(pulseWidthStdev - pulseWidthMean*pulseWidthMean);

	secondaryFeatures->push_back(pulseWidthMean);
	secondaryFeatures->push_back(pulseWidthStdev);

	//slope features

	std::vector<size_t> slopeSizes = { 3, 6, 12, 24, 36 };
	
	for (size_t s = 0; s < slopeSizes.size(); s++) {
		//prePeak
		float mean = 0;
		float stdev = 0;
		float counts = 0;
		for (size_t i = 0; i < peakLocs.size(); i++) {
			if (peakLocs[i] < slopeSizes[s])
				continue;
			float slope = (inputs[peakLocs[i]] - inputs[peakLocs[i] - slopeSizes[s]]) / slopeSizes[s];
			mean += slope;
			stdev += slope*slope;
			counts++;
		}
		mean /= counts;
		stdev /= counts;
		stdev = (stdev > mean*mean ? sqrt(stdev - mean*mean) : 0);

		secondaryFeatures->push_back(mean);
		secondaryFeatures->push_back(stdev);

		//postPeak
		mean = 0;
		stdev = 0;
		counts = 0;
		for (size_t i = 0; i < peakLocs.size(); i++) {
			if (peakLocs[i] >= NUM_INPUTS - slopeSizes[s])
				continue;
			float slope = (inputs[peakLocs[i] + slopeSizes[s]] - inputs[peakLocs[i]]) / slopeSizes[s];
			mean += slope;
			stdev += slope*slope;
			counts++;
		}
		mean /= counts;
		stdev /= counts;
		stdev = (stdev > mean*mean ? sqrt(stdev - mean*mean) : 0);

		secondaryFeatures->push_back(mean);
		secondaryFeatures->push_back(stdev);

		//preValley
		mean = 0;
		stdev = 0;
		counts = 0;
		for (size_t i = 0; i < valleyLocs.size(); i++) {
			if (valleyLocs[i] < slopeSizes[s])
				continue;
			float slope = (inputs[valleyLocs[i]] - inputs[valleyLocs[i] - slopeSizes[s]]) / slopeSizes[s];
			mean += slope;
			stdev += slope*slope;
			counts++;
		}
		mean /= counts;
		stdev /= counts;
		stdev = (stdev > mean*mean ? sqrt(stdev - mean*mean) : 0);

		secondaryFeatures->push_back(mean);
		secondaryFeatures->push_back(stdev);

		//postValley
		mean = 0;
		stdev = 0;
		counts = 0;
		for (size_t i = 0; i < valleyLocs.size(); i++) {
			if (valleyLocs[i] >= NUM_INPUTS - slopeSizes[s])
				continue;
			float slope = (inputs[valleyLocs[i] + slopeSizes[s]] - inputs[valleyLocs[i]]) / slopeSizes[s];
			mean += slope;
			stdev += slope*slope;
			counts++;
		}
		mean /= counts;
		stdev /= counts;
		stdev = (stdev > mean*mean ? sqrt(stdev - mean*mean) : 0);

		secondaryFeatures->push_back(mean);
		secondaryFeatures->push_back(stdev);
	}

	return secondaryFeatures->size();
}

void scaleConvSecondaryFeatures(std::vector<FILE*> trainsets, std::vector<FILE*> valsets, std::vector<FILE*> testsets, size_t numFeatures, std::vector<bool>* globalScaleMask) {
#if !defined(USE_FIXED_FEATURES)
	size_t numInputs = NUM_INPUTS;
#else
	size_t numInputs = 1;
#endif
	for (size_t cv = 0; cv < trainsets.size(); cv++) {
		std::cout << "Scaling CV " << cv + 1 << ": ";
		std::vector<long double> featureMeans(numFeatures);
		std::vector<long double> featureStdevs(numFeatures);
		std::vector<float> features(numFeatures*numInputs);

		_fseeki64(trainsets[cv], 0, SEEK_SET);

		size_t numSamples = 0;
		fread(&numSamples, sizeof(size_t), 1, trainsets[cv]);
		size_t numOutputs = 0;
		if (USE_ALL_OUTPUTS)
			numOutputs = (SKIP_FIRST_OUTPUT ? NUM_OUTPUTS - 1 : NUM_OUTPUTS);
#ifdef PEAK_DATA_INCLUDED
		else if (NUM_SIDE_OUTPUT_PEAK_HEIGHTS > 0)
			numOutputs = NUM_SIDE_OUTPUT_PEAK_HEIGHTS * 2 + 1;
#endif
		else
			numOutputs = 1;
		size_t numPreFlags = numOutputs + 1;
		for (size_t s = 0; s < numSamples; s++) {
			_fseeki64(trainsets[cv], numPreFlags*sizeof(float), SEEK_CUR);
			fread(&features[0], sizeof(float), numFeatures*numInputs, trainsets[cv]);
			for (size_t i = 0; i < numInputs; i++) {
				for (size_t f = 0; f < numFeatures; f++) {
					long double val = (long double)features[f + i*numFeatures];
					/*
					if (val != val) {
						//TEST
						std::cout << "Invalid value on sample " << s + 1 << " input " << i + 1 << " feature " << f + 1 << std::endl;
						for (size_t v = 0; v < numFeatures*NUM_INPUTS; v++) {
							std::cout << features[v] << " ";
						}
						std::cout << std::endl;
						system("pause");
					}
					*/
					featureMeans[f] += val;
					featureStdevs[f] += val*val;
				}
			}
		}
		for (size_t f = 0; f < numFeatures; f++) {
			//std::cout << "F" << f + 1 << ": " << featureMeans[f] << " +\\- " << featureStdevs[f] << " ";	//TEST
			//well cast, idiot.
			featureMeans[f] /= (((long double)numSamples)*((long double)numInputs));
			featureStdevs[f] /= (((long double)numSamples)*((long double)numInputs));
			featureStdevs[f] = (featureStdevs[f] > featureMeans[f]*featureMeans[f] ? sqrt(featureStdevs[f] - featureMeans[f] * featureMeans[f]) : 0);
			std::cout << "F" << f + 1 << ": " << featureMeans[f] << " +\\- " << featureStdevs[f] << " ";
		}
		std::cout << std::endl;

		std::stringstream fss;
		fss << "featurenorms_" << cv + 1;
		std::ofstream featurefile(fss.str());
		for (size_t f = 0; f < numFeatures; f++) {
			featurefile << featureMeans[f] << " ";
		}
		featurefile << std::endl;
		for (size_t f = 0; f < numFeatures; f++) {
			featurefile << featureStdevs[f] << " ";
		}
		featurefile << std::endl;
		featurefile.close();

		for (size_t type = 0; type < 3; type++) {
			FILE* typeFile;
			if (type == 0)
				typeFile = trainsets[cv];
			else if (type == 1)
				typeFile = valsets[cv];
			else
				typeFile = testsets[cv];

			_fseeki64(typeFile, 0, SEEK_SET);
			fread(&numSamples, sizeof(size_t), 1, typeFile);
			for (size_t s = 0; s < numSamples; s++) {
				_fseeki64(typeFile, numPreFlags*sizeof(float), SEEK_CUR);
				__int64 initPos = _ftelli64(typeFile);
				fread(&features[0], sizeof(float), numFeatures*numInputs, typeFile);
				_fseeki64(typeFile, initPos, SEEK_SET);
				for (size_t i = 0; i < numInputs; i++) {
					for (size_t f = 0; f < numFeatures; f++) {
						float feat = features[f + i*numFeatures];
#if !defined(USE_FIXED_FEATURES)
						if (globalScaleMask->size() <= f || (*globalScaleMask)[f]) {
							if (featureStdevs[f] > 0)
								feat = (feat - (float)featureMeans[f]) / ((float)featureStdevs[f]);
							else
								feat = 0;
						}
#else
						feat = (feat - (float)featureMeans[f]) / ((float)featureStdevs[f]);
#endif
						fwrite(&feat, sizeof(float), 1, typeFile);
					}
				}
			}
		}
	}
}

#ifdef PEAK_DATA_INCLUDED
void calculatePeakOutputs(float* inputs, float* peaks, std::vector<float>* outputs) {
	std::vector<size_t> peakLocs;
	size_t centerPeak = 0;
	int minDistFromCenter = 9999;
	for (size_t i = 0; i < NUM_INPUTS; i++) {
		if (peaks[i] == 1)
			peakLocs.push_back(i);
		if (abs((int)i - NUM_INPUTS / 2) < minDistFromCenter) {
			centerPeak = peakLocs.size() - 1;
			minDistFromCenter = abs((int)i - NUM_INPUTS / 2);
		}
	}

	outputs->clear();

	for (int i = -NUM_SIDE_OUTPUT_PEAK_HEIGHTS; i <= NUM_SIDE_OUTPUT_PEAK_HEIGHTS; i++) {
		int peakPos = (int)centerPeak + i;
		if (peakPos < 0)
			outputs->push_back(inputs[peakLocs[0]]);
		else if (peakPos > peakLocs.size() - 1)
			outputs->push_back(inputs[peakLocs[peakLocs.size() - 1]]);
		else
			outputs->push_back(inputs[peakLocs[peakPos]]);
	}
}
#endif