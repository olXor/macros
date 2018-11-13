#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>

#define datastring "D:/momMIMIC/weights/"

int main() {
	std::string infname;
	std::cout << "Enter input file name: ";
	std::cin >> infname;
	infname = datastring + infname;

	std::string outfname;
	std::cout << "Enter output file name: ";
	std::cin >> outfname;
	outfname = datastring + outfname;

	size_t intervalColumn;
	std::cout << "Enter column of interval identification: ";
	std::cin >> intervalColumn;

	size_t numLinesAveraged;
	std::cout << "Enter number of lines to average: ";
	std::cin >> numLinesAveraged;

	std::vector<std::vector<float>> lines;
	std::string line;
	std::ifstream infile(infname);
	std::ofstream outfile(outfname);
	std::string lastInterval = "";

	size_t numLines = 0;
	while (std::getline(infile, line)) {
		std::stringstream lss(line);
		size_t col = 0;
		std::string dum;
		std::vector<float> columns;
		while (lss >> dum) {
			col++;
			if (col == intervalColumn) {
				if (dum != lastInterval) {
					lines.clear();
					numLines = 0;
					lastInterval = dum;
				}
			}
			float val;
			std::stringstream(dum) >> val;
			columns.push_back(val);
		}
		lines.push_back(columns);
		numLines++;

		if (numLines == numLinesAveraged) {
			for (size_t i = 0; i < lines[0].size(); i++) {
				float avg = 0;
				for (size_t j = 0; j < lines.size(); j++) {
					avg += lines[j][i];
				}
				avg /= lines.size();
				outfile << avg << " ";
			}
			outfile << std::endl;

			lines.clear();
			numLines = 0;
		}
	}
}
