#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>

#define datastring ""
//#define datastring "D:/trivialNetworkTest/testdata/"

#define NUM_INPUTS 512
#define NUM_OUTPUTS 4
#define NUM_ADD_FLAGS 1

int main() {
	srand((size_t)time(NULL));

	size_t firstCV = 0;
	std::cout << "Enter first error CV: ";
	std::cin >> firstCV;

	size_t numSets = 0;
	std::cout << "Enter last error CV: ";
	std::cin >> numSets;

	std::vector<float> sample(NUM_INPUTS + NUM_OUTPUTS + NUM_ADD_FLAGS);

	for (size_t cv = firstCV; cv < numSets; cv++) {
		size_t dum = 0;
		size_t numTrainSamples = 0;
		size_t numTestSamples = 0;
		std::stringstream trainss;
		trainss << "fullerrortrainset" << cv + 1;
		FILE* trainfile = fopen(trainss.str().c_str(), "wb");
		fwrite(&dum, sizeof(size_t), 1, trainfile);

		std::stringstream testss;
		testss << "fullerrortestset" << cv + 1;
		FILE* testfile = fopen(testss.str().c_str(), "wb");
		fwrite(&dum, sizeof(size_t), 1, testfile);

		for (size_t s = firstCV; s < numSets; s++) {
			std::stringstream errss;
			errss << "errorset" << s + 1;
			FILE* errfile = fopen(errss.str().c_str(), "rb");
			FILE* outfile = (s == cv ? testfile : trainfile);
			size_t errcount;
			fread(&errcount, sizeof(size_t), 1, errfile);

			if (s == cv)
				numTestSamples += errcount;
			else
				numTrainSamples += errcount;

			for (size_t i = 0; i < errcount; i++) {
				fread(&sample[0], sizeof(float), NUM_INPUTS + NUM_OUTPUTS + NUM_ADD_FLAGS, errfile);
				fwrite(&sample[0], sizeof(float), NUM_INPUTS + NUM_OUTPUTS + NUM_ADD_FLAGS, outfile);
			}
		}

		fseek(trainfile, 0, SEEK_SET);
		fwrite(&numTrainSamples, sizeof(size_t), 1, trainfile);
		fseek(testfile, 0, SEEK_SET);
		fwrite(&numTrainSamples, sizeof(size_t), 1, testfile);
	}
}