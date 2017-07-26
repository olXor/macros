#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>

int convertTime(std::string str);
std::string timeToStr(int time);

int main() {
	std::string artfname;
	std::string sensefname;
	std::string outfname;
	int offset = 0;
	std::vector<size_t> intCols;
	std::vector<std::string> batchInfo;
	size_t artColumn = 1;
	bool batchInput = false;
	std::string batchfname;
	std::ifstream batchfile;
	std::string batchline;
	std::ofstream intfile;

	std::cout << "Enter batch filename (blank allows manual input): ";
	std::getline(std::cin, batchfname);
	if (batchfname != "") batchInput = true;
	std::cout << std::endl;

	if (!batchInput) {
		std::cout << "Enter art-line file name: ";
		std::getline(std::cin, artfname);
		std::cout << std::endl;

		std::cout << "Enter sensor file name: ";
		std::getline(std::cin, sensefname);
		std::cout << std::endl;

		std::cout << "Enter output file name: ";
		std::getline(std::cin, outfname);
		std::cout << std::endl;

		std::cout << "Enter sensor columns to put in interval file: ";
		std::string colstr;
		std::getline(std::cin, colstr);
		std::cout << std::endl;

		if (colstr != "") {
			intCols.clear();
			std::stringstream colss(colstr);
			size_t col;
			while (colss >> col) {
				intCols.push_back(col);
			}
		}

		std::cout << "Enter art-line column to use in interval file: ";
		std::cin >> artColumn;
		std::cout << std::endl;

		std::cout << "Enter offset (artline - sensor times in seconds): ";
		std::cin >> offset;
		std::cout << std::endl;
	}
	else {
		batchfile.open(batchfname);
		std::getline(batchfile, batchline);
		std::stringstream intss;
		intss << "int_" << batchfname;
		intfile.open(intss.str());
	}

	size_t numFiles = 0;
	do {
		numFiles++;
		std::cout << "Starting file #" << numFiles << std::endl;
		if (batchInput) {
			std::stringstream batchss;
			batchss << batchline;
			batchss >> artfname >> sensefname >> outfname >> offset >> artColumn;
			size_t scol;
			intCols.clear();
			for (size_t i = 0; i<4 && (batchss >> scol); i++) 
				intCols.push_back(scol);
			std::string bInfo;
			batchInfo.clear();
			while (batchss >> bInfo)
				batchInfo.push_back(bInfo);
		}
		std::ifstream artfile(artfname);
		std::ifstream sensefile(sensefname);
		std::ofstream outfile(outfname);

		if (!batchInput) {
			std::stringstream intss;
			intss << "int_" << outfname;
			intfile.open(intss.str());
		}

		std::string dum;
		getline(artfile, dum);	//remove header
		std::string artline;
		if (!getline(artfile, artline)) {
			std::cout << "Artfile empty" << std::endl;
			return 0;
		}

		size_t slinenum = 0;
		size_t curIntStart = 1;
		bool intOpen = false;
		std::string senseline;
		float artRes = 0;
		std::vector<std::string> artcols;
		size_t numLinesOutput = 0;
		size_t outfileNumber = 1;
		size_t numUnmatchedLines = 0;
		while (getline(sensefile, senseline)) {
			slinenum++;
			std::stringstream senselss;
			senselss << senseline;
			std::vector<std::string> sensecolumns;
			while (senselss >> dum)
				sensecolumns.push_back(dum);
			int sensetime = convertTime(sensecolumns.back()) + offset;

			bool foundArtLine = false;
			do  {
				std::stringstream artss;
				artss << artline;
				std::string arttimestr;
				getline(artss, arttimestr, ',');
				int arttime = convertTime(arttimestr);

				if (abs(arttime - sensetime) <= 30) {
					std::string column;
					artcols.clear();
					size_t col = 1;
					while (getline(artss, column, ',')) {
						col++;
						artcols.push_back(column);
						if (col == artColumn) {
							std::stringstream colss;
							colss << column;
							colss >> artRes;
						}
					}
					outfile << artRes;
					for (size_t i = 0; i < sensecolumns.size(); i++) {
						bool colSelected = false;
						if (i >= sensecolumns.size() - 2)
							colSelected = true;
						else {
							for (size_t j = 0; j < intCols.size(); j++) {
								if (intCols[j] == i + 1) {
									colSelected = true;
									break;
								}
							}
						}
						if (colSelected)
							outfile << "," << sensecolumns[i];
					}
					for (size_t i = 0; i < batchInfo.size(); i++) {
						outfile << "," << batchInfo[i];
					}
					for (size_t i = 0; i < artcols.size(); i++) {
						outfile << "," << artcols[i];
					}
					outfile << std::endl;
					numLinesOutput++;
					if (numLinesOutput >= 1000000) {
						numLinesOutput = 0;
						outfileNumber++;
						std::stringstream outnewss;
						outnewss << outfname << "-" << outfileNumber;
						outfile.close();
						outfile.open(outnewss.str());
					}
					foundArtLine = true;
					if (!intOpen) {
						curIntStart = slinenum;
						intOpen = true;
					}
					break;
				}
				else if (arttime - sensetime > 30) {
					//std::cout << "Failed to find art-line match for sensor data at " << timeToStr(sensetime) << std::endl;
					foundArtLine = true;
					break;
				}
				if (intOpen) {
					for (size_t i = 0; i < intCols.size(); i++) {
						intfile << sensefname << " " << intCols[i] << " " << curIntStart << " " << slinenum - 1 << " " << artRes << " ";
						for (size_t i = 0; i < batchInfo.size(); i++) {
							intfile << batchInfo[i] << " ";
						}
						for (size_t i = 0; i < artcols.size(); i++) {
							if (artcols[i] == "")
								intfile << 0;
							intfile << artcols[i] << " ";
						}
						intfile << std::endl;
					}
					intOpen = false;
				}
				artRes = 0;
			} while (getline(artfile, artline));

			if (foundArtLine == false) {
				numUnmatchedLines++;
				if (numUnmatchedLines >= 5) {
					//std::cout << "Artline ended without match for " << timeToStr(sensetime) << std::endl;
					break;
				}
				artfile.clear();
				artfile.seekg(0, std::ios::beg);
			}
			else
				numUnmatchedLines = 0;
		}
	} while (batchInput && std::getline(batchfile, batchline));

	system("pause");
}

int convertTime(std::string str) {
	int hour = 0;
	int minute = 0;
	int second = 0;
	char dum;
	std::string pm;

	std::stringstream strs;
	strs << str;
	strs >> hour;
	strs >> dum;	//":"
	strs >> minute;
	strs >> dum;	//":"
	strs >> second;
	strs >> pm;

	int time = 3600 * hour + 60 * minute + second;
	if (pm == "PM")
		time += 12 * 3600;

	return time;
}
std::string timeToStr(int time) {
	if (time < 0)
		return "0";
	std::stringstream ss;
	ss << time / 3600 << ":";
	time = time - 3600 * (time / 3600);
	ss << time / 60 << ":";
	time = time - 60 * (time / 60);
	ss << time;
	return ss.str();
}