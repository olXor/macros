#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>
#include <list>

#define datastring ""
//#define datastring "D:/trivialNetworkTest/sethsensor/"

#define SAVE_PERIOD 10

struct SensorConvDatasetInfo {
	std::ifstream* datafile;
	size_t windowSize;
#ifndef SAVE_PERIOD
	size_t firstQualityColumn;
	float qualityThresh;
#endif
	size_t firstDataColumn;
	size_t lastDataColumn;
	std::string outputName;
	size_t outNum = 0;
};

struct IntervalData {
	std::string fname;
	size_t startIndex;
	size_t endIndex;
	float output;
	SensorConvDatasetInfo* info;
};

void convertInterval(IntervalData* intData);
void convertTrainset(SensorConvDatasetInfo* info);

int main() {
	SensorConvDatasetInfo dataInfo;

	std::string datafname;
	std::cout << "Enter data file: ";
	std::cin >> datafname;

	std::ifstream datafile(datastring + datafname);
	if (!datafile.is_open()) {
		std::cout << "Can't find datafile" << std::endl;
		system("pause");
		return 0;
	}
	dataInfo.datafile = &datafile;

	std::cout << "Enter window size: ";
	std::cin >> dataInfo.windowSize;

	std::cout << "Enter first data column (starting at 0): ";
	std::cin >> dataInfo.firstDataColumn;
	
	std::cout << "Enter last data column: ";
	std::cin >> dataInfo.lastDataColumn;

#ifndef SAVE_PERIOD
	std::cout << "Enter quality threshold: ";
	std::cin >> dataInfo.qualityThresh;

	std::cout << "Enter first quality column: ";
	std::cin >> dataInfo.firstQualityColumn;
#endif

	std::cout << "Enter output file name: ";
	std::cin >> dataInfo.outputName;

	convertTrainset(&dataInfo);

	system("pause");
}

void convertTrainset(SensorConvDatasetInfo* info) {
	std::string line;

	while (std::getline((*info->datafile), line)) {
		IntervalData intData;
		(std::stringstream(line)) >> intData.fname >> intData.startIndex >> intData.endIndex >> intData.output;
		intData.info = info;

		std::cout << "Reading interval: " << intData.fname << " " << intData.startIndex << " " << intData.endIndex << " " << intData.output << std::endl;
		info->outNum++;

		convertInterval(&intData);
	}
}

void convertInterval(IntervalData* intData) {
	std::ifstream infile(datastring + intData->fname);
	if (!infile.is_open()) {
		std::cout << "Couldn't open file " << datastring + intData->fname << std::endl;
		return;
	}
	std::stringstream outss;
	outss << datastring << intData->info->outputName << "_" << intData->info->outNum;
	FILE* outfile = fopen(outss.str().c_str(), "wb");
	float header = 0;
	fwrite(&header, sizeof(float), 1, outfile);
	fwrite(&header, sizeof(float), 1, outfile);

	std::string line;
	for (size_t i = 0; i < intData->startIndex; i++) {
		if (infile.ignore(10000, infile.widen('\n'))){
			//just skipping the line
		}
		else {
			std::cout << "Some sort of error skipping initial lines of file " << std::endl;
			system("pause");
		}
	}

	std::vector<std::list<long long>> data;
	data.resize(intData->info->lastDataColumn - intData->info->firstDataColumn + 1);
	std::vector<float> quality;
	quality.resize(data.size());

	for (size_t i = intData->startIndex; i < intData->endIndex; i++) {
		std::getline(infile, line);
		std::stringstream lss(line);

		std::string dum;
		quality.clear();
		for (size_t c = 0; std::getline(lss, dum, ','); c++) {
			if (c >= intData->info->firstDataColumn && c <= intData->info->lastDataColumn) {
				long long val;
				(std::stringstream(dum)) >> val;
				size_t colNum = c - intData->info->firstDataColumn;
				data[colNum].push_back(val);
				if (data[colNum].size() > intData->info->windowSize)
					data[colNum].pop_front();
			}
#ifndef SAVE_PERIOD
			else if (c >= intData->info->firstQualityColumn) {
				float val;
				(std::stringstream(dum)) >> val;
				if (c - intData->info->firstQualityColumn < data.size())
					quality.push_back(val);
			}
#endif
		}

#ifndef SAVE_PERIOD
		for (size_t q = 0; q < quality.size(); q++) {
			if (fabs(quality[q]) >= intData->info->qualityThresh && data[q].size() == intData->info->windowSize) {
#else
		for (size_t q = 0; q < data.size(); q++) {
			if ((i - intData->startIndex) % SAVE_PERIOD == 0 && data[q].size() == intData->info->windowSize) {
#endif
				for (size_t invert = 0; invert < 2; invert++) {
					std::vector<float> inputs;
					long long initVal = (invert == 0 ? data[q].front() : -data[q].front());
					long long maxVal = initVal;
					long long minVal = initVal;
					for (std::list<long long>::iterator it = data[q].begin(); it != data[q].end(); it++) {
						long long val;
						if (invert == 0)
							val = (*it);
						else
							val = -(*it);
						maxVal = std::max(maxVal, val);
						minVal = std::min(minVal, val);
					}

					for (std::list<long long>::iterator it = data[q].begin(); it != data[q].end(); it++) {
						long long val;
						if (invert == 0)
							val = (*it);
						else
							val = -(*it);

						long long valDiff = val - minVal;
						long long maxDiff = maxVal - minVal;

						if (maxDiff > 0)
							inputs.push_back(2.0f*valDiff / maxDiff - 1.0f);
						else
							inputs.push_back(0.0f);
					}

					fwrite(&intData->output, sizeof(float), 1, outfile);
#ifndef SAVE_PERIOD
					fwrite(&quality[q], sizeof(float), 1, outfile);
#else
					float dum = 0;
					fwrite(&dum, sizeof(float), 1, outfile);
#endif
					if (inputs.size() != intData->info->windowSize)
						std::cout << "Invalid size window!" << std::endl;
					else
						fwrite(&inputs[0], sizeof(float), inputs.size(), outfile);
				}
			}
		}
	}
}
