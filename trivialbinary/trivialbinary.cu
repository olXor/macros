#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>
#include <cstdio>

#define PI 3.14159265

#define datastring "D:/trivialNetworkTest/"

int main() {
	FILE* trainfile = fopen((datastring + (std::string)"trainset").c_str(), "wb");
	FILE* testfile = fopen((datastring + (std::string)"testset").c_str(), "wb");

	for (size_t i = 0; i < 100000; i++) {
		float in1 = 2.0f*(rand() % 10000)*PI/10000.0f;
		float in2 = 2.0f*(rand() % 10000)*PI/10000.0f;
		float out = sin(in1)*sin(in2);
		fwrite(&out, sizeof(float), 1, trainfile);
		fwrite(&in1, sizeof(float), 1, trainfile);
		fwrite(&in2, sizeof(float), 1, trainfile);
	}
	for (size_t i = 0; i < 100000; i++) {
		float in1 = 2.0f*(rand() % 10000)*PI/10000.0f;
		float in2 = 2.0f*(rand() % 10000)*PI/10000.0f;
		float out = sin(in1)*sin(in2);
		fwrite(&out, sizeof(float), 1, testfile);
		fwrite(&in1, sizeof(float), 1, testfile);
		fwrite(&in2, sizeof(float), 1, testfile);
	}
	fclose(trainfile);
	fclose(testfile);
}
