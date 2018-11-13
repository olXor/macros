#include <iostream>
#include <string>
#include <sstream>
#include <fstream>
#include <vector>
#define _USE_MATH_DEFINES
#include <math.h>
#include "clusterdistStructDef.cuh"

#define datafname "D:/stopSearch/weights/deep_350-200_FixPhiWBMatchedNoMETEtaBTag_L1_2e-5/actMaxL5N10_45/raw_output"
#define outfolder "D:/stopSearch/weights/deep_350-200_FixPhiWBMatchedNoMETEtaBTag_L1_2e-5/actMaxClusterL5N10_45_lowpt/"

float displayCorrelationHistogram(Histogram2D hist, std::ofstream* resfile);

bool includeEvent(std::vector<float>* inputs) {
	//return (*inputs)[0] > 3	&& (*inputs)[0] < 5 && (*inputs)[1] > 3.2 && (*inputs)[1] < 4 && (*inputs)[5] > 3.2 && (*inputs)[5] < 4;
	return (*inputs)[11] > 1.5 && (*inputs)[11] < 2 && (*inputs)[13] > 0.25 && (*inputs)[13] < 0.75;
}

int main() {
	std::ifstream datafile(datafname);
	size_t numInputs;
	std::string line;
	std::vector<std::vector<float>> rawinputs;
	std::vector<float> eventInputs;

	while (std::getline(datafile, line)) {
		eventInputs.clear();
		float val;
		std::stringstream lss(line);
		lss >> val;	//first input assumed to be neuron output
		while (lss >> val)
			eventInputs.push_back(val);
		rawinputs.push_back(eventInputs);
	}

	std::vector<float> mins(rawinputs[0].size());
	std::vector<float> maxes(rawinputs[0].size());
	for (size_t i = 0; i < mins.size(); i++) {
		mins[i] = 99999;
		maxes[i] = -99999;
	}

	for (size_t i = 0; i < rawinputs.size(); i++) {
		for (size_t j = 0; j < rawinputs[i].size(); j++) {
			mins[j] = std::min(mins[j], rawinputs[i][j]);
			maxes[j] = std::max(maxes[j], rawinputs[i][j]);
		}
	}

	std::vector<Histogram2D> hists;
	size_t numBins = 40;
	for (size_t i = 0; i < mins.size(); i++) {
		for (size_t j = i + 1; j < mins.size(); j++) {
			Histogram2D hist;
			hist.initHistogram(mins[i], maxes[i], mins[j], maxes[j], numBins, numBins);
			hists.push_back(hist);
		}
	}
			
	for (size_t i = 0; i < rawinputs.size(); i++) {
		if (!includeEvent(&rawinputs[i]))
			continue;

		size_t histNum = 0;
		for (size_t in1 = 0; in1 < rawinputs[i].size(); in1++) {
			for (size_t in2 = in1 + 1; in2 < rawinputs[i].size(); in2++) {
				hists[histNum].fill(rawinputs[i][in1], rawinputs[i][in2], 1.0f);
				histNum++;
			}
		}
	}

	size_t displayHistNum = 0;
	for (size_t i = 0; i < mins.size(); i++) {
		for (size_t j = i + 1; j < mins.size(); j++) {
			std::stringstream outss;
			outss << outfolder << "disp" << i << "-" << j << "_1";
			std::ofstream outfile(outss.str());
			displayCorrelationHistogram(hists[displayHistNum], &outfile);
			displayHistNum++;
		}
	}
}

float displayCorrelationHistogram(Histogram2D hist, std::ofstream* resfile) {
	float mutInt = 0;
	(*resfile) << "# " << hist.min1 << " " << hist.max1 << " " << hist.min2 << " " << hist.max2 << " " << mutInt << " " << hist.numBins1 << " " << hist.numBins2 << std::endl;
	for (size_t i = 0; i < hist.numBins1; i++) {
		for (size_t j = 0; j < hist.numBins2; j++) {
			size_t pos = i + j*hist.numBins1;
			(*resfile) << hist.bins[pos] << " ";
		}
		(*resfile) << std::endl;
	}
	return mutInt;
}
