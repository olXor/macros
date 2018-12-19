#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>

#define datastring ""
//#define datastring "D:/trivialNetworkTest/meetpacker/"

#define HEADER_SIZE 4 

#define NUM_INPUTS 512
#define NUM_OUTPUTS 16
#define NUM_PEAKLOCS 30	//same as valleys
#define NUM_FEATURES 591

void meetPackerConvertFiles(FILE* oldfile, FILE* newfile);

int main() {
	std::string filelist = "meetfilelist";
	std::ifstream meetfile(datastring + filelist);
	if (!meetfile.is_open()) {
		std::cout << "Couldn't open file list " << datastring << filelist << std::endl;
		system("pause");
		return;
	}

	std::string meetline;
	while (std::getline(meetfile, meetline)) {
		std::stringstream lss(meetline);
		std::string oldfname, newfname;
		lss >> oldfname >> newfname;

		FILE* oldfile = fopen((datastring + oldfname).c_str(), "rb");
		FILE* newfile = fopen((datastring + newfname).c_str(), "wb");

		meetPackerConvertFiles(oldfile, newfile);
		fclose(oldfile);
		fclose(newfile);
	}
}

void meetPackerConvertFiles(FILE* oldfile, FILE* newfile) {
	fseek(oldfile, HEADER_SIZE, SEEK_SET);
	fseek(newfile, 0, SEEK_SET);

	size_t dum = 0;
	fwrite(&dum, sizeof(size_t), 1, newfile);
	fwrite(&dum, sizeof(size_t), 1, newfile);	//dummy header

	int numColumns;
	fread(&numColumns, sizeof(int), 1, oldfile);

	if (numColumns != NUM_OUTPUTS + NUM_INPUTS + 2 * NUM_PEAKLOCS + NUM_FEATURES + 1) {
		std::cout << "Invalid number of columns in at least one file: expected " << NUM_OUTPUTS + NUM_INPUTS + 2 * NUM_PEAKLOCS + NUM_FEATURES + 1 << " got " << numColumns << std::endl;
		system("pause");
		return;
	}

	std::vector<float> columns(numColumns);

	while (fread(&columns[0], sizeof(float), numColumns, oldfile) == numColumns) {
		fwrite(&columns[0], sizeof(float), 1 + NUM_OUTPUTS + NUM_INPUTS, newfile);
		std::vector<float> peaks(NUM_INPUTS);
		for (size_t i = 0; i < NUM_PEAKLOCS; i++) {
			float peakLoc = columns[1 + NUM_OUTPUTS + NUM_INPUTS + i];
			if (peakLoc == peakLoc)
				peaks[(size_t)peakLoc] = 1;
			float valleyLoc = columns[1 + NUM_OUTPUTS + NUM_INPUTS + NUM_PEAKLOCS + i];
			if (valleyLoc == valleyLoc)
				peaks[(size_t)valleyLoc] = -1;
		}

		fwrite(&peaks[0], sizeof(float), NUM_INPUTS, newfile);
	}
}