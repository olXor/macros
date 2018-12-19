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

#define COMMA_DELIMITER

#define DATA_EPOCHTIME_DIVISOR 1000
#define INTERVAL_SIZE 6900

int main() {
	std::string datafname;
	std::cout << "Enter data file: ";
	std::cin >> datafname;

	std::string dataoutfname;
	std::cout << "Enter new data file: ";
	std::cin >> dataoutfname;

	std::ifstream datafile(datastring + datafname);
	if (!datafile.is_open()) {
		std::cout << "Can't find datafile" << std::endl;
		system("pause");
		return 0;
	}

	std::ofstream outfile(datastring + dataoutfname);

	std::string line;
	while (std::getline(datafile, line)) {
		long long epochTime;
		std::string fname;
		float output;
		(std::stringstream(line)) >> epochTime >> fname >> output;
		std::cout << "Starting: " << epochTime << " " << fname << " " << output << std::endl;

		std::ifstream infile(datastring + fname);
		std::string inLine;
		bool preData = false;
		size_t lineNum = 1;
		bool foundInterval = false;
		size_t intervalStart = 0;
		size_t intervalEnd = 0;
		std::getline(infile, inLine);	//header
		while (std::getline(infile, inLine)) {
			std::string tok;
			lineNum++;
#ifdef COMMA_DELIMITER
			std::getline((std::stringstream(inLine)), tok, ',');
#else
			(std::stringstream(inLine)) >> tok;
#endif
			long long lineEpochTime;
			(std::stringstream(tok)) >> lineEpochTime;
			lineEpochTime /= DATA_EPOCHTIME_DIVISOR;

			if (lineEpochTime < epochTime && !preData)
				preData = true;
			else if (((lineEpochTime > epochTime && preData) || (lineEpochTime == epochTime)) && !foundInterval) {
				foundInterval = true;
				intervalStart = lineNum;
				intervalEnd = lineNum;
			}
			else if (foundInterval) {
				intervalEnd++;
				if (intervalEnd >= intervalStart + INTERVAL_SIZE)
					break;
			}
			else if (lineEpochTime > epochTime && !preData) {
				break;
			}
		}
		if (foundInterval) {
			outfile << fname << " " << intervalStart << " " << intervalEnd << " " << output << std::endl;
			std::cout << fname << " " << intervalStart << " " << intervalEnd << " " << output << std::endl;
		}
		else if (!preData)
			std::cout << "File starts after interval" << std::endl;
		else
			std::cout << "File ends before interval" << std::endl;
	}

	system("pause");
}