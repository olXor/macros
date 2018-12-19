#include "structdef.cuh"
#define _USE_MATH_DEFINES
#include <math.h>

#define datastring "D:/stopSearch/data/"
//#define signalstring "eventSaveBTag3JetsignalWB_350-200_1871520"
//#define backgroundstring "eventSaveBTag3Jetbackground_7625071"
//#define signalstring "convFixPhiBTag_WBSignal_350-200_1994132"
//#define signalstring "convFixPhiBTag_signalTN_185-5_1300000"
//#define backgroundstring "convFixPhiBTag_background_7625071"
//#define signalstring "../weights/deep_350-200_FixPhiWBMatchedNoMETEtaBTag_L1_2e-5/nhistL12N0_g10_type0"
//#define backgroundstring "../weights/deep_350-200_FixPhiWBMatchedNoMETEtaBTag_L1_2e-5/nhistL12N0_g10_type1"
//#define signalstring "../weights/deep_350-200_FixPhiWBMatchedNoMETEtaBTag_L1_2e-5/nhistL12N0_l10g-10_type0"
//#define backgroundstring "../weights/deep_350-200_FixPhiWBMatchedNoMETEtaBTag_L1_2e-5/nhistL12N0_l10g-10_type1"
//#define signalstring "../weights/deep_350-200_FixPhiWBMatchedNoMETEtaBTag_L1_2e-5/nhistL12N0_l-10_type0"
//#define backgroundstring "../weights/deep_350-200_FixPhiWBMatchedNoMETEtaBTag_L1_2e-5/nhistL12N0_l-10_type1"
//#define signalstring "convRelPhiBTag_TNSignal_185-5_1300000"
//#define backgroundstring "convRelPhiBTag_background_7625071"
//#define signalstring "../weights/deep_185-5_FixPhiTNNoMETEtaBTag_L1_2e-5_dropout/nhistL4N11_g100_type0"
//#define backgroundstring "../weights/deep_185-5_FixPhiTNNoMETEtaBTag_L1_2e-5_dropout/nhistL4N11_g100_type1"
//#define signalstring "../weights/deep_185-5_FixPhiTNNoMETEtaBTag_L1_2e-5_dropout/nhistL12N0_l-0p4_type0"
//#define backgroundstring "../weights/deep_185-5_FixPhiTNNoMETEtaBTag_L1_2e-5_dropout/nhistL12N0_l-0p4_type1"
//#define signalstring "../weights/deep_185-5_FixPhiTNNoMETEtaBTag_L1_2e-5_dropout/nhistL12N0_type0"
//#define backgroundstring "../weights/deep_185-5_FixPhiTNNoMETEtaBTag_L1_2e-5_dropout/nhistL12N0_type1"
//#define signalstring "../weights/deep_185-5_FixPhiTNNoMETEtaBTag_L1_2e-5_dropout/nhistL12N0_l-0p4_all"
//#define backgroundstring "../weights/deep_185-5_FixPhiTNNoMETEtaBTag_L1_2e-5_dropout/nhistL12N0_all"
#define signalstring "../weights/deep_750-1_FixPhiTNBTag_L1_2e-5/nhistL12N0_l-20_type0"
#define backgroundstring "../weights/deep_750-1_FixPhiTNBTag_L1_2e-5/nhistL12N0_g-20_type1"

#define NORMALIZE_SBRATIO 0

#define WEIGHT_1 (5*0.00184*35900/1968700)
//#define WEIGHT_1 (5*0.0834*35900/1968700)
//#define WEIGHT_1 (5*2.38*35900/1300000)
#define WEIGHT_2 (5*24.6*35900/7329772)

#define CUSTOM_VAR_SIZE 2

/*
#define datastring "D:/stopSearch/data/"
#define signalstring "nhistL5N10_type0"
#define backgroundstring "nhistL5N10_type1"
*/

#define NUM_BINS 20

bool acceptEvent(std::vector<float>* vals) {
	//remember to add one because first val is network output
	size_t preVars = 1;	//number of variables coming before input (ie. network output)
	float metPt = exp((*vals)[0 + preVars]);
	float metPhi = 0;
	float l1Pt = exp((*vals)[1 + preVars]);
	float l2Pt = exp((*vals)[3 + preVars]);
	float j1Pt = exp((*vals)[5 + preVars]);
	float j2Pt = exp((*vals)[8 + preVars]);

	//FixPhiBTag
	float l1Phi = (*vals)[11 + preVars]*(*vals)[12 + preVars];
	float l2Phi = (*vals)[13 + preVars]*(*vals)[14 + preVars];
	float j1Phi = (*vals)[15 + preVars]*(*vals)[16 + preVars];
	float j2Phi = (*vals)[17 + preVars]*(*vals)[18 + preVars];

	//RelPhiBTag
	/*
	float l1Phi = (*vals)[11 + preVars];
	float l2Phi = (*vals)[12 + preVars]*(*vals)[13 + preVars];
	float j1Phi = (*vals)[14 + preVars]*(*vals)[15 + preVars];
	float j2Phi = (*vals)[16 + preVars]*(*vals)[17 + preVars];
	*/

	float l1Eta = (*vals)[2 + preVars];
	float l2Eta = (*vals)[4 + preVars];

	//return std::cos(l1Phi) < -0.5 && std::cos(l2Phi) < -0.5 && metPt + 2 * l2Pt > 160;
	//return fabs(l1Phi - l2Phi) < M_PI/4 && fabs(l1Phi) < M_PI/2 && fabs(l2Phi) < M_PI/2;
	return true;
}

std::vector<float> getCustomVars(std::vector<float>* vals) {
	std::vector<float> vars(CUSTOM_VAR_SIZE);
	//remember to add one because first val is network output
	size_t preVars = 1;	//number of variables coming before input (ie. network output)
	float metPt = exp((*vals)[0 + preVars]);
	float metPhi = 0;
	float l1Pt = exp((*vals)[1 + preVars]);
	float l2Pt = exp((*vals)[3 + preVars]);
	float j1Pt = exp((*vals)[5 + preVars]);
	float j2Pt = exp((*vals)[8 + preVars]);

	//FixPhiBTag
	float l1Phi = (*vals)[11 + preVars]*(*vals)[12 + preVars];
	float l2Phi = (*vals)[13 + preVars]*(*vals)[14 + preVars];
	float j1Phi = (*vals)[15 + preVars]*(*vals)[16 + preVars];
	float j2Phi = (*vals)[17 + preVars]*(*vals)[18 + preVars];

	//RelPhiBTag
	/*
	float l1Phi = (*vals)[11 + preVars];
	float l2Phi = (*vals)[12 + preVars]*(*vals)[13 + preVars];
	float j1Phi = (*vals)[14 + preVars]*(*vals)[15 + preVars];
	float j2Phi = (*vals)[16 + preVars]*(*vals)[17 + preVars];
	*/

	float l1Eta = (*vals)[2 + preVars];
	float l2Eta = (*vals)[4 + preVars];

	float metPx = metPt*cos(metPhi);
	float metPy = metPt*sin(metPhi);
	float l1Px = l1Pt*cos(l1Phi);
	float l1Py = l1Pt*sin(l1Phi);
	float l2Px = l2Pt*cos(l2Phi);
	float l2Py = l2Pt*sin(l2Phi);
	float j1Px = j1Pt*cos(j1Phi);
	float j1Py = j1Pt*sin(j1Phi);
	float j2Px = j2Pt*cos(j2Phi);
	float j2Py = j2Pt*sin(j2Phi);

	float recoilPx = metPx + l1Px + l2Px + j1Px + j2Px;
	float recoilPy = metPy + l1Py + l2Py + j1Py + j2Py;
	float recoilPt = sqrt(recoilPx*recoilPx + recoilPy*recoilPy);

	float phiSum = fabs(l1Phi) + fabs(l2Phi);

	float ISRPt = 0;
	if ((*vals)[8] == 1 && (*vals)[11] == 1)
		ISRPt = recoilPt;
	else if ((*vals)[8] == -1)
		ISRPt = j1Pt;
	else if ((*vals)[11] == -1)
		ISRPt = j2Pt;

	float lepPhiDiff = fabs(l1Phi - l2Phi);
	if (lepPhiDiff > M_PI)
		lepPhiDiff = 2 * M_PI - lepPhiDiff;
	float lepPhiSum = fabs(l1Phi) + fabs(l2Phi);
	float lepEtaDiff = fabs(l1Eta - l2Eta);
	//vars[0] = lepPhiDiff;// fabs(l1Eta - l2Eta);
	//vars[0] = l1Phi*l2Phi;
	//vars[0] = 3 * std::log(metPt) + std::log(l1Pt) + std::log(l2Pt);
	//vars[0] = l1Eta - l2Eta;
	vars[0] = std::log(metPt);
	vars[1] = lepPhiSum;

	return vars;
}

void convertInputs(std::vector<float>* inputs) {
	return;
	(*inputs)[0] = std::log((*inputs)[0]);
	(*inputs)[3] = std::log((*inputs)[3]);
	(*inputs)[6] = std::log((*inputs)[6]);
	(*inputs)[9] = std::log((*inputs)[9]);
	(*inputs)[13] = std::log((*inputs)[13]);
	(*inputs)[17] = std::log((*inputs)[17]);

	//non-overlapping phi combinations
	bool addBTags = true;
	for (size_t i = 1; i < 6; i++) {
		size_t numExtraVars = (i > 3 && addBTags ? i - 3 : 0);	//b-tags
		float firstPhi = (*inputs)[1];	//MET
		float secondPhi = (*inputs)[3 * i + 1 + numExtraVars];
		float phiDiff = secondPhi - firstPhi;
		float convPhi = fabs(firstPhi - secondPhi);
		if (phiDiff > M_PI)
			phiDiff -= 2 * M_PI;
		if (phiDiff < -M_PI)
			phiDiff += 2 * M_PI;
		float phiSign = (phiDiff > 0 ? 1 : -1);
		if (convPhi > M_PI)
			convPhi = 2 * M_PI - convPhi;
		if (firstPhi == 0 || secondPhi == 0)
			convPhi = 0;
		(*inputs)[3 * i + 1 + numExtraVars] = convPhi;
	}
}

int main() {
	std::string suffix;
	std::cout << "Enter suffix (\".\") for none: ";
	std::cin >> suffix;
	std::stringstream sigss;
	sigss << datastring << signalstring << (suffix != "." ? suffix : "");
	std::ifstream sigstream(sigss.str());
	std::stringstream backss;
	backss << datastring << backgroundstring << (suffix != "." ? suffix : "");
	std::ifstream backstream(backss.str());
	std::stringstream outss;
	outss << datastring << "plotdist_save";
	std::ofstream outstream(outss.str());
	std::stringstream outss2;
	outss2 << datastring << "plotdist_save2";
	std::ofstream outstream2(outss2.str());
	std::stringstream outss3;
	outss3 << datastring << "plotdist_save3";
	std::ofstream outstream3(outss3.str());
	std::stringstream outss4;
	outss4 << datastring << "plotdist_save4";
	std::ofstream outstream4(outss4.str());

	std::vector<size_t> vars;
	bool doneGetVars = false;
	bool manualBounds = false;
	std::cout << "Enter histogram boundaries manually? ";
	std::cin >> manualBounds;
	std::vector<float> manualMins;
	std::vector<float> manualMaxes;
	bool useCustomVars = false;
	std::cout << "Use hardcoded custom variables? ";
	std::cin >> useCustomVars;
	if (!useCustomVars) {
		while (!doneGetVars) {
			std::cout << "Enter variable to plot: ";
			size_t var;
			std::cin >> var;
			vars.push_back(var);
			if (manualBounds) {
				std::cout << "Enter min: ";
				float min;
				std::cin >> min;
				manualMins.push_back(min);
				std::cout << "Enter max: ";
				float max;
				std::cin >> max;
				manualMaxes.push_back(max);
			}
			std::cout << "Done entering variables? ";
			std::cin >> doneGetVars;
		}
	}
	else {
		for (size_t i = 0; i < CUSTOM_VAR_SIZE; i++) {
			vars.push_back(0);
			if (manualBounds) {
				std::cout << "Enter min " << i + 1 << ": ";
				float min;
				std::cin >> min;
				manualMins.push_back(min);
				std::cout << "Enter max " << i + 1 << ": ";
				float max;
				std::cin >> max;
				manualMaxes.push_back(max);
			}
		}
	}

	std::vector<std::ifstream*> streams;
	streams.push_back(&sigstream);
	streams.push_back(&backstream);

	std::vector<std::vector<std::vector<float>>> vals(streams.size());
	std::string line;
	std::vector<float> curVals;
	std::vector<float> minVals(vars.size());
	std::vector<float> maxVals(vars.size());
	std::vector<size_t> numBins(vars.size());
	for (size_t i = 0; i < vars.size(); i++) {
		minVals[i] = 99999;
		maxVals[i] = -99999;
		numBins[i] = NUM_BINS;
	}

	for (size_t i = 0; i < streams.size(); i++) {
		while (std::getline((*streams[i]), line)) {
			curVals.clear();
			std::stringstream lss(line);
			float val;
			while (lss >> val)
				curVals.push_back(val);
			convertInputs(&curVals);
			std::vector<float> varVals;
			if (!useCustomVars) {
				for (size_t v = 0; v < vars.size(); v++)
					varVals.push_back(curVals[vars[v]]);
			}
			else
				varVals = getCustomVars(&curVals);
			if (acceptEvent(&curVals))
				vals[i].push_back(varVals);

			for (size_t j = 0; j < vars.size(); j++) {
				minVals[j] = std::min(minVals[j], varVals[j]);
				maxVals[j] = std::max(maxVals[j], varVals[j]);
			}
		}
	}

	std::vector<SparseHistogram> hists(streams.size());
	if (manualBounds) {
		minVals = manualMins;
		maxVals = manualMaxes;
	}
	for (size_t i = 0; i < hists.size(); i++) {
		hists[i].initHistogram(minVals, maxVals, numBins);
	}

	for (size_t i = 0; i < vals.size(); i++) {
		for (size_t j = 0; j < vals[i].size(); j++) {
			float weight = (i == 0 ? WEIGHT_1 : WEIGHT_2);
			hists[i].fill(vals[i][j], weight);
		}
	}

	if (vars.size() == 1) {
		for (size_t i = 0; i < NUM_BINS; i++) {
			float posVal = i*(hists[0].maxes[0] - hists[0].mins[0]) / hists[0].numBins[0] + hists[0].mins[0] + (hists[0].maxes[0] - hists[0].mins[0]) / hists[0].numBins[0] / 2;
			std::vector<size_t> pos;
			pos.push_back(i);
			outstream << posVal << " " << hists[0].getWeightOfBin(&pos) / hists[0].totalWeight << " " << hists[1].getWeightOfBin(&pos) / hists[1].totalWeight << " " << (hists[0].getWeightOfBin(&pos))/(hists[1].getWeightOfBin(&pos)) << std::endl;
		}
	}
	else if (vars.size() == 2) {
		outstream << "# " << minVals[0] << " " << maxVals[0] << " " << minVals[1] << " " << maxVals[1] << " " << numBins[0] << " " << numBins[1] << std::endl;
		for (size_t i = 0; i < numBins[0]; i++) {
			for (size_t j = 0; j < numBins[1]; j++) {
				std::vector<size_t> pos = { i, j };
				float normRatio = (NORMALIZE_SBRATIO ? hists[1].totalWeight / hists[0].totalWeight : 1);
				outstream << normRatio*hists[0].getWeightOfBin(&pos) / hists[1].getWeightOfBin(&pos) << " ";
			}
			outstream << std::endl;
		}

		outstream2 << "# " << minVals[0] << " " << maxVals[0] << " " << minVals[1] << " " << maxVals[1] << " " << numBins[0] << " " << numBins[1] << std::endl;
		for (size_t i = 0; i < numBins[0]; i++) {
			for (size_t j = 0; j < numBins[1]; j++) {
				std::vector<size_t> pos = { i, j };
				outstream2 << hists[0].getWeightOfBin(&pos) << " ";
			}
			outstream2 << std::endl;
		}

		outstream3 << "# " << minVals[0] << " " << maxVals[0] << " " << minVals[1] << " " << maxVals[1] << " " << numBins[0] << " " << numBins[1] << std::endl;
		for (size_t i = 0; i < numBins[0]; i++) {
			for (size_t j = 0; j < numBins[1]; j++) {
				std::vector<size_t> pos = { i, j };
				outstream3 << hists[1].getWeightOfBin(&pos) << " ";
			}
			outstream3 << std::endl;
		}

		outstream4 << "# " << minVals[0] << " " << maxVals[0] << " " << minVals[1] << " " << maxVals[1] << " " << numBins[0] << " " << numBins[1] << std::endl;
		for (size_t i = 0; i < numBins[0]; i++) {
			for (size_t j = 0; j < numBins[1]; j++) {
				std::vector<size_t> pos = { i, j };
				outstream4 << hists[0].getWeightOfBin(&pos) + hists[1].getWeightOfBin(&pos) << " ";
			}
			outstream4 << std::endl;
		}

		std::cout << "Total weights: Signal: " << hists[0].totalWeight << " Background: " << hists[1].totalWeight << std::endl;
	}
	else
		throwError("Too many variables");
}