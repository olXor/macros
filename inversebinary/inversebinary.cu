#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>

#define datastring ""
//#define datastring "D:/trivialNetworkTest/sethsensor/"

#define NUM_INPUTS 512
#define NUM_OUTPUTS 2//5
#define NUM_SILENT_OUTPUTS 0//12
#define HEADER_SIZE 8

int main() {
	std::string filefname;
	std::cout << "Enter file list: ";
	std::cin >> filefname;

	std::ifstream filelist((std::string)datastring + filefname);
	std::string line;
	while (std::getline(filelist, line)) {
		std::string fname;
		std::stringstream(line) >> fname;
		FILE* infile = fopen(fname.c_str(), "rb");
		FILE* outfile = fopen(("inv_" + fname).c_str(), "wb");

		char* buffer[HEADER_SIZE];
		fread(&buffer, HEADER_SIZE, 1, infile);
		fwrite(&buffer, HEADER_SIZE, 1, outfile);

		size_t numColumns = NUM_INPUTS + NUM_OUTPUTS + NUM_SILENT_OUTPUTS;
		std::vector<float> columns(numColumns);
		while (fread(&columns[0], sizeof(float), numColumns, infile) == numColumns) {
			fwrite(&columns[0], sizeof(float), numColumns, outfile);
			//flip outputs but not silent outputs
			for (size_t c = 0; c < NUM_OUTPUTS; c++)
				columns[c] = -columns[c];
			for (size_t c = NUM_OUTPUTS + NUM_SILENT_OUTPUTS; c < numColumns; c++)
				columns[c] = -columns[c];
			fwrite(&columns[0], sizeof(float), numColumns, outfile);
		}
	}
}
