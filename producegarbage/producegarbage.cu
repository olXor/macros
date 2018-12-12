#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>
#include <random>

#define datastring ""
//#define datastring "D:/trivialNetworkTest/sethsensor/"

#define NUM_INPUTS 512
#define NUM_OUTPUTS 3
#define HEADER_SIZE 8

int main() {
	srand((size_t)time(NULL));

	size_t numFiles = 1;
	std::cout << "Enter number of garbage files to produce: ";
	std::cin >> numFiles;

	size_t numEvents = 2000;
	std::cout << "Enter number of garbage events in each file: ";
	std::cin >> numEvents;

	std::string outfname;
	std::cout << "Enter name of garbage files: ";
	std::cin >> outfname;

	float minOutput = 0;
	float maxOutput = 100;
	std::cout << "Enter minimum output: ";
	std::cin >> minOutput;
	std::cout << "Enter maximum output: ";
	std::cin >> maxOutput;

	std::random_device rd;

	std::mt19937 e2(rd());

	std::normal_distribution<> dist(0, 1);

	for (size_t f = 1; f <= numFiles; f++) {
		std::stringstream outss;
		outss << outfname << "_" << f;
		FILE* outfile = fopen(outss.str().c_str(), "wb");
		char* header[HEADER_SIZE];
		memset(header, 0, HEADER_SIZE);

		fwrite(header, HEADER_SIZE, 1, outfile);

		for (size_t i = 0; i < numEvents; i++) {
			float val = (1.0f*(rand() % 100) / 100.0f)*(maxOutput - minOutput) + minOutput;
			fwrite(&val, sizeof(float), 1, outfile);
			val = 0;
			for (size_t o = 1; o < NUM_OUTPUTS; o++)
				fwrite(&val, sizeof(float), 1, outfile);

			for (size_t in = 0; in < NUM_INPUTS; in++) {
				val = dist(e2);
				fwrite(&val, sizeof(float), 1, outfile);
			}
		}
		fclose(outfile);
	}

	system("pause");
}