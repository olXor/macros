#include <iostream>
#include <string>
#include <sstream>
#include <fstream>
#include <vector>
#include <algorithm>
#include <time.h>

#define CHECK_STEP_SIZE 100000

#define datastring "D:/stopSearch/data/"

void readInputs(std::vector<std::vector<float>>* inputs, std::string infname);
float median(float a, float b, float c);
void swap(std::vector<float>* A, size_t i, size_t j);
void quicksort(std::vector<float>* A, size_t lo, size_t hi);
void sortVector(std::vector<float>* A, size_t lo = 0, size_t hi = 0);
float evaluateMaxAMS(std::vector<std::vector<float>>* signalInputs, std::vector<std::vector<float>>* backgroundInputs, std::vector<std::vector<float>>* indivSort, std::vector<size_t>* cutLocs, std::vector<size_t>* maxCutLocs, size_t index, float stepSize);
void optimizeCuts(std::vector<std::vector<float>>* signalInputs, std::vector<std::vector<float>>* backgroundInputs, std::vector<std::vector<float>>* indivSort);
float evaluateAMS(std::vector<std::vector<float>>* signalInputs, std::vector<std::vector<float>>* backgroundInputs, std::vector<float> cuts);

int main() {
	srand((size_t)time(NULL));
	std::string signalFile;
	std::string backgroundFile;
	std::cout << "Enter signal file: ";
	std::cin >> signalFile;
	std::cout << "Enter background file: ";
	std::cin >> backgroundFile;

	bool manualCuts;
	std::cout << "Enter cuts manually? ";
	std::cin >> manualCuts;
	
	std::vector<std::vector<float>> signalInputs;
	std::vector<std::vector<float>> backgroundInputs;
	std::cout << "Reading inputs..." << std::endl;
	readInputs(&signalInputs, datastring + signalFile);
	readInputs(&backgroundInputs, datastring + backgroundFile);
	std::cout << "Sorting inputs..." << std::endl;
	std::vector<std::vector<float>> indivSort = signalInputs;
	for (size_t i = 0; i < backgroundInputs.size(); i++) {
		for (size_t j = 0; j < backgroundInputs[i].size(); j++)
			indivSort[i].push_back(backgroundInputs[i][j]);
	}
	for (size_t i = 0; i < indivSort.size(); i++) {
		sortVector(&indivSort[i]);
	}

	if (!manualCuts) {
		std::cout << "Optimizing..." << std::endl;
		for (size_t i = 0; i < 20; i++) {
			optimizeCuts(&signalInputs, &backgroundInputs, &indivSort);
			std::cout << std::endl;
		}
		std::cout << "Done. " << std::endl;
	}
	else {
		while (true) {
			std::vector<float> cuts(signalInputs.size());
			for (size_t i = 0; i < signalInputs.size(); i++) {
				std::cout << "Enter cut " << i << ": ";
				std::cin >> cuts[i];
			}
			std::cout << "AMS: " << evaluateAMS(&signalInputs, &backgroundInputs, cuts) << std::endl;
		}
	}
}

void optimizeCuts(std::vector<std::vector<float>>* signalInputs, std::vector<std::vector<float>>* backgroundInputs, std::vector<std::vector<float>>* indivSort) {
	std::vector<size_t> cutLocs;
	for (size_t i = 0; i < (*indivSort).size(); i++) {
		size_t randIndex = rand() + rand() * RAND_MAX;
		cutLocs.push_back(randIndex % (*indivSort)[i].size());
	}
	std::cout << "Starting Cuts: ";
	for (size_t i = 0; i < cutLocs.size(); i++)
		std::cout << (*indivSort)[i][cutLocs[i]] << " ";
	std::cout << std::endl;

	std::vector<size_t> maxCutLocs = cutLocs;
	float ams = 0;
	for (float stepSize = CHECK_STEP_SIZE; stepSize >= 1; stepSize *= 0.9) {
		do {
			cutLocs = maxCutLocs;
			ams = evaluateMaxAMS(signalInputs, backgroundInputs, indivSort, &cutLocs, &maxCutLocs, 0, stepSize);
		} while (cutLocs != maxCutLocs);
	}
	std::cout << "AMS: " << ams << " Cuts: ";
	for (size_t i = 0; i < maxCutLocs.size(); i++)
		std::cout << (*indivSort)[i][maxCutLocs[i]] << " ";
	std::cout << std::endl;
}

float evaluateMaxAMS(std::vector<std::vector<float>>* signalInputs, std::vector<std::vector<float>>* backgroundInputs, std::vector<std::vector<float>>* indivSort, std::vector<size_t>* cutLocs, std::vector<size_t>* maxCutLocs, size_t index, float stepSize) {
	if (index < cutLocs->size()) {
		float maxAMS = -9999;
		for (size_t diffRes = 0; diffRes < 3;diffRes++) {
			int diff = (diffRes == 2 ? -1 : (int)diffRes);
			std::vector<size_t> newCuts = (*cutLocs);
			std::vector<size_t> newMaxCuts = (*cutLocs);
			if (diff < 0 && size_t(newCuts[index] + diff*stepSize) >= (*indivSort)[index].size())
				newCuts[index] = 0;
			else if (diff > 0 && size_t(newCuts[index] + diff*stepSize) >= (*indivSort)[index].size())
				newCuts[index] = (*indivSort)[index].size() - 1;
			else
				newCuts[index] = (size_t)(newCuts[index] + diff*stepSize);
			float nextAMS = evaluateMaxAMS(signalInputs, backgroundInputs, indivSort, &newCuts, &newMaxCuts, index + 1, stepSize);
			if (nextAMS > maxAMS) {
				maxAMS = nextAMS;
				(*maxCutLocs) = newMaxCuts;
			}
		}
		return maxAMS;
	}

	(*maxCutLocs) = (*cutLocs);

	float srate = 0;
	float brate = 0;
	float breg = 10;
	for (size_t i = 0; i < (*signalInputs)[0].size(); i++) {
		bool chosen = true;
		for (size_t j = 0; j < (*signalInputs).size(); j++) {
			float cutVal = (*indivSort)[j][(*cutLocs)[j]];
			if ((*signalInputs)[j][i] <= cutVal) {
				chosen = false;
				break;
			}
		}

		if (chosen)
			srate += 0.00184 * 35900 / 1968700;	//35.9 fb^-1, 1.9e6 events
	}
	for (size_t i = 0; i < (*backgroundInputs)[0].size(); i++) {
		bool chosen = true;
		for (size_t j = 0; j < (*backgroundInputs).size(); j++) {
			float cutVal = (*indivSort)[j][(*cutLocs)[j]];
			if ((*backgroundInputs)[j][i] <= cutVal) {
				chosen = false;
				break;
			}
		}

		if (chosen)
			brate += 24.6 * 35900 / 7329772;	//7e6 events
	}

	float ams = std::sqrt(2 * ((srate + brate + breg)*std::log(1 + srate / (brate + breg)) - srate));
	return ams;
}

void readInputs(std::vector<std::vector<float>>* inputs, std::string infname) {
	std::ifstream infile(infname);
	if (!infile.is_open())
		std::cout << "Couldn't open input file " << infname << std::endl;
	inputs->clear();

	std::string line;
	while (std::getline(infile, line)) {
		std::stringstream lss(line);
		std::vector<float> ins;
		float val;
		while (lss >> val) {};	//take only last input

		ins.push_back(val);

		if (inputs->size() != 0 && inputs->size() != ins.size()) {
			std::cout << "Uneven number of inputs in file!" << std::endl;
			throw std::runtime_error("");
		}

		inputs->resize(ins.size());
		for (size_t i = 0; i < ins.size(); i++) {
			(*inputs)[i].push_back(ins[i]);
		}
	}
}

float median(float a, float b, float c) {
	return std::max(std::min(a, b), std::min(std::max(a, b), c));
}

void swap(std::vector<float>* A, size_t i, size_t j) {
	float tmp = (*A)[i];
	(*A)[i] = (*A)[j];
	(*A)[j] = tmp;
}

void quicksort(std::vector<float>* A, size_t lo, size_t hi) {
	if (lo >= hi)
		return;
	float pivot = median((*A)[lo], (*A)[hi], (*A)[(lo + hi) / 2]);
	size_t i = lo - 1;
	size_t j = hi + 1;
	while (true) {
		do {
			i++;
		} while (i <= hi && (*A)[i] < pivot);
		do{
			j--;
		} while (j >= lo && (*A)[j] > pivot);
		if (i >= j)
			break;
		swap(A, i, j);
	}
	quicksort(A, lo, j);
	quicksort(A, j + 1, hi);
}

void sortVector(std::vector<float>* A, size_t lo, size_t hi) {
	if (hi == 0)
		hi = A->size() - 1;
	quicksort(A, lo, hi);
}

float evaluateAMS(std::vector<std::vector<float>>* signalInputs, std::vector<std::vector<float>>* backgroundInputs, std::vector<float> cuts) {
	float srate = 0;
	float brate = 0;
	float breg = 10;
	for (size_t i = 0; i < (*signalInputs)[0].size(); i++) {
		bool chosen = true;
		for (size_t j = 0; j < (*signalInputs).size(); j++) {
			float cutVal = cuts[j];
			if ((*signalInputs)[j][i] <= cutVal) {
				chosen = false;
				break;
			}
		}

		if (chosen)
			srate += 0.00184 * 35900 / 1968700;	//35.9 fb^-1, 1.9e6 events
	}
	for (size_t i = 0; i < (*backgroundInputs)[0].size(); i++) {
		bool chosen = true;
		for (size_t j = 0; j < (*backgroundInputs).size(); j++) {
			float cutVal = cuts[j];
			if ((*backgroundInputs)[j][i] <= cutVal) {
				chosen = false;
				break;
			}
		}

		if (chosen)
			brate += 24.6 * 35900 / 7329772;	//7e6 events
	}

	std::cout << "srate: " << srate << " brate: " << brate << std::endl;
	float ams = std::sqrt(2 * ((srate + brate + breg)*std::log(1 + srate / (brate + breg)) - srate));
	return ams;
}