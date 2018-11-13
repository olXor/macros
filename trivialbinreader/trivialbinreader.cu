#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>

#define datastring ""
//#define datastring "D:/trivialNetworkTest/testdata/"

#define NUM_PREFLAGS 5
#define NUM_INPUTS 512

int main() {
	std::string datafname;
	std::cout << "Enter name of dataset to read; ";
	std::cin >> datafname;

	size_t startSample = 0;
	std::cout << "Enter sample to start at: ";
	std::cin >> startSample;

	FILE* datafile = fopen((datastring + datafname).c_str(), "rb");
	
	//1 size_t header
	_int64 startLoc = sizeof(size_t) + startSample*(NUM_PREFLAGS + NUM_INPUTS)*sizeof(float);
	_fseeki64(datafile, startLoc, SEEK_SET);

	std::vector<float> sample(NUM_PREFLAGS + NUM_INPUTS);
	while (true) {
		fread(&sample[0], (NUM_PREFLAGS + NUM_INPUTS)*sizeof(float), 1, datafile);
		for (size_t i = 0; i < NUM_PREFLAGS; i++)
			std::cout << sample[i] << " ";
		std::cout << std::endl;
		for (size_t i = 0; i < NUM_INPUTS; i++)
			std::cout << sample[i + NUM_PREFLAGS] << " ";
		std::cout << std::endl;
		system("pause");
	}
}
