#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <algorithm>

#define SENSOR_LENGTH 336
//#define datastring "D:/momRegression/rawdata/"
#define datastring ""

void saveOutputFile1(std::string infname, std::ofstream* outfile);
void saveOutputFile2(std::string infname, std::ofstream* outfile);
void saveOutputFile3(std::string infname, std::ofstream* outfile);
void saveOutputFile4(std::string infname, FILE* outbinfile);
void saveOutputFile5(std::string infname, FILE* outbinfile);
void saveOutputFile7(std::string infname, FILE* outbinfile);
void saveOutputFile8(std::string infname, FILE* outbinfile);

int main() {
	std::string trainfname;
	std::cout << "Enter trainset name: ";
	std::cin >> trainfname;
	trainfname = datastring + trainfname;
	
	std::string outfname;
	std::cout << "Enter name of output file: ";
	std::cin >> outfname;
	std::string shortOutFname = outfname;
	outfname = datastring + outfname;

	size_t inputType = 0;
	std::cout << "Enter input type: ";
	std::cin >> inputType;

	std::ofstream intervalfile(outfname + "_interval");

	std::ifstream infile(trainfname);
	std::string line;
	size_t num = 0;
	while (std::getline(infile, line)) {
		std::cout << "Converting file: " << line << std::endl;
		num++;
		std::stringstream lss(line);
		std::string fname;
		lss >> fname;
		fname = datastring + fname;
		std::stringstream outfss;
		outfss << datastring << shortOutFname << "_" << num;
		if (inputType == 1) {
			std::ofstream outfile(outfss.str());
			saveOutputFile1(fname, &outfile);
		}
		else if (inputType == 2) {
			std::ofstream outfile(outfss.str());
			saveOutputFile2(fname, &outfile);
		}
		else if (inputType == 3) {
			std::ofstream outfile(outfss.str());
			saveOutputFile3(fname, &outfile);
		}
		else if (inputType == 4) {
			FILE* outfile = fopen(outfss.str().c_str(), "wb");
			saveOutputFile4(fname, outfile);
			fclose(outfile);
		}
		else if (inputType == 5) {
			FILE* outfile = fopen(outfss.str().c_str(), "wb");
			saveOutputFile5(fname, outfile);
			fclose(outfile);
		}
		else if (inputType == 7) {
			FILE* outfile = fopen(outfss.str().c_str(), "wb");
			saveOutputFile7(fname, outfile);
			fclose(outfile);
		}
		else if (inputType == 8) {
			FILE* outfile = fopen(outfss.str().c_str(), "wb");
			saveOutputFile8(fname, outfile);
			fclose(outfile);
		}
		else {
			std::cout << "Input type not recognized" << std::endl;
			system("pause");
			return;
		}
		intervalfile << outfss.str() << std::endl;
	}

	std::cout << "Done. " << std::endl;
	system("pause");
}

//quality, 336 point intervals, sensor data
void saveOutputFile1(std::string infname, std::ofstream* outfile) {
	std::ifstream infile(infname);

	std::string line;
	std::getline(infile, line);	//header

	while (std::getline(infile, line)) {
		std::replace(line.begin(), line.end(), ',', ' ');
		std::stringstream lss(line);
		std::string dum;
		lss >> dum;	//clipped flag
		if (dum == "True")
			continue;
		lss >> dum;	//peak mismatch flag
		if (dum == "True")
			continue;

		lss >> dum >> dum >> dum >> dum;	//SegmentNum, WindowNum, SegmentQuality, SegmentCorrelation

		float windowCorrelation;
		lss >> windowCorrelation;

		(*outfile) << "dummy," << windowCorrelation << ",";

		lss >> dum >> dum >> dum >> dum >> dum >> dum;	//SBP, DBP, 1_min_SBP, 1_min_DBP, SensorPeak, SensorValley

		float val;
		std::vector<float> vals;
		float minVal = 9999;
		float maxVal = -9999;
		for (size_t i = 0; i < SENSOR_LENGTH; i++) {
			lss >> val;
			vals.push_back(val);
			minVal = std::min(val, minVal);
			maxVal = std::max(val, maxVal);
		}
		for (size_t i = 0; i < vals.size(); i++) {
			(*outfile) << 2.0f*(vals[i] - minVal) / (maxVal - minVal) - 1.0f << ",";
		}
		(*outfile) << std::endl;
	}
}

//take 336 point interval from first 512 point interval
void saveOutputFile2(std::string infname, std::ofstream* outfile) {
	std::ifstream infile(infname);

	std::string line;
	std::getline(infile, line);	//header

	while (std::getline(infile, line)) {
		std::replace(line.begin(), line.end(), ',', ' ');
		std::stringstream lss(line);
		std::string dum;

		lss >> dum >> dum;	//SegmentNum, WindowNum

		float SBP;
		float DBP;
		lss >> SBP >> DBP;

		(*outfile) << "dummy," << SBP << "," << DBP << ",";

		//88 dummy indices to accomodate the transition from 512 points to 336 points
		for (size_t i = 0; i < 512 / 2 - 336 / 2; i++)
			lss >> dum;

		float val;
		std::vector<float> vals;
		float minVal = 9999;
		float maxVal = -9999;
		for (size_t i = 0; i < SENSOR_LENGTH; i++) {
			lss >> val;
			vals.push_back(val);
			minVal = std::min(val, minVal);
			maxVal = std::max(val, maxVal);
		}
		for (size_t i = 0; i < vals.size(); i++) {
			(*outfile) << 2.0f*(vals[i] - minVal) / (maxVal - minVal) - 1.0f << ",";
		}
		(*outfile) << std::endl;
	}
}

//quality with 512 point intervals, sensor data, also includes inverted data
void saveOutputFile3(std::string infname, std::ofstream* outfile) {
	std::ifstream infile(infname);

	std::string line;
	std::getline(infile, line);	//header

	while (std::getline(infile, line)) {
		std::replace(line.begin(), line.end(), ',', ' ');
		std::stringstream lss(line);
		std::string dum;
		lss >> dum;	//clipped flag
		if (dum == "True")
			continue;
		lss >> dum;	//peak mismatch flag
		if (dum == "True")
			continue;

		lss >> dum >> dum >> dum >> dum;	//SegmentNum, WindowNum, SegmentQuality, SegmentCorrelation

		float windowCorrelation;
		lss >> windowCorrelation;

		lss >> dum >> dum >> dum >> dum >> dum >> dum;	//SBP, DBP, 1_min_SBP, 1_min_DBP, SensorPeak, SensorValley

		float val;
		std::vector<float> vals;
		float minVal = 9999;
		float maxVal = -9999;
		for (size_t i = 0; i < 512; i++) {
			lss >> val;
			vals.push_back(val);
			minVal = std::min(val, minVal);
			maxVal = std::max(val, maxVal);
		}

		(*outfile) << "dummy," << windowCorrelation << ",";
		for (size_t i = 0; i < vals.size(); i++) {
			(*outfile) << 2.0f*(vals[i] - minVal) / (maxVal - minVal) - 1.0f << ",";
		}
		(*outfile) << std::endl;
		(*outfile) << "dummy," << -windowCorrelation << ",";
		for (size_t i = 0; i < vals.size(); i++) {
			(*outfile) << -(2.0f*(vals[i] - minVal) / (maxVal - minVal) - 1.0f) << ",";
		}
		(*outfile) << std::endl;
	}
}

//quality with 512 point intervals, sensor data, also includes inverted data; binary output
void saveOutputFile4(std::string infname, FILE* outbinfile) {
	std::ifstream infile(infname);

	std::string line;
	std::getline(infile, line);	//header

	float dumVal = 0;
	fwrite(&dumVal, sizeof(float), 1, outbinfile);
	fwrite(&dumVal, sizeof(float), 1, outbinfile);	//dummy header

	while (std::getline(infile, line)) {
		std::replace(line.begin(), line.end(), ',', ' ');
		std::stringstream lss(line);
		std::string dum;
		lss >> dum;	//clipped flag
		if (dum == "True")
			continue;
		lss >> dum;	//peak mismatch flag
		if (dum == "True")
			continue;

		lss >> dum >> dum >> dum >> dum;	//SegmentNum, WindowNum, SegmentQuality, SegmentCorrelation

		float windowCorrelation;
		lss >> windowCorrelation;

		lss >> dum >> dum >> dum >> dum >> dum >> dum;	//SBP, DBP, 1_min_SBP, 1_min_DBP, SensorPeak, SensorValley

		float val;
		std::vector<float> vals;
		float minVal = 9999;
		float maxVal = -9999;
		for (size_t i = 0; i < 512; i++) {
			lss >> val;
			vals.push_back(val);
			minVal = std::min(val, minVal);
			maxVal = std::max(val, maxVal);
		}

		fwrite(&windowCorrelation, sizeof(float), 1, outbinfile);
		for (size_t i = 0; i < vals.size(); i++) {
			float val = 2.0f*(vals[i] - minVal) / (maxVal - minVal) - 1.0f;
			fwrite(&val, sizeof(float), 1, outbinfile);
		}
		windowCorrelation = -windowCorrelation;
		fwrite(&windowCorrelation, sizeof(float), 1, outbinfile);
		for (size_t i = 0; i < vals.size(); i++) {
			float val = -(2.0f*(vals[i] - minVal) / (maxVal - minVal) - 1.0f);
			fwrite(&val, sizeof(float), 1, outbinfile);
		}
	}
}

//Artline, 512 intervals, outputs: sBP, dBP, dummy, dummy, unscaled waveform
void saveOutputFile5(std::string infname, FILE* outbinfile) {
	std::ifstream infile(infname);

	std::string line;
	std::getline(infile, line);	//header

	float dumVal = 0;
	fwrite(&dumVal, sizeof(float), 1, outbinfile);
	fwrite(&dumVal, sizeof(float), 1, outbinfile);	//dummy header

	while (std::getline(infile, line)) {
		std::replace(line.begin(), line.end(), ',', ' ');
		std::stringstream lss(line);
		std::string dum;

		lss >> dum >> dum;	//SegmentNum, WindowNum

		float sBP, dBP;
		lss >> sBP >> dBP;

		/*
		for (size_t i = 0; i < 512; i++)	//raw artline
			lss >> dum;
			*/

		float val;
		std::vector<float> vals;
		for (size_t i = 0; i < 512; i++) {
			lss >> val;
			vals.push_back(val);
		}

		fwrite(&dBP, sizeof(float), 1, outbinfile);
		fwrite(&sBP, sizeof(float), 1, outbinfile);
		float dumFloat = 0;
		fwrite(&dumFloat, sizeof(float), 1, outbinfile);
		fwrite(&dumFloat, sizeof(float), 1, outbinfile);
		for (size_t i = 0; i < vals.size(); i++)
			fwrite(&vals[i], sizeof(float), 1, outbinfile);
	}
}

//Sid fixed data
void saveOutputFile6(std::string infname, FILE* outbinfile) {
	std::ifstream infile(infname);

	std::string line;
	std::getline(infile, line);	//header
}

//Meet sensor data with aline
void saveOutputFile7(std::string infname, FILE* outbinfile) {
	std::ifstream infile(infname);

	std::string line;
	std::getline(infile, line);	//header

	float dumVal = 0;
	fwrite(&dumVal, sizeof(float), 1, outbinfile);
	fwrite(&dumVal, sizeof(float), 1, outbinfile);	//dummy header

	std::vector<float> outputs;
	std::vector<float> sensor(512);
	std::vector<float> peaks;
	size_t waveformId = 0;
	while (std::getline(infile, line)) {
		outputs.clear();
		outputs.resize(17);
		outputs[0] = waveformId;
		peaks.clear();
		peaks.resize(512);

		float sensorPeak = 0;
		float sensorValley = 0;
		
		size_t column = 0;
		//std::replace(line.begin(), line.end(), ',', ' ');
		std::stringstream lss(line);
		std::string dum;
		bool saveEvent = true;
		while (std::getline(lss, dum, ',')) {
			if (column == 0 && dum == "True") {
				saveEvent = false;
				break;
			}
			else if (column == 1 && dum == "True") {
				saveEvent = false;
				break;
			}
			else if (column == 4) {
				float qual;
				if(!(std::stringstream(dum) >> qual))
					std::cout << "Invalid column: " << dum << std::endl;
				if (fabs(qual) < 3) {
					saveEvent = false;
					break;
				}
			}
			else if (column == 7) {
				float sbp;
				if(!(std::stringstream(dum) >> sbp))
					std::cout << "Invalid column: " << dum << std::endl;
				outputs[2] = sbp;
			}
			else if (column == 9) {
				float dbp;
				if(!(std::stringstream(dum) >> dbp))
					std::cout << "Invalid column: " << dum << std::endl;
				outputs[1] = dbp;
			}
			else if (column == 13) {
				if(!(std::stringstream(dum) >> sensorPeak))
					std::cout << "Invalid column: " << dum << std::endl;
			}
			else if (column == 14) {
				if(!(std::stringstream(dum) >> sensorValley))
					std::cout << "Invalid column: " << dum << std::endl;
			}
			else if (column >= 15 && column <= 526) {
				if (!(std::stringstream(dum) >> sensor[column - 15]))
					std::cout << "Invalid column: " << dum << std::endl;
				if (sensorPeak > sensorValley)
					sensor[column - 15] = 2.0f*(sensor[column - 15] - sensorValley) / (sensorPeak - sensorValley) - 1.0f;
			}
			else if (column >= 527 && column <= 546) {
				size_t peakIndex;
				if ((std::stringstream(dum) >> peakIndex))
					peaks[peakIndex] = 1;
			}
			else if (column >= 547 && column <= 566) {
				size_t valleyIndex;
				if ((std::stringstream(dum) >> valleyIndex))
					peaks[valleyIndex] = -1;
			}

			column++;
		}
		if (saveEvent) {
			fwrite(&outputs[0], sizeof(float), outputs.size(), outbinfile);
			fwrite(&sensor[0], sizeof(float), sensor.size(), outbinfile);
			fwrite(&peaks[0], sizeof(float), peaks.size(), outbinfile);
		}
		waveformId++;
	}

}

//Meet sensor data with aline (earlier format, no peaks). Includes inverted waveform.
void saveOutputFile8(std::string infname, FILE* outbinfile) {
	std::ifstream infile(infname);

	std::string line;
	std::getline(infile, line);	//header

	float dumVal = 0;
	fwrite(&dumVal, sizeof(float), 1, outbinfile);
	fwrite(&dumVal, sizeof(float), 1, outbinfile);	//dummy header

	std::vector<float> outputs;
	std::vector<float> sensor(512);
	size_t waveformId = 0;
	while (std::getline(infile, line)) {
		outputs.clear();
		outputs.resize(2);
		
		float sensorPeak = 0;
		float sensorValley = 0;

		size_t column = 0;
		//std::replace(line.begin(), line.end(), ',', ' ');
		std::stringstream lss(line);
		std::string dum;
		bool saveEvent = true;

		while (std::getline(lss, dum, ',')) {
			if (column == 0 && dum == "True") {
				saveEvent = false;
				break;
			}
			else if (column == 1 && dum == "True") {
				saveEvent = false;
				break;
			}
			else if (column == 7) {
				float sbp;
				if(!(std::stringstream(dum) >> sbp))
					std::cout << "Invalid column: " << dum << std::endl;
				outputs[0] = sbp;
			}
			else if (column == 11) {
				if(!(std::stringstream(dum) >> sensorPeak))
					std::cout << "Invalid column: " << dum << std::endl;
			}
			else if (column == 12) {
				if(!(std::stringstream(dum) >> sensorValley))
					std::cout << "Invalid column: " << dum << std::endl;
			}
			else if (column >= 13 && column <= 524) {
				if (!(std::stringstream(dum) >> sensor[column - 13]))
					std::cout << "Invalid column: " << dum << std::endl;
				if (sensorPeak > sensorValley)
					sensor[column - 13] = 2.0f*(sensor[column - 13] - sensorValley) / (sensorPeak - sensorValley) - 1.0f;
				else
					sensor[column - 13] = 0;
			}

			column++;
		}
		if (saveEvent) {
			fwrite(&outputs[0], sizeof(float), outputs.size(), outbinfile);
			fwrite(&sensor[0], sizeof(float), sensor.size(), outbinfile);
			for (size_t s = 0; s < sensor.size(); s++) {
				sensor[s] = -sensor[s];
			}
			fwrite(&outputs[0], sizeof(float), outputs.size(), outbinfile);
			fwrite(&sensor[0], sizeof(float), sensor.size(), outbinfile);
		}
		waveformId++;
	}

}