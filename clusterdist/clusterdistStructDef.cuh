#pragma once
#include <iostream>
#include <string>
#include <sstream>
#include <fstream>
#include <vector>
#include <algorithm>
#include <time.h>

void throwError(std::string err) {
	std::cout << err << std::endl;
	system("pause");
	throw std::runtime_error(err);
}

struct Histogram2D {
	float min1;
	float max1;
	float min2;
	float max2;
	size_t numBins1;
	size_t numBins2;
	std::vector<float> bins;
	float totalWeight = 0;

	void initHistogram(float newMin1, float newMax1, float newMin2, float newMax2, size_t newNumBins1, size_t newNumBins2) {
		if (!(newMax1 > newMin1) || !(newMax2 > newMin2))
			throwError("Histogram max must be greater than min");
		min1 = newMin1;
		max1 = newMax1;
		min2 = newMin2;
		max2 = newMax2;
		numBins1 = newNumBins1;
		numBins2 = newNumBins2;
		bins.clear();
		bins.resize(numBins1*numBins2);
	}

	void fill(float val1, float val2, float weight) {
		size_t pos1;
		size_t pos2;
		if (val1 < min1)
			pos1 = 0;
		else if (val1 >= max1)
			pos1 = numBins1 - 1;
		else
			pos1 = (size_t)(numBins1*(val1 - min1) / (max1 - min1));
		if (val2 < min2)
			pos2 = 0;
		else if (val2 >= max2)
			pos2 = numBins2 - 1;
		else
			pos2 = (size_t)(numBins2*(val2 - min2) / (max2 - min2));

		bins[pos1 + pos2*numBins1] += weight;
		totalWeight += weight;
	}

	void fillByBin(size_t bin1, size_t bin2, float weight) {
		if (bin1 > numBins1 || bin2 > numBins2)
			throwError("Tried to fill bin out of histogram range");
		bins[bin1 + bin2*numBins1] += weight;
		totalWeight += weight;
	}

	void clearFill() {
		bins.clear();
		bins.resize(numBins1*numBins2);
		totalWeight = 0;
	}
};