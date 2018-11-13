#include <iostream>
#include <string>
#include <sstream>
#include <fstream>
#include <vector>
#define _USE_MATH_DEFINES
#include <math.h>
#include <time.h>

#define imagestring "D:/stopsearch/"
#define datastring "D:/stopsearch/data/"
#define dataname "toydata_hawaii"
#define imagename "hawaiiconv"

#define NUM_EVENTS 1e6
#define NUM_VARS 2


void throwError(std::string err) {
	std::cout << err << std::endl;
	system("pause");
	throw std::runtime_error(err);
}

bool evaluateEvent(std::vector<float>* inputs, std::vector<std::vector<float>>* goalimage) {
	if (inputs->size() != NUM_VARS)
		throwError("Invalid input size");

	size_t bin0 = (size_t)((*inputs)[0] * goalimage->size());
	size_t bin1 = (size_t)((*inputs)[1] * (*goalimage)[bin0].size());
		
	return (*goalimage)[bin0][bin1] > 0;
}

int main() {
	srand((size_t)time(NULL));
	std::stringstream outss;
	outss << datastring << dataname;
	std::ofstream signalfile(outss.str() + "_signal");
	std::ofstream backgroundfile(outss.str() + "_background");

	std::stringstream imagess;
	imagess << imagestring << imagename;
	std::ifstream imagestream(imagess.str());

	std::string line;
	std::vector<std::vector<float>> goalimage;
	while (std::getline(imagestream, line)) {
		std::vector<float> iline;
		std::stringstream lss(line);
		float val;
		while (lss >> val) {
			iline.push_back(val);
		}
		goalimage.push_back(iline);
	}

	for (size_t i = 0; i < NUM_EVENTS; i++) {
		std::vector<float> inputs(NUM_VARS);
		for (size_t j = 0; j < NUM_VARS; j++) {
			inputs[j] = 1.0f*(rand() % 10000) / 10000;
		}

		std::ofstream* outfile = (evaluateEvent(&inputs, &goalimage) ? &signalfile : &backgroundfile);
		for (size_t j = 0; j < inputs.size(); j++) {
			(*outfile) << inputs[j] << " ";
		}
		(*outfile) << std::endl;
	}
}