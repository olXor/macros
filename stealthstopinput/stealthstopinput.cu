#include <iostream>
#include <string>
#include <sstream>
#include <fstream>
#include <vector>
#define _USE_MATH_DEFINES
#include <math.h>
#include "permutations.cuh"

#define NUM_OUTPUTS 2
#define NUM_PARTICLES 12
#define NUM_INPUTS (NUM_PARTICLES*3)
#define NUM_LEPTONS 2
#define NUM_JETS 10
#define NUM_JETS_CONV 4
#define datastring "D:/stealthstop/data/"

std::vector<float> convertFeatures(std::vector<float> inputs);
std::vector<float> convertConvolutionFeatures(std::vector<float> inputs);

int main() {
	std::string infname;
	std::string outfname;
	bool convertInputs = false;
	bool convolveInputs = false;
	std::cout << "Enter input file name: ";
	std::cin >> infname;
	std::cout << "Enter output file name: ";
	std::cin >> outfname;
	std::cout << "Convert inputs? ";
	std::cin >> convertInputs;
	if (convertInputs) {
		std::cout << "Convolve particles? ";
		std::cin >> convolveInputs;
	}

	std::ifstream infile(datastring + infname);
	std::ofstream totaloutfile(datastring + outfname);

	if (!infile.is_open()) {
		std::cout << "Couldn't find input file." << std::endl;
		system("pause");
		return 0;
	}

	std::string line;

	while (std::getline(infile, line)) {
		std::string tok;
		std::stringstream lss(line);

		std::vector<float> outputs(NUM_OUTPUTS);
		std::vector<float> features(NUM_INPUTS);
		for (size_t i = 0; i < NUM_OUTPUTS; i++) {
			lss >> outputs[i];
		}
		for (size_t i = 0; i < NUM_INPUTS; i++) {
			lss >> features[i];
		}

		if (convertInputs) {
			if (convolveInputs)
				features = convertConvolutionFeatures(features);
			else
				features = convertFeatures(features);
		}

		for (size_t i = 0; i < outputs.size(); i++)
			totaloutfile << outputs[i] << " ";
		for (size_t i = 0; i < features.size(); i++) {
			totaloutfile << features[i] << " ";
		}
		totaloutfile << std::endl;
	}
}

std::vector<float> convertFeatures(std::vector<float> inputs) {
	std::vector<float> convFeatures(2*NUM_PARTICLES + (NUM_PARTICLES*(NUM_PARTICLES-1)/2));

	for (size_t i = 0; i < NUM_PARTICLES; i++) {
		if (inputs[3 * i] != 0)
			convFeatures[2 * i] = std::log(inputs[3 * i]);	//pt
		else
			convFeatures[2 * i] = 0;
		convFeatures[2 * i + 1] = inputs[3 * i + 2];	//eta
	}

	//all phi combinations
	size_t combNum = 0;
	for (size_t i = 0; i < NUM_PARTICLES; i++) {
		for (size_t j = i + 1; j < NUM_PARTICLES; j++) {
			float firstPhi = inputs[3 * i + 1];
			float secondPhi = inputs[3 * j + 1];
			float convPhi = fabs(firstPhi - secondPhi);
			if (convPhi > M_PI)
				convPhi = 2 * M_PI - convPhi;
			if (firstPhi == 0 || secondPhi == 0)
				convPhi = 0;
			convFeatures[2 * NUM_PARTICLES + combNum] = convPhi;
			combNum++;
		}
	}

	return convFeatures;
}

std::vector<float> convertConvolutionFeatures(std::vector<float> inputs) {
	std::vector<float> convFeatures;

	PermutationArray permLepton = createPermutation(2);
	PermutationArray permJets;

	do { 
		permJets = createPermutation(4);
		do {
			for (size_t l = 0; l < permLepton.indices.size(); l++) {
				size_t lepNum = permLepton.indices[l];
				float pt = inputs[3 * l];
				if (pt == 0)
					convFeatures.push_back(0);
				else
					convFeatures.push_back(std::log(pt));
				convFeatures.push_back(inputs[3 * l + 1]);
				convFeatures.push_back(inputs[3 * l + 2]);
			}
			for (size_t j = 0; j < permJets.indices.size(); j++) {
				size_t jetNum = permJets.indices[j];
				float pt = inputs[3 * (NUM_LEPTONS + j)];
				if (pt == 0)
					convFeatures.push_back(0);
				else
					convFeatures.push_back(std::log(pt));
				convFeatures.push_back(inputs[3 * (NUM_LEPTONS + j) + 1]);
				convFeatures.push_back(inputs[3 * (NUM_LEPTONS + j) + 2]);
			}
		} while (iteratePermutation(&permJets));
	} while (iteratePermutation(&permLepton));

	return convFeatures;
}
