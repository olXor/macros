#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>
#include <cstdio>
#include <list>

//#define datastring "D:/momMIMIC/rawdata/"
#define datastring "rawdata/"

struct AggregateInfo {
	size_t windowSize;
	size_t numWindows;	//number of windows to average
	size_t headerSize;	//in bytes
	size_t numPreVariables;
};

void writeAggregateInterval(FILE* infile, FILE* outfile, AggregateInfo info);

//converts a series of .bin files to .bin files with averaged pulses (and stdevs)
int main() {
	std::string trainfname;
	std::cout << "Enter trainset name: ";
	std::cin >> trainfname;
	trainfname = datastring + trainfname;
	
	std::string outprefix;
	std::cout << "Enter output prefix: ";
	std::cin >> outprefix;

	AggregateInfo info;

	std::cout << "Enter window size: ";
	std::cin >> info.windowSize;

	std::cout << "Enter number of windows to average: ";
	std::cin >> info.numWindows;

	std::cout << "Enter number of additional input/output variables per window: ";
	std::cin >> info.numPreVariables;

	std::cout << "Enter size of header (in bytes): ";
	std::cin >> info.headerSize;

	std::ifstream trainfile(trainfname);
	std::string line;
	while (std::getline(trainfile, line)) {
		std::stringstream lss(line);
		std::string fname;
		lss >> fname;
		std::cout << "Processing file " << fname << std::endl;
		FILE* binfile = fopen((datastring + fname).c_str(), "rb");
		FILE* outbinfile = fopen((datastring + outprefix + fname).c_str(), "wb");

		writeAggregateInterval(binfile, outbinfile, info);
		fclose(binfile);
		fclose(outbinfile);
	}

	system("pause");
}

void writeAggregateInterval(FILE* infile, FILE* outfile, AggregateInfo info) {
	fseek(infile, info.headerSize, SEEK_SET);

	size_t numColumns = info.numPreVariables + info.windowSize;
	std::vector<float> columns(numColumns);
	std::vector<std::vector<float>> aggColumns(info.numWindows);
	size_t curWindow = 0;
	
	std::vector<float> windowAverages(info.windowSize);
	std::vector<float> windowStdevs(info.windowSize);

	while (fread(&columns[0], sizeof(float), columns.size(), infile) == columns.size()) {
		aggColumns[curWindow] = columns;
		curWindow++;
		
		if (curWindow >= aggColumns.size()) {
			for (size_t i = 0; i < info.numPreVariables; i++) {
				float avg = 0;
				for (size_t j = 0; j < info.numWindows; j++) {
					avg += aggColumns[j][i];
				}
				avg /= info.numWindows;
				fwrite(&avg, sizeof(float), 1, outfile);
			}

			float maxAvg = -9999;
			float minAvg = 9999;
			for (size_t i = 0; i < info.windowSize; i++) {
				float avg = 0;
				float stdev = 0;
				for (size_t j = 0; j < info.numWindows; j++) {
					float val = aggColumns[j][i + info.numPreVariables];
					avg += val;
					stdev += val*val;
				}
				avg /= info.numWindows;
				stdev /= info.numWindows;
				stdev -= avg*avg;

				stdev = sqrt((stdev > 0 ? stdev : 0));

				windowAverages[i] = avg;
				windowStdevs[i] = stdev;
				maxAvg = std::max(avg, maxAvg);
				minAvg = std::min(avg, minAvg);
			}
			for (size_t i = 0; i < info.windowSize; i++) {
				if (maxAvg > minAvg) {
					windowAverages[i] = 2.0f * (windowAverages[i] - minAvg) / (maxAvg - minAvg) - 1.0f;
					windowStdevs[i] /= ((maxAvg - minAvg) / 2.0f);
				}
				else {
					windowAverages[i] = 0;
					windowStdevs[i] = 0;
				}
				fwrite(&windowAverages[i], sizeof(float), 1, outfile);
				fwrite(&windowStdevs[i], sizeof(float), 1, outfile);
			}

			curWindow = 0;
		}
	}
}
