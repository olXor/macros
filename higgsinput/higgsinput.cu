#include <iostream>
#include <string>
#include <sstream>
#include <fstream>
#include <vector>
#define _USE_MATH_DEFINES
#include <math.h>

#define datastring "D:/higgs/data/"

std::vector<float> convertFeatures(std::vector<float> inputs);

int main() {
	std::string infname;
	std::string outfname;
	bool convertInputs = false;
	bool trainingFile = false;
	std::cout << "Enter input file name: ";
	std::cin >> infname;
	std::cout << "Enter output file prefix: ";
	std::cin >> outfname;
	std::cout << "Convert inputs? ";
	std::cin >> convertInputs;
	std::cout << "Does this file have training information? ";
	std::cin >> trainingFile;

	std::ifstream infile(datastring + infname);
	std::ofstream signalfile(datastring + outfname + "_s");
	std::ofstream backgroundfile(datastring + outfname + "_b");
	std::ofstream totaloutfile(datastring + outfname);

	if (!infile.is_open()) {
		std::cout << "Couldn't find input file." << std::endl;
		system("pause");
		return 0;
	}

	std::string line;
	std::getline(infile, line);	//header

	while (std::getline(infile, line)) {
		std::string tok;
		std::stringstream lss(line);
		size_t id;
		float weight = 1.0f;
		std::string type;

		std::getline(lss, tok, ',');
		std::stringstream tss(tok);
		tss >> id;

		std::vector<float> features(30);
		for (size_t i = 0; i < 30; i++) {
			std::getline(lss, tok, ',');
			tss.clear();
			tss.str(tok);
			tss >> features[i];
		}

		//output
		std::ofstream* outfile;

		if (trainingFile) {
			std::getline(lss, tok, ',');
			tss.clear();
			tss.str(tok);
			tss >> weight;

			std::getline(lss, tok, ',');
			tss.clear();
			tss.str(tok);
			tss >> type;

			if (type == "s")
				outfile = &signalfile;
			else
				outfile = &backgroundfile;
		}
		else {
			outfile = &totaloutfile;
		}

		if (convertInputs)
			features = convertFeatures(features);
		(*outfile) << weight << " ";
		for (size_t i = 0; i < features.size(); i++) {
			(*outfile) << features[i] << " ";
		}
		(*outfile) << std::endl;
	}
}

std::vector<float> convertFeatures(std::vector<float> inputs) {
	std::vector<float> convFeatures;

	float val;
	//estimated higgs mass
	val = inputs[0];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//transverse mass between missing transverse energy and lepton
	val = inputs[1];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//visible invariant mass
	val = inputs[2];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//modulus of p_t of tau, lepton, and miss_pt
	val = inputs[3];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//jet-jet d_eta
	val = inputs[4];
	if (val != -999)
		convFeatures.push_back(val);
	else
		convFeatures.push_back(NAN);

	//jet-jet invariant mass
	val = inputs[5];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//jet-jet eta product
	val = inputs[6];
	if (val != -999)
		convFeatures.push_back(val);
	else
		convFeatures.push_back(NAN);

	//hadron tau-lepton R separation
	val = inputs[7];
	if (val != -999)
		convFeatures.push_back(val);
	else
		convFeatures.push_back(NAN);

	//total p_t modulus (without additional jets)
	val = inputs[8];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//total p_t modulus
	val = inputs[9];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//lep-tau ratio
	val = inputs[10];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//m_et-phi centrality
	val = inputs[11];
	if (val != -999)
		convFeatures.push_back(val);
	else
		convFeatures.push_back(NAN);

	//lep-eta centrality
	val = inputs[12];
	if (val != -999)
		convFeatures.push_back(val);
	else
		convFeatures.push_back(NAN);

	//tau-pt
	val = inputs[13];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//tau-eta
	val = inputs[14];
	if (val != -999)
		convFeatures.push_back(val);
	else
		convFeatures.push_back(NAN);

	//tau-phi
	/*
	val = inputs[15];
	if (val != -999)
		convFeatures.push_back(val);
	else
		convFeatures.push_back(NAN);
		*/

	//lep-pt
	val = inputs[16];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//lep-eta
	val = inputs[17];
	if (val != -999)
		convFeatures.push_back(val);
	else
		convFeatures.push_back(NAN);

	//lep-phi
	/*
	val = inputs[18];
	if (val != -999)
		convFeatures.push_back(val);
	else
		convFeatures.push_back(NAN);
		*/

	//met
	val = inputs[19];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//met-phi
	/*
	val = inputs[20];
	if (val != -999)
		convFeatures.push_back(val);
	else
		convFeatures.push_back(NAN);
		*/

	//met-sum_et
	val = inputs[21];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//jet num
	val = inputs[22];
	if (val != -999)
		convFeatures.push_back(val);
	else
		convFeatures.push_back(NAN);

	//jet leading pt
	val = inputs[23];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//jet leading eta
	val = inputs[24];
	if (val != -999)
		convFeatures.push_back(val);
	else
		convFeatures.push_back(NAN);

	//jet leading phi
	/*
	val = inputs[25];
	if (val != -999)
		convFeatures.push_back(val);
	else
		convFeatures.push_back(NAN);
		*/

	//jet subleading pt
	val = inputs[26];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//jet subleading eta
	val = inputs[27];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//jet subleading phi
	/*
	val = inputs[28];
	if (val != -999)
		convFeatures.push_back(val);
	else
		convFeatures.push_back(NAN);
		*/

	//jet sum pt
	val = inputs[29];
	if (val != -999)
		convFeatures.push_back(std::log(val));
	else
		convFeatures.push_back(NAN);

	//Additional features

	//tau: 15, lep: 18, met: 20, jet1: 25, jet2: 28
	//tau-lep phi diff
	float phi1 = inputs[15];
	float phi2 = inputs[18];
	float convPhi;
	if (phi1 == -999 || phi2 == -999)
		convPhi = NAN;
	else {
		convPhi = fabs(phi1 - phi2);
		if (convPhi > M_PI)
			convPhi = 2 * M_PI - convPhi;
	}
	convFeatures.push_back(convPhi);

	//tau-met phi diff
	phi1 = inputs[15];
	phi2 = inputs[20];
	if (phi1 == -999 || phi2 == -999)
		convPhi = NAN;
	else {
		convPhi = fabs(phi1 - phi2);
		if (convPhi > M_PI)
			convPhi = 2 * M_PI - convPhi;
	}
	convFeatures.push_back(convPhi);

	//tau-jet1 phi diff
	phi1 = inputs[15];
	phi2 = inputs[25];
	if (phi1 == -999 || phi2 == -999)
		convPhi = NAN;
	else {
		convPhi = fabs(phi1 - phi2);
		if (convPhi > M_PI)
			convPhi = 2 * M_PI - convPhi;
	}
	convFeatures.push_back(convPhi);

	//tau-jet2 phi diff
	phi1 = inputs[15];
	phi2 = inputs[28];
	if (phi1 == -999 || phi2 == -999)
		convPhi = NAN;
	else {
		convPhi = fabs(phi1 - phi2);
		if (convPhi > M_PI)
			convPhi = 2 * M_PI - convPhi;
	}
	convFeatures.push_back(convPhi);

	//lep-met phi diff
	phi1 = inputs[18];
	phi2 = inputs[20];
	if (phi1 == -999 || phi2 == -999)
		convPhi = NAN;
	else {
		convPhi = fabs(phi1 - phi2);
		if (convPhi > M_PI)
			convPhi = 2 * M_PI - convPhi;
	}
	convFeatures.push_back(convPhi);

	//lep-jet1 phi diff
	phi1 = inputs[18];
	phi2 = inputs[25];
	if (phi1 == -999 || phi2 == -999)
		convPhi = NAN;
	else {
		convPhi = fabs(phi1 - phi2);
		if (convPhi > M_PI)
			convPhi = 2 * M_PI - convPhi;
	}
	convFeatures.push_back(convPhi);

	//lep-jet2 phi diff
	phi1 = inputs[18];
	phi2 = inputs[28];
	if (phi1 == -999 || phi2 == -999)
		convPhi = NAN;
	else {
		convPhi = fabs(phi1 - phi2);
		if (convPhi > M_PI)
			convPhi = 2 * M_PI - convPhi;
	}
	convFeatures.push_back(convPhi);

	//met-jet1 phi diff
	phi1 = inputs[20];
	phi2 = inputs[25];
	if (phi1 == -999 || phi2 == -999)
		convPhi = NAN;
	else {
		convPhi = fabs(phi1 - phi2);
		if (convPhi > M_PI)
			convPhi = 2 * M_PI - convPhi;
	}
	convFeatures.push_back(convPhi);

	//met-jet2 phi diff
	phi1 = inputs[20];
	phi2 = inputs[28];
	if (phi1 == -999 || phi2 == -999)
		convPhi = NAN;
	else {
		convPhi = fabs(phi1 - phi2);
		if (convPhi > M_PI)
			convPhi = 2 * M_PI - convPhi;
	}
	convFeatures.push_back(convPhi);

	//jet1-jet2 phi diff
	phi1 = inputs[25];
	phi2 = inputs[28];
	if (phi1 == -999 || phi2 == -999)
		convPhi = NAN;
	else {
		convPhi = fabs(phi1 - phi2);
		if (convPhi > M_PI)
			convPhi = 2 * M_PI - convPhi;
	}
	convFeatures.push_back(convPhi);

	return convFeatures;
}