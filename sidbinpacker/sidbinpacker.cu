#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>
#include <windows.h>

#define datastring ""
//#define datastring "D:/trivialNetworkTest/testdata/"

#define NUM_INPUTS 27
#define NUM_OUTPUTS 9
#define NUM_POST_OUTPUTS 5
#define USE_ALL_OUTPUTS true
#define SAVE_OUTPUT 2
#define HEADER_SIZE 8
#define TEST_FRACTION 0.3
#define NUM_SAMPLES_PER_PERSON 10000
#define NUM_VAL_SAMPLES_PER_PERSON 5000
#define CUT_ON_AVERAGE_BP true
#define MIN_AVERAGE_OUTPUT 0
#define MAX_AVERAGE_OUTPUT 85
#define OUT_AVERAGE_SAMPLES 10000
#define OUT_AVERAGE_INDEX 2

#define OUTLIERS_TO_TRAINSET

size_t NUM_CV_SETS = 16;

void readOldTestfiles(std::vector<std::vector<std::string>>* testfiles);

template <typename T> void randomizeVector(std::vector<T>* vec) {
	for (size_t i = 0; i < vec->size(); i++) {
		size_t j = (RAND_MAX*rand() + rand()) % vec->size();
		T tmp = (*vec)[i];
		(*vec)[i] = (*vec)[j];
		(*vec)[j] = tmp;
	}
}

float transformVariable(float in) {
	float inup = (in + 1.0f)/2.0f;
	return (inup*inup*2 - 1.0f);
}

void transformInput(std::vector<float>* columns) {

}

int main() {
	srand((size_t)time(NULL));

	std::cout << "Enter number of CV sets: ";
	std::cin >> NUM_CV_SETS;

	bool useOldTestsets = false;
	std::cout << "Use old testfile lists? ";
	std::cin >> useOldTestsets;

	std::string filelist = "filelist";
	std::ifstream infilelist(datastring + filelist);
	if (!infilelist.is_open()) {
		std::cout << "Couldn't open file list " << datastring << filelist << std::endl;
	}

	std::vector<std::vector<std::string>> oldtestfiles;
	if (useOldTestsets)
		readOldTestfiles(&oldtestfiles);

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
		numss << "_" << i + 1;
		trainsets[i] = fopen((datastring + trainfname + numss.str()).c_str(), "wb");
		fwrite(&dum, sizeof(size_t), 1, trainsets[i]);
		valsets[i] = fopen((datastring + valfname + numss.str()).c_str(), "wb");
		fwrite(&dum, sizeof(size_t), 1, valsets[i]);
		testsets[i] = fopen((datastring + testfname + numss.str()).c_str(), "wb");
		fwrite(&dum, sizeof(size_t), 1, testsets[i]);

		std::stringstream trainss;
		trainss << datastring << "trainfiles_" << i + 1;
		trainfilelists[i].open(trainss.str());
		if (!useOldTestsets) {
			std::stringstream testss;
			testss << datastring << "testfiles_" << i + 1;
			testfilelists[i].open(testss.str());
		}
	}

	std::vector<size_t> trainSamples(NUM_CV_SETS);
	std::vector<size_t> valSamples(NUM_CV_SETS);
	std::vector<size_t> testSamples(NUM_CV_SETS);

	float personIdentifier = 0;
	std::string line;
	while (std::getline(infilelist, line)) {
		std::string fname;
		(std::stringstream(line)) >> fname;
		std::cout << "Reading folder " << fname << ": " << std::endl;

		size_t choiceNum;
		if (!useOldTestsets) {
			float ranChoice = 1.0f*(rand() % 10000) / 10000.0f;
			if (NUM_CV_SETS > 1) {
				choiceNum = NUM_CV_SETS*ranChoice + 1;
				if (choiceNum > NUM_CV_SETS)
					choiceNum = NUM_CV_SETS;
			}
			else {
				choiceNum = (ranChoice < TEST_FRACTION ? 1 : 0);
			}
		}
		else {
			choiceNum = 0;
			for (size_t i = 0; i < oldtestfiles.size(); i++) {
				for (size_t j = 0; j < oldtestfiles[i].size(); j++) {
					if (oldtestfiles[i][j] == fname) {
						choiceNum = i + 1;
						break;
					}
				}
			}
		}

		personIdentifier += 1.0f;

		HANDLE hFind;
		WIN32_FIND_DATA findFileData;

		hFind = FindFirstFile(((std::string)datastring + fname + "/*.csv").c_str(), &findFileData);
		if (hFind == INVALID_HANDLE_VALUE) {
			std::string err = "Couldn't find any csv files in folder " + fname;
			std::cout << err << std::endl;
			throw std::runtime_error(err);
		}

		do {
			size_t* choiceSamples;

			std::ifstream infile(fname + "/" + findFileData.cFileName);
			std::string line;
			std::getline(infile, line);	//header

			std::vector<float> columns(NUM_INPUTS + NUM_OUTPUTS + NUM_POST_OUTPUTS);
			std::cout << "	" << fname + "/" + findFileData.cFileName << " going to CV set" << choiceNum << std::endl;

			for (size_t cv = 0; cv < NUM_CV_SETS; cv++) {
				if (cv + 1 == choiceNum && !useOldTestsets)
					testfilelists[cv] << personIdentifier << " " << fname << std::endl;
				else
					trainfilelists[cv] << personIdentifier << " " << fname << std::endl;
			}

			while (std::getline(infile, line)) {
				std::replace(line.begin(), line.end(), ',', ' ');
				std::stringstream lss(line);
				for (size_t c = 0; c < NUM_INPUTS + NUM_OUTPUTS + NUM_POST_OUTPUTS; c++) {
					lss >> columns[c];
				}

				for (size_t cv = 0; cv < NUM_CV_SETS; cv++) {
					FILE* dataset;
					if (cv + 1 == choiceNum) {
						dataset = testsets[cv];
						choiceSamples = &testSamples[cv];
					}
					else {
						dataset = trainsets[cv];
						choiceSamples = &trainSamples[cv];
					}

					if (USE_ALL_OUTPUTS)
						fwrite(&columns[0], sizeof(float), NUM_OUTPUTS, dataset);
					else
						fwrite(&columns[SAVE_OUTPUT - 1], sizeof(float), 1, dataset);
					fwrite(&personIdentifier, sizeof(float), 1, dataset);
					fwrite(&columns[NUM_OUTPUTS], sizeof(float), NUM_INPUTS, dataset);

					(*choiceSamples)++;
				}
			}
			infile.close();
		} while (FindNextFile(hFind, &findFileData) != NULL);
	}
	for (size_t c = 0; c < NUM_CV_SETS; c++) {
		fseek(trainsets[c], 0, SEEK_SET);
		fwrite(&trainSamples[c], sizeof(size_t), 1, trainsets[c]);
		fclose(trainsets[c]);

		fseek(valsets[c], 0, SEEK_SET);
		fwrite(&valSamples[c], sizeof(size_t), 1, valsets[c]);
		fclose(valsets[c]);

		fseek(testsets[c], 0, SEEK_SET);
		fwrite(&testSamples[c], sizeof(size_t), 1, testsets[c]);
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
		testss << datastring << "testfiles_" << t + 1;
		std::ifstream testfile(testss.str());
		std::string line;
		std::vector<std::string> fnames;
		while (std::getline(testfile, line)) {
			size_t dum;
			std::string fname;
			std::stringstream lss(line);
			lss >> dum >> fname;
			fnames.push_back(fname);
		}
		testfiles->push_back(fnames);
		testfile.close();
	}
}
