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

#define HEADER_SIZE 8
#define NUM_INPUTS 512
#define NUM_OUTPUTS 3

bool calculateAverage(std::string fname, float* average);
void saveMeanDiffs(std::string infname, std::string meanfname, std::string difffname, float mean);

int main() {
	std::string meanFolder;
	std::string diffFolder;
	std::cout << "Enter mean folder: ";
	std::cin >> meanFolder;
	std::cout << "Enter diff folder: ";
	std::cin >> diffFolder;

	std::ifstream filelist(datastring + (std::string)"filelist");
	std::ifstream indivlist(datastring + (std::string)"indivlist");

	std::vector<std::string> indivs;
	std::vector<float> indivAverages;
	std::vector<size_t> indivNumFiles;
	std::string line;
	while (std::getline(indivlist, line)) {
		indivs.push_back(line);
		indivAverages.push_back(0);
		indivNumFiles.push_back(0);
	}

	std::cout << "Computing individual averages: " << std::endl;
	while (std::getline(filelist, line)) {
		for (size_t i = 0; i < indivs.size(); i++) {
			if (line.substr(0, indivs[i].size()) == indivs[i]) {
				float average = 0;
				std::string fname;
				(std::stringstream(line) >> fname);
				if (!calculateAverage(fname, &average))
					break;
				indivAverages[i] += average;
				indivNumFiles[i]++;
				break;
			}
		}
	}

	for (size_t i = 0; i < indivs.size(); i++) {
		indivAverages[i] /= indivNumFiles[i];
		std::cout << indivs[i] << ": " << indivAverages[i] << " " << indivNumFiles[i] << std::endl;
	}

	std::cout << "Saving mean and differences: " << std::endl;
	filelist.clear();
	filelist.seekg(0, std::ios::beg);

	while (std::getline(filelist, line)) {
		for (size_t i = 0; i < indivs.size(); i++) {
			if (line.substr(0, indivs[i].size()) == indivs[i]) {
				std::string fname;
				(std::stringstream(line) >> fname);
				std::string localName = fname.substr(fname.find_last_of("\\/"), std::string::npos);
				saveMeanDiffs(fname, meanFolder + localName, diffFolder + localName, indivAverages[i]);
				break;
			}
		}
	}

	system("pause");
}

bool calculateAverage(std::string fname, float* average) {
	FILE* binfile = fopen(fname.c_str(), "rb");
	fseek(binfile, HEADER_SIZE, SEEK_SET);

	(*average) = 0;
	size_t numEvents = 0;
	std::vector<float> columns(NUM_INPUTS + NUM_OUTPUTS);
	while (fread(&columns[0], sizeof(float), NUM_INPUTS + NUM_OUTPUTS, binfile) == NUM_INPUTS + NUM_OUTPUTS) {
		(*average) += columns[0];
		numEvents++;
	}
	fclose(binfile);
	if (numEvents > 0)
		(*average) /= numEvents;
	return numEvents > 0;
}

void saveMeanDiffs(std::string infname, std::string meanfname, std::string difffname, float mean) {
	FILE* infile = fopen(infname.c_str(), "rb");
	FILE* meanfile = fopen(meanfname.c_str(), "wb");
	FILE* difffile = fopen(difffname.c_str(), "wb");
	char* header[HEADER_SIZE];
	fread(&header, HEADER_SIZE, 1, infile);
	fwrite(&header, HEADER_SIZE, 1, meanfile);
	fwrite(&header, HEADER_SIZE, 1, difffile);

	std::vector<float> columns(NUM_INPUTS + NUM_OUTPUTS);
	while (fread(&columns[0], sizeof(float), NUM_INPUTS + NUM_OUTPUTS, infile) == NUM_INPUTS + NUM_OUTPUTS) {
		columns[0] = columns[0] - mean;
		fwrite(&columns[0], sizeof(float), NUM_INPUTS + NUM_OUTPUTS, difffile);
		columns[0] = mean;
		fwrite(&columns[0], sizeof(float), NUM_INPUTS + NUM_OUTPUTS, meanfile);
	}

	fclose(infile);
	fclose(meanfile);
	fclose(difffile);
}