#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>

#define datastring ""
//#define datastring "C:/Users/Thomas/Desktop/VMs/rawdata/"

#define NUM_CV_SETS 16

#define NUM_INPUTS 512
#define NUM_OUTPUTS 4

#define HEADER_SIZE 8

#define NORMALIZE_BY_FIRST_TWO_OUTPUTS
#define USE_ALL_OUTPUTS true

#define SAVE_OUTPUT 2

int main() {
	srand((size_t)time(NULL));

	for (size_t cv = 0; cv < NUM_CV_SETS; cv++) {
		std::cout << "Saving testset " << cv + 1 << ": ";
		std::stringstream filess;
		filess << "testfiles_" << cv + 1;
		std::string filefname = filess.str();

		std::stringstream testss;
		testss << "testset_" << cv + 1;
		std::string testfname = testss.str();

		size_t dum = 0;
		FILE* testfile = fopen((datastring + testfname).c_str(), "wb");
		fwrite(&dum, sizeof(size_t), 1, testfile);

		size_t testSamples = 0;

		std::ifstream filelist(datastring + filefname);
		std::string line;
		while (std::getline(filelist, line)) {
			std::stringstream lss(line);
			float personIdentifier;
			std::string binfname;
			lss >> personIdentifier >> binfname;

			std::vector<float> columns(NUM_INPUTS + NUM_OUTPUTS);

			FILE* infile = fopen((datastring + binfname).c_str(), "rb");
			fseek(infile, HEADER_SIZE, SEEK_SET);

			while (fread(&columns[0], sizeof(float), NUM_INPUTS + NUM_OUTPUTS, infile) == NUM_INPUTS + NUM_OUTPUTS) {
				float minInput = 9999;
				float maxInput = -9999;
#ifndef NORMALIZE_BY_FIRST_TWO_OUTPUTS
				for (size_t in = 0; in < NUM_INPUTS; in++) {
					minInput = std::min(minInput, columns[in + NUM_OUTPUTS]);
					maxInput = std::max(maxInput, columns[in + NUM_OUTPUTS]);
				}
#else
				minInput = columns[0];
				maxInput = columns[1];
#endif
				for (size_t in = 0; in < NUM_INPUTS; in++) {
					columns[in + NUM_OUTPUTS] = 2.0f*(columns[in + NUM_OUTPUTS] - minInput) / (maxInput - minInput) - 1.0f;
				}

				if (USE_ALL_OUTPUTS)
					fwrite(&columns[0], sizeof(float), NUM_OUTPUTS, testfile);
				else
					fwrite(&columns[SAVE_OUTPUT - 1], sizeof(float), 1, testfile);
				fwrite(&personIdentifier, sizeof(float), 1, testfile);
				fwrite(&columns[NUM_OUTPUTS], sizeof(float), NUM_INPUTS, testfile);

				testSamples++;
			}
			fclose(infile);
		}
		fseek(testfile, 0, SEEK_SET);
		fwrite(&testSamples, sizeof(size_t), 1, testfile);
		fclose(testfile);
		std::cout << "Done." << std::endl;
	}

	system("pause");
}