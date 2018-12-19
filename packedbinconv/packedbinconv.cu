#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>

#define datastring "D:/momArtline/bindata/"

int main() {
	std::string infname;
	std::cout << "Enter name of input packed binary file: ";
	std::cin >> infname;

	FILE* infile = fopen((datastring + infname).c_str(), "rb");

	size_t version;
	fread(&version, sizeof(size_t), 1, infile);
	size_t columnNum;
	fread(&columnNum, sizeof(size_t), 1, infile);
	std::cout << "Version: " << version << " Num columns: " << columnNum << std::endl;

	std::vector<float> columns(columnNum);
	size_t readCount = 0;
	size_t entries = 0;
	do {
		readCount = fread(&columns[0], sizeof(float), columnNum, infile);
		for (size_t i = 0; i < columns.size(); i++)
			std::cout << columns[i] << " ";
		std::cout << std::endl;
		system("pause");
		if (readCount == columnNum)
			entries++;
	} while (readCount == columnNum);

	std::cout << entries << " entries read" << std::endl;
}
