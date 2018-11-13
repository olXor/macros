#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>

#define datastring ""
//#define datastring "D:/trivialNetworkTest/resultCombine/"

#define TEST_COLUMN 6

#define NUM_INPUTS 512
#define NUM_OUTPUTS 4
#define CORRECT_OUTPUT 2
#define NUM_ADD_FLAGS 1
#define NUM_SILENT_OUTPUTS 0
#define HEADER_SIZE 4	//header in binfile created by trivialbinpacker, so it's different from the flag in that program

#define TRAIN_INCLUDESIZE 200000

template <typename T> void randomizeVector(std::vector<T>* vec) {
	for (size_t i = 0; i < vec->size(); i++) {
		size_t j = (RAND_MAX*rand() + rand()) % vec->size();
		T tmp = (*vec)[i];
		(*vec)[i] = (*vec)[j];
		(*vec)[j] = tmp;
	}
}

void main() {
	srand((size_t)time(NULL));

	size_t numCVs;
	std::cout << "Enter number of cv sets: ";
	std::cin >> numCVs;

	size_t numNetworks;
	std::cout << "Enter number of networks: ";
	std::cin >> numNetworks;

	std::string trainfname = "choicetrainset";
	std::string testfname = "choicetestset";

	std::ofstream resfile("resultaverages");

	std::vector<FILE*> choicetrainsets(numCVs);
	std::vector<FILE*> choicetestsets(numCVs);
	size_t dum = 0;
	for (size_t cv = 0; cv < numCVs; cv++) {
		std::stringstream numss;
		numss << "_" << cv + 1;
		choicetrainsets[cv] = fopen((datastring + trainfname + numss.str()).c_str(), "wb");
		fwrite(&dum, sizeof(size_t), 1, choicetrainsets[cv]);
		choicetestsets[cv] = fopen((datastring + testfname + numss.str()).c_str(), "wb");
		fwrite(&dum, sizeof(size_t), 1, choicetestsets[cv]);
	}

	std::vector<size_t> trainCounts(numCVs);
	std::vector<size_t> testCounts(numCVs);
	std::vector<float> networkErrors(numNetworks);
	float averageError = 0;
	float optimalError = 0;
	size_t totalCount = 0;
	size_t numColumns = NUM_INPUTS + NUM_OUTPUTS + NUM_SILENT_OUTPUTS + NUM_ADD_FLAGS;
	for (size_t cv = 0; cv < numCVs; cv++) {
		std::cout << "Starting CV " << cv + 1 << ": ";
		std::vector<std::ifstream> networkfiles(numNetworks);
		std::vector<float> networkOutputs(numNetworks);
		std::vector<float> columns(numColumns);
		std::vector<float> cvNetworkErrors(numNetworks);
		float cvAverageError = 0;
		float cvOptimalError = 0;
		size_t cvCount = 0;

		std::stringstream testss;
		testss << datastring << "testset_" << cv + 1;
		FILE* testset = fopen(testss.str().c_str(), "rb");
		if (testset == NULL) {
			std::cout << "Couldn't find testset_" << cv + 1 << std::endl;
			system("pause");
			return;
		}

		for (size_t n = 0; n < numNetworks; n++) {
			std::stringstream netss;
			netss << datastring << "testresults_c" << cv + 1 << "_n" << n + 1;
			networkfiles[n].open(netss.str());
			if (!networkfiles[n].is_open()) {
				std::cout << "Couldn't find " << netss.str() << std::endl;
				system("pause");
				return;
			}
		}
		size_t numSamples = 0;
		fseek(testset, HEADER_SIZE, SEEK_SET);
		while (fread(&columns[0], sizeof(float), numColumns, testset) == numColumns) {
			numSamples++;
		}

		std::vector<std::vector<size_t>> testsetIndices(numCVs);
		for (size_t testCV = 0; testCV < testsetIndices.size(); testCV++) {
			testsetIndices[testCV].resize(numSamples);
			for (size_t i = 0; i < testsetIndices[testCV].size(); i++)
				testsetIndices[testCV][i] = i;
			randomizeVector(&testsetIndices[testCV]);
		}

		fseek(testset, HEADER_SIZE, SEEK_SET);

		size_t testIndex = 0;
		while (fread(&columns[0], sizeof(float), numColumns, testset) == numColumns) {
			bool testresultDone = false;
			for (size_t n = 0; n < numNetworks; n++) {
				std::string line;
				if (!std::getline(networkfiles[n], line)) {
					testresultDone = true;
					break;
				}
				std::stringstream lss(line);
				for (size_t l = 0; l < NUM_OUTPUTS; l++) {
					float val;
					lss >> val;
					std::stringstream forss;
					forss << columns[l];
					float roundVal;
					forss >> roundVal;
					if (val != roundVal) {
						std::cout << "Unmatched input in testresults_c" << cv + 1 << "_n" << n + 1 << ": " << val << " vs. " << roundVal << std::endl;
						system("pause");
						return;
					}
				}
				for (size_t l = NUM_OUTPUTS; l < TEST_COLUMN - 1; l++) {
					std::string dum;
					lss >> dum;
				}
				lss >> networkOutputs[n];
			}

			if (testresultDone)
				break;

			float corOutput = columns[CORRECT_OUTPUT - 1];
			float minError = 9999;
			float minNetwork = 0;
			float optimalOutput = 0;
			float averageOutput = 0;
			for (size_t n = 0; n < numNetworks; n++) {
				float err = fabs(networkOutputs[n] - corOutput);
				averageOutput += networkOutputs[n];
				if (err < minError) {
					minError = err;
					minNetwork = n;
					optimalOutput = networkOutputs[n];
				}
				cvNetworkErrors[n] += err;
				networkErrors[n] += err;
			}
			averageOutput /= numNetworks;
			cvAverageError += fabs(averageOutput - corOutput);
			averageError += fabs(averageOutput - corOutput);
			cvOptimalError += fabs(optimalOutput - corOutput);
			optimalError += fabs(optimalOutput - corOutput);
			cvCount++;
			totalCount++;

			for (size_t c = 0; c < numCVs; c++) {
				FILE* outfile;
				size_t* count;
				if (c == cv) {
					outfile = choicetestsets[c];
					count = &testCounts[c];
				}
				else {
					outfile = choicetrainsets[c];
					count = &trainCounts[c];
				}
				if (c == cv || testsetIndices[c][testIndex] < TRAIN_INCLUDESIZE) {
					for (size_t n = 0; n < numNetworks; n++) {
						float out;
						if (n == minNetwork)
							out = 1;
						else
							out = -1;
						fwrite(&out, sizeof(float), 1, outfile);
					}

					fwrite(&columns[0], sizeof(float), NUM_OUTPUTS + NUM_SILENT_OUTPUTS + NUM_ADD_FLAGS + NUM_INPUTS, outfile);
					(*count)++;
				}
			}
			testIndex++;
		}

		std::cout << cvCount << " samples read, Net Errors: ";
		resfile << cv + 1 << ": ";
		for (size_t n = 0; n < numNetworks; n++) {
			std::cout << n + 1 << ": " << cvNetworkErrors[n] / cvCount << " ";
			resfile << cvNetworkErrors[n] / cvCount << " ";
		}
		std::cout << "Average: " << cvAverageError / cvCount << " Optimal: " << cvOptimalError / cvCount << std::endl;
		resfile << cvAverageError / cvCount << " " << cvOptimalError / cvCount << std::endl;
	}

	for (size_t cv = 0; cv < numCVs; cv++) {
		fseek(choicetrainsets[cv], 0, SEEK_SET);
		fwrite(&trainCounts[cv], sizeof(size_t), 1, choicetrainsets[cv]);
		fseek(choicetestsets[cv], 0, SEEK_SET);
		fwrite(&testCounts[cv], sizeof(size_t), 1, choicetestsets[cv]);
	}
	std::cout << std::endl << "Total Samples: " << totalCount << " Net Errors: ";
	resfile << "Total: ";
	for (size_t n = 0; n < numNetworks; n++) {
		std::cout << n + 1 << ": " << networkErrors[n] / totalCount << " ";
		resfile << networkErrors[n] / totalCount << " ";
	}
	std::cout << "Average: " << averageError / totalCount << " Optimal: " << optimalError / totalCount << std::endl;
	resfile << averageError / totalCount << " " << optimalError / totalCount << std::endl;
	system("pause");
	system("pause");
}