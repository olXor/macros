#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>
#include <list>

#define datastring ""
//#define datastring "D:/trivialNetworkTest/testdata/"

#define PERSON_COLUMN 5U
#define GROUND_TRUTH_COLUMN 7U
#define PREDICTION_COLUMN 6U

#define WINDOWSIZE_1 5U
#define WINDOWSIZE_2 10U

#define STDEV_WINDOWSIZE 10U

int main() {
	srand((size_t)time(NULL));

	std::vector<std::string> cvfnames;
	bool moreCVs = true;
	while (moreCVs) {
		std::string fname;
		std::cout << "Enter result file: ";
		std::cin >> fname;
		cvfnames.push_back(datastring + fname);

		std::cout << "Enter another result file? ";
		std::cin >> moreCVs;
	}

	size_t lastPerson = 99999;
	for (size_t cv = 0; cv < cvfnames.size(); cv++) {
		std::ifstream infile(cvfnames[cv]);
		std::string line;

		std::list<float> prevTruth;
		std::list<float> prevPred;

		std::vector<std::vector<float>> errors(3);	//first index: truth type by window size, second index: prediction type
		std::vector<std::vector<size_t>> samples(3);	//same index structure
		for (size_t i = 0; i < 3; i++) {
			errors[i].resize(3);
			samples[i].resize(3);
		}

		std::vector<float> truthMeans;
		std::vector<float> predMedians;

		while (std::getline(infile, line)) {
			size_t person = 99999;
			float groundTruth = 99999;
			float prediction = 99999;

			std::stringstream lss(line);
			float val;
			size_t col = 0;
			while (lss >> val) {
				col++;
				if (col == PERSON_COLUMN)
					person = (size_t)val;
				else if (col == GROUND_TRUTH_COLUMN)
					groundTruth = val;
				else if (col == PREDICTION_COLUMN)
					prediction = val;

				prevTruth.push_back(groundTruth);
				prevPred.push_back(prediction);

				if (prevTruth.size() > std::max(WINDOWSIZE_2, STDEV_WINDOWSIZE)) {
					prevTruth.pop_front();
					prevPred.pop_front();
				}
				
				/*
				float truthMean1 = 0;
				if (prevTruth.size() >= WINDOWSIZE_1) {
					for (std::list<float>::reverse_iterator it = prevTruth.rbegin(); it != prevTruth.rbegin() + WINDOWSIZE_1; it++) {
						//truthMean1 += (*it);
					}
					truthMean1 /= WINDOWSIZE_1;
				}
				float truthMean2 = 0;
				if (prevTruth.size() >= WINDOWSIZE_2) {
					for (std::list<float>::reverse_iterator it = prevTruth.rbegin(); it != prevTruth.rbegin() + WINDOWSIZE_2; it++) {
						//truthMean2 += (*it);
					}
					truthMean2 /= WINDOWSIZE_2;
				}
				*/
			}
		}

	}
}
