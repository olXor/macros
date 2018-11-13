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

struct Histogram1D {
	float min;
	float max;
	size_t numBins;
	float totalWeight = 0;
	std::vector<float> bins;

	void initHistogram(float newMin, float newMax, size_t newNumBins) {
		if (!(newMax > newMin))
			throwError("Histogram max must be greater than min");
		min = newMin;
		max = newMax;
		numBins = newNumBins;
		bins.clear();
		bins.resize(numBins);
	}

	void fill(float val, float weight) {
		size_t pos;
		if (val < min)
			pos = 0;
		else if (val >= max)
			pos = numBins - 1;
		else
			pos = (size_t)(numBins*(val - min) / (max - min));

		bins[pos] += weight;
		totalWeight += weight;
	}

	void fillByBin(size_t bin, float weight) {
		if (bin > numBins)
			throwError("Tried to fill bin out of histogram range");
		bins[bin] += weight;
		totalWeight += weight;
	}
};

struct SparseHistogramBin {
	std::vector<size_t> binLoc;
	float weight = 0;
	__int64 key;
};

struct SparseHistogram {
	size_t dimension = 2;
	std::vector<float> mins;
	std::vector<float> maxes;
	std::vector<size_t> numBins;
	std::vector<SparseHistogramBin> bins;	//just for storage
	std::vector<size_t> binIndices;	//this is ordered by key
	float totalWeight = 0;
	bool boundaryFlag = false;	//denotes that all filled bins are on the boundary

	void clearFill() {
		bins.clear();
		binIndices.clear();
		totalWeight = 0;
	}

	void initHistogram(std::vector<float> newMins, std::vector<float> newMaxes, std::vector<size_t> newNumBins) {
		if (newMins.size() != newMaxes.size() || newNumBins.size() != newMins.size())
			throwError("SparseHistogram creation: all input arrays must have same dimension");
		dimension = newMins.size();
		for (size_t i = 0; i < dimension; i++) {
			if (newMins[i] >= newMaxes[i])
				throwError("Histogram max must be greater than min");
			mins.push_back(newMins[i]);
			maxes.push_back(newMaxes[i]);
			numBins.push_back(newNumBins[i]);
		}
	}

	void insertBin(std::vector<size_t>* pos, float weight, __int64 key, size_t pointerLoc) {
		SparseHistogramBin newBin;
		newBin.binLoc = (*pos);
		newBin.weight = weight;
		newBin.key = key;

		bins.push_back(newBin);
		if (binIndices.size() > 0 && pointerLoc < binIndices.size())
			binIndices.insert(binIndices.begin() + pointerLoc, bins.size() - 1);
		else
			binIndices.push_back(bins.size() - 1);
	}

	size_t getClosestBin(std::vector<size_t>* pos, int* dirFlag) {
		if (binIndices.size() == 0)
			return 0;

		__int64 key = 0;
		__int64 mult = 1;
		for (size_t i = 0; i < dimension; i++) {
			key += (*pos)[i] * mult;
			mult *= numBins[i];
		}

		size_t low = 0;
		size_t high = binIndices.size() - 1;
		SparseHistogramBin* checkBin = NULL;
		size_t checkPos = 0;
		while (low <= high && high < binIndices.size()) {
			size_t mid = (low + high) / 2;
			checkBin = &bins[binIndices[mid]];
			checkPos = mid;
			if (checkBin->key > key)
				high = mid - 1;
			else if (checkBin->key < key)
				low = mid + 1;
			else
				break;
		}

		if (checkBin->key > key)
			(*dirFlag) = 1;
		else if (checkBin->key < key)
			(*dirFlag) = -1;
		else
			(*dirFlag) = 0;

		return checkPos;
	}

	void fillByBin(std::vector<size_t>* pos, float weight) {
		for (size_t i = 0; i < dimension; i++) {
			if ((*pos)[i] >= numBins[i])
				throwError("Tried to fill bin out of histogram range");
		}

		__int64 key = 0;
		__int64 mult = 1;
		for (size_t i = 0; i < dimension; i++) {
			key += (*pos)[i] * mult;
			mult *= numBins[i];
		}

		if (binIndices.size() == 0) {
			insertBin(pos, weight, key, 0);
		}
		else {
			int dirFlag = 0;
			size_t checkPos = getClosestBin(pos, &dirFlag);
			if (dirFlag == 0) {
				bins[binIndices[checkPos]].weight += weight;
			}
			else if (dirFlag == -1) {
				insertBin(pos, weight, key, checkPos + 1);
			}
			else {
				insertBin(pos, weight, key, checkPos);
			}
		}
		totalWeight += weight;
	}

	void fill(std::vector<float> vals, float weight) {
		std::vector<size_t> pos;
		if (vals.size() != dimension)
			throwError("Tried to fill histogram with val of invalid size");

		for (size_t i = 0; i < dimension; i++) {
			if (vals[i] < mins[i])
				pos.push_back(0);
			else if (vals[i] >= maxes[i])
				pos.push_back(numBins[i] - 1);
			else
				pos.push_back((size_t)(numBins[i] * (vals[i] - mins[i]) / (maxes[i] - mins[i])));
		}

		fillByBin(&pos, weight);
	}

	float getWeightOfBin(std::vector<size_t>* pos) {
		if (binIndices.size() == 0)
			return 0;
		int dirFlag = 0;
		size_t closePos = getClosestBin(pos, &dirFlag);
		if (dirFlag == 0)
			return bins[binIndices[closePos]].weight;
		else
			return 0;
	}

	SparseHistogramBin* getBinPointer(size_t bin) {
		return &bins[binIndices[bin]];
	}
};
