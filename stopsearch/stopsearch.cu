#include <iostream>
#include <string>
#include <sstream>
#include <fstream>
#include <vector>
#define _USE_MATH_DEFINES
#include <math.h>
#include "lester_mt2_bisect.h"

#define NUM_PARTICLES 5
//#define NUM_INPUTS (NUM_PARTICLES*3)
#define NUM_INPUTS 17
#define datastring "D:/stopsearch/data/"

#define NUM_CAVEMAN_WEIGHTS 17

float getCavemanVar(std::vector<float> inputs);
std::vector<float> convertFeatures(std::vector<float> inputs);

int main() {
	std::string infname = "eventSaveBTagsignalTN_750-1_1968700";
	//std::string infname = "eventSaveBTagsignalWBMatched_380-200_1894470";
	//std::string infname = "eventSaveBTagsignalWBMatched_350-200_J3g200_1994132";
	//std::string infname = "eventSavebackground_J3g200_7625071";
	//std::string infname = "eventSaveBTagbackground_7625071";
	//std::string infname = "eventSavesignalTN_750-1_1870265";
	//std::string infname = "eventSaveBTagsignalTN_185-5_1300000";
	//std::string outfname = "convRazorTest_WBSignal";
	//std::string outfname = "convRazorTest_background";
	//std::string outfname = "convFixPhiBTagMT2_TNSignal_750-1_1968700";
	//std::string outfname = "convFixPhiBTag_background_J3g200_7625071";
	//std::string outfname = "convRelPhiBTag_background_7625071";
	//std::string outfname = "eventSaveBTagbackgroundMT2_7625071";
	std::string outfname = "eventSaveBTagsignalTNMT2_750-1_1968700";
	//std::string outfname = "convRelPhiBTag_TNSignal_185-5_1300000";
	//std::string outfname = "convFixPhiBTagMT2_background_7625071";

	bool convertInputs = true;
	/*
	std::cout << "Enter input file name: ";
	std::cin >> infname;
	std::cout << "Enter output file name: ";
	std::cin >> outfname;
	std::cout << "Convert inputs? ";
	std::cin >> convertInputs;
	*/

	std::ifstream infile(datastring + infname);
	std::ofstream totaloutfile(datastring + outfname);

	if (!infile.is_open()) {
		std::cout << "Couldn't find input file." << std::endl;
		system("pause");
		return 0;
	}

	std::string line;

	while (std::getline(infile, line)) {
		std::string tok;
		std::stringstream lss(line);

		if (line == "MISS" || line == "CUT") {
			totaloutfile << line << std::endl;
			continue;
		}
		std::vector<float> features(NUM_INPUTS);
		for (size_t i = 0; i < NUM_INPUTS; i++) {
			lss >> features[i];
		}

		if (convertInputs) {
			features = convertFeatures(features);
		}

		for (size_t i = 0; i < features.size(); i++) {
			totaloutfile << features[i] << " ";
		}
		totaloutfile << std::endl;
	}
}

//particles: met, l1, l2, j1, j2
std::vector<float> convertFeatures(std::vector<float> inputs) {
	//size_t numConvFeatures = 2 * NUM_PARTICLES + (NUM_PARTICLES*(NUM_PARTICLES - 1) / 2);
	//size_t numConvFeatures = 0;
	std::vector<float> convFeatures;

	/*
	bool addBTags = true;
	for (size_t i = 0; i < NUM_PARTICLES; i++) {
		size_t numExtraVars = (i > 3 && addBTags ? i - 3 : 0);	//b-tags
		if (inputs[3 * i + numExtraVars] != 0)
			convFeatures.push_back(std::log(inputs[3 * i + numExtraVars]));	//pt
		else
			convFeatures.push_back(0);
		//float missEtaSign = inputs[2] / fabs(inputs[2]);
		float lep1EtaSign = inputs[5] / fabs(inputs[5]);
		if (i != 0)
			convFeatures.push_back(inputs[3 * i + 2 + numExtraVars] / lep1EtaSign);	//eta

		if (i > 2 && addBTags)	//b-tag
			convFeatures.push_back(2 * inputs[3 * i + 3 + numExtraVars] - 1.0f);
	}

	float firstPhiSign = 1;
	//non-overlapping phi combinations
	for (size_t i = 1; i < NUM_PARTICLES; i++) {
		size_t numExtraVars = (i > 3 && addBTags ? i - 3 : 0);	//b-tags
		float firstPhi = inputs[1];	//MET
		float secondPhi = inputs[3 * i + 1 + numExtraVars];
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
		convFeatures.push_back(convPhi);
		if (i == 1)
			firstPhiSign = phiSign;
		else
			convFeatures.push_back(phiSign/firstPhiSign);
	}
	*/
	for (size_t i = 0; i < inputs.size(); i++)
		convFeatures.push_back(inputs[i]);

	/*
	//all phi combinations
	for (size_t i = 0; i < NUM_PARTICLES; i++) {
		for (size_t j = i + 1; j < NUM_PARTICLES; j++) {
			float firstPhi = inputs[3 * i + 1];
			float secondPhi = inputs[3 * j + 1];
			float convPhi = fabs(firstPhi - secondPhi);
			if (convPhi > M_PI)
				convPhi = 2 * M_PI - convPhi;
			if (firstPhi == 0 || secondPhi == 0)
				convPhi = 0;
			convFeatures.push_back(convPhi);
		}
	}
	*/

	//convFeatures.push_back(getCavemanVar(inputs));

	//convFeatures.push_back(inputs[0]);

	float metPt = inputs[0];
	float metPhi = inputs[1];
	float metPx = metPt*cos(metPhi);
	float metPy = metPt*sin(metPhi);
	float l1Pt = inputs[3];
	float l1Phi = inputs[4];
	float l1Eta = inputs[5];
	float l1Px = l1Pt*cos(l1Phi);
	float l1Py = l1Pt*sin(l1Phi);
	float l1Tanh = std::tanh(l1Eta);
	float l1Pz = l1Pt*l1Tanh / sqrt(1 - l1Tanh*l1Tanh);
	float l1E = sqrt(l1Pt*l1Pt + l1Pz*l1Pz);
	float l2Pt = inputs[6];
	float l2Phi = inputs[7];
	float l2Eta = inputs[8];
	float l2Px = l2Pt*cos(l2Phi);
	float l2Py = l2Pt*sin(l2Phi);
	float l2Tanh = std::tanh(l2Eta);
	float l2Pz = l2Pt*l2Tanh / sqrt(1 - l2Tanh*l2Tanh);
	float l2E = sqrt(l2Pt*l2Pt + l2Pz*l2Pz);
	float j1Pt = inputs[9];
	float j1Phi = inputs[10];
	float j1Eta = inputs[11];
	float j1Px = j1Pt*cos(j1Phi);
	float j1Py = j1Pt*sin(j1Phi);
	float j1Tanh = std::tanh(j1Eta);
	float j1Pz = j1Pt*j1Tanh / sqrt(1 - j1Tanh*j1Tanh);
	float j1E = sqrt(j1Pt*j1Pt + j1Pz*j1Pz);
	float j2Pt = inputs[12];
	float j2Phi = inputs[13];
	float j2Eta = inputs[14];
	float j2Px = j2Pt*cos(j2Phi);
	float j2Py = j2Pt*sin(j2Phi);
	float j2Tanh = std::tanh(j2Eta);
	float j2Pz = j2Pt*j2Tanh / sqrt(1 - j2Tanh*j2Tanh);
	float j2E = sqrt(j2Pt*j2Pt + j2Pz*j2Pz);

	//MT2(ll)
	float mt2ll = (float)asymm_mt2_lester_bisect::get_mT2(0, l1Px, l1Py, 0, l2Px, l2Py, metPx, metPy, 0, 0, 0.001);

	/*
	//MT2(blbl)
	float l1E = sqrt(l1Px*l1Px + l1Py*l1Py + l1Pz*l1Pz);
	float l2E = sqrt(l2Px*l2Px + l2Py*l2Py + l2Pz*l2Pz);
	float j1E = sqrt(j1Px*j1Px + j1Py*j1Py + j1Pz*j1Pz);
	float j2E = sqrt(j2Px*j2Px + j2Py*j2Py + j2Pz*j2Pz);
	float m1 = sqrt((l1E + j1E)*(l1E + j1E) - (l1Px + j1Px)*(l1Px + j1Px) - (l1Py + j1Py)*(l1Py + j1Py) - (l1Pz + j1Pz)*(l1Pz + j1Pz));
	float m2 = sqrt((l2E + j2E)*(l2E + j2E) - (l2Px + j2Px)*(l2Px + j2Px) - (l2Py + j2Py)*(l2Py + j2Py) - (l2Pz + j2Pz)*(l2Pz + j2Pz));
	//float mt2blbl = (float)asymm_mt2_lester_bisect::get_mT2(m1, l1Px + j1Px, l1Py + j1Py, m2, l2Px + j2Px, l2Py + j2Py, metPx, metPy, 0, 0, 0.001);
	float mt2blbl = (float)asymm_mt2_lester_bisect::get_mT2(0, l1Px + j1Px, l1Py + j1Py, 0, l2Px + j2Px, l2Py + j2Py, metPx, metPy, 0, 0, 0.001);

	//convFeatures.push_back(mt2blbl);
	*/

	//leptons only
	float q1Px = l1Px;
	float q1Py = l1Py;
	float q1Pz = l1Pz;
	float q1Pt = sqrt(pow(q1Px, 2) + pow(q1Py, 2));
	float q1E = l1E;
	float q2Px = l2Px;
	float q2Py = l2Py;
	float q2Pz = l2Pz;
	float q2Pt = sqrt(pow(q2Px, 2) + pow(q2Py, 2));
	float q2E = l2E;
	/*
	//megajets
	float q1Px = l1Px + j1Px;
	float q1Py = l1Py + j1Py;
	float q1Pz = l1Pz + j1Pz;
	float q1Pt = sqrt(pow(q1Px, 2) + pow(q1Py, 2));
	float q1E = l1E + j1E;
	float q2Px = l2Px + j2Px;
	float q2Py = l2Py + j2Py;
	float q2Pz = l2Pz + j2Pz;
	float q2Pt = sqrt(pow(q2Px, 2) + pow(q2Py, 2));
	float q2E = l2E + j2E;
	*/

	//Razor M_R
	float M_R = sqrt(pow(q1E + q2E, 2) - pow(q1Pz + q2Pz, 2));
	float M_TR = sqrt((metPt*(q1Pt + q2Pt) - metPx*(q1Px + q2Px) - metPy*(q1Py + q2Py)) / 2);
	float R_M2 = pow(M_TR / M_R, 2);

	//boost to longitudinal razor frame
	float beta_L = (q1Pz + q2Pz) / (q1E + q2E);
	float gamma_L = 1 / sqrt(1 - beta_L*beta_L);
	float q1E_L = gamma_L*(q1E - beta_L*q1Pz);
	float q1Px_L = q1Px;
	float q1Py_L = q1Py;
	float q1Pz_L = gamma_L*(q1Pz - beta_L*q1E);
	float q2E_L = gamma_L*(q2E - beta_L*q2Pz);
	float q2Px_L = q2Px;
	float q2Py_L = q2Py;
	float q2Pz_L = gamma_L*(q2Pz - beta_L*q2E);

	float m12sq = pow(q1E + q2E, 2) - pow(q1Px + q2Px, 2) - pow(q1Py + q2Py, 2) - pow(q1Pz + q2Pz, 2);
	float metE = sqrt(m12sq + metPx*metPx + metPy*metPy);

	//boost to super-razor frame (from L frame)
	float j_Tx = -metPx - q1Px - q2Px;
	float j_Ty = -metPy - q1Py - q2Py;
	float j_T = sqrt(j_Tx*j_Tx + j_Ty*j_Ty);
	float j_Tnx = j_Tx / j_T;
	float j_Tny = j_Ty / j_T;
	float s_R = 2 * (pow(M_R, 2) + j_Tx*(q1Px + q2Px) + j_Ty*(q1Py + q2Py) + M_R*sqrt(M_R*M_R + j_Tx*j_Tx + j_Ty*j_Ty + 2 * (j_Tx*(q1Px + q2Px) + j_Ty*(q1Py + q2Py))));
	float beta_R = -j_T / sqrt(s_R + pow(j_T, 2));
	float gamma_R = 1 / sqrt(1 - beta_R*beta_R);
	float q1E_R = gamma_R*(q1E_L - beta_R*q1Px_L*j_Tnx - beta_R*q1Py_L*j_Tny);
	float q1Px_R = ((1 + (gamma_R - 1)*j_Tnx*j_Tnx)*q1Px_L - beta_R*gamma_R*j_Tnx*q1E_L + (gamma_R - 1)*j_Tnx*j_Tny*q1Py_L);
	float q1Py_R = ((1 + (gamma_R - 1)*j_Tny*j_Tny)*q1Py_L - beta_R*gamma_R*j_Tny*q1E_L + (gamma_R - 1)*j_Tny*j_Tnx*q1Px_L);
	float q1Pz_R = q1Pz_L;
	float q2E_R = gamma_R*(q2E_L - beta_R*q2Px_L*j_Tnx - beta_R*q2Py_L*j_Tny);
	float q2Px_R = ((1 + (gamma_R - 1)*j_Tnx*j_Tnx)*q2Px_L - beta_R*gamma_R*j_Tnx*q2E_L + (gamma_R - 1)*j_Tnx*j_Tny*q2Py_L);
	float q2Py_R = ((1 + (gamma_R - 1)*j_Tny*j_Tny)*q2Py_L - beta_R*gamma_R*j_Tny*q2E_L + (gamma_R - 1)*j_Tny*j_Tnx*q2Px_L);
	float q2Pz_R = q2Pz_L;

	/*
	//boost to super-razor frame (from lab frame)
	float j_Tx = -metPx - q1Px - q2Px;
	float j_Ty = -metPy - q1Py - q2Py;
	float j_T = sqrt(j_Tx*j_Tx + j_Ty*j_Ty);
	float j_Tnx = j_Tx / j_T;
	float j_Tny = j_Ty / j_T;
	float s_R = 2 * (pow(M_R, 2) + j_Tx*(q1Px + q2Px) + j_Ty*(q1Py + q2Py) + M_R*sqrt(M_R*M_R + j_Tx*j_Tx + j_Ty*j_Ty + 2 * (j_Tx*(q1Px + q2Px) + j_Ty*(q1Py + q2Py))));
	float qSumPz = q1Pz + q2Pz;
	float pBoost = sqrt(j_T*j_T + qSumPz*qSumPz);
	float beta_R = pBoost / sqrt(pBoost*pBoost + s_R);
	float gamma_R = 1 / sqrt(1 - beta_R*beta_R);
	float nx_R = -j_Tx / pBoost;
	float ny_R = -j_Ty / pBoost;
	float nz_R = qSumPz / pBoost;
	float q1E_R = gamma_R*(q1E - beta_R*q1Px*nx_R - beta_R*q1Py*ny_R - beta_R*q1Pz*nz_R);
	float q1Px_R = (1 + (gamma_R - 1)*nx_R*nx_R)*q1Px - beta_R*gamma_R*nx_R*q1E + (gamma_R - 1)*nx_R*ny_R*q1Py + (gamma_R - 1)*nx_R*nz_R*q1Pz;
	float q1Py_R = (1 + (gamma_R - 1)*ny_R*ny_R)*q1Py - beta_R*gamma_R*ny_R*q1E + (gamma_R - 1)*ny_R*nx_R*q1Px + (gamma_R - 1)*ny_R*nz_R*q1Pz;
	float q1Pz_R = (1 + (gamma_R - 1)*nz_R*nz_R)*q1Pz - beta_R*gamma_R*nz_R*q1E + (gamma_R - 1)*nz_R*nx_R*q1Px + (gamma_R - 1)*nz_R*ny_R*q1Py;
	float q2E_R = gamma_R*(q2E - beta_R*q2Px*nx_R - beta_R*q2Py*ny_R - beta_R*q2Pz*nz_R);
	float q2Px_R = (1 + (gamma_R - 1)*nx_R*nx_R)*q2Px - beta_R*gamma_R*nx_R*q2E + (gamma_R - 1)*nx_R*ny_R*q2Py + (gamma_R - 1)*nx_R*nz_R*q2Pz;
	float q2Py_R = (1 + (gamma_R - 1)*ny_R*ny_R)*q2Py - beta_R*gamma_R*ny_R*q2E + (gamma_R - 1)*ny_R*nx_R*q2Px + (gamma_R - 1)*ny_R*nz_R*q2Pz;
	float q2Pz_R = (1 + (gamma_R - 1)*nz_R*nz_R)*q2Pz - beta_R*gamma_R*nz_R*q2E + (gamma_R - 1)*nz_R*nx_R*q2Px + (gamma_R - 1)*nz_R*ny_R*q2Py;
	*/

	//boost to decay frames
	float betaPx_R1 = (q1Px_R - q2Px_R) / (q1E_R + q2E_R);
	float betaPy_R1 = (q1Py_R - q2Py_R) / (q1E_R + q2E_R);
	float betaPz_R1 = (q1Pz_R - q2Pz_R) / (q1E_R + q2E_R);
	float beta_R1 = sqrt(pow(betaPx_R1, 2) + pow(betaPy_R1, 2) + pow(betaPz_R1, 2));
	float gamma_R1 = 1 / sqrt(1 - beta_R1*beta_R1);
	float M_deltaR = sqrt(s_R) / (2*gamma_R1);

	float q1dotM_L = q1E_L*metE - q1Px_L*metPx - q1Py_L*metPy;
	float q2dotM_L = q2E_L*metE - q2Px_L*metPx - q2Py_L*metPy;
	float M_deltaR_alt = sqrt((4 * q1dotM_L*q2dotM_L - pow(m12sq, 2)) / s_R);

	//R_pt
	float R_pt = j_T / (j_T + sqrt(s_R) / 4);

	//d_phiBR
	float qsumPx_R = q1Px_R + q2Px_R;
	float qsumPy_R = q1Py_R + q2Py_R;
	float qsumPz_R = q1Pz_R + q2Pz_R;
	float qsumPhi_R = atan2(qsumPy_R, qsumPx_R);
	float j_TPhi_R = atan2(-j_Ty, -j_Tx);
	float d_phiBR = fabs(j_TPhi_R - qsumPhi_R);
	if (d_phiBR > M_PI)
		d_phiBR = 2 * M_PI - d_phiBR;

	//cos \theta_(R+1) (note: based on megajets rather than leptons, if they are different)
	float costheta_R1 = sqrt(pow(q1E_R - q2E_R, 2) / (s_R / 4 - M_deltaR*M_deltaR));

	//m_delta
	float mS = 350;
	float mX = 200;
	float m_delta = (mS*mS - mX*mX) / mS;

	//cuts
	/*
	float feature = M_deltaR;
	if (R_pt <= 0.7)
		feature = 0;
	else if (1 / gamma_R1 <= 0.7)
		feature = 0;
	else if (d_phiBR <= 0.9*fabs(costheta_b) + 1.6)
		feature = 0;
		*/

	/*
	convFeatures.push_back(M_R);
	convFeatures.push_back(M_TR);
	convFeatures.push_back(R_M2);
	convFeatures.push_back(sqrt(s_R));
	*/
	//convFeatures.push_back(M_deltaR);
	//convFeatures.push_back(d_phiBR);

	convFeatures.push_back(mt2ll);
	return convFeatures;
}

float getCavemanVar(std::vector<float> inputs) {
	std::vector<float> weights = { 1.0f, 0.48f, 0.48f, 0.4f, 0.04f, 0.08f, 0.24f, 0.16f, 0.12f, 0.12f, 0.08f, 0, 0.04f, 0, 0.04f, -0.04f, 0.04f };
	std::vector<float> hardWeights(NUM_CAVEMAN_WEIGHTS);
	if (weights.size() != NUM_CAVEMAN_WEIGHTS)
		throw new std::runtime_error("Wrong number of caveman weights");

	float var = 0;
	var += weights[0] * inputs[0];	//MET
	var += weights[1] * inputs[11];	//MET-L2
	var += weights[2] * inputs[4];	//L2Pt
	var += weights[3] * inputs[10];	//MET-L1
	var += weights[4] * inputs[16];	//L1-J2
	var -= weights[5] * inputs[6];	//J1Pt
	var -= weights[6] * inputs[14];	//L1L2
	var += weights[7] * inputs[2];	//L1Pt
	var -= weights[8] * fabs(inputs[2] - 0.9*inputs[0]);	//L1Pt dependence on MET
	var -= weights[9] * inputs[18];	//L2-J2

	//L1Pt dependence on MET-L2
	if (inputs[11] < 0.7)
		var -= weights[10] * inputs[2];
	else if (inputs[11] < 1.07)
		var -= weights[11] * fabs(inputs[2] - (4 + 2 * (inputs[11] - 0.7) / 0.37));
	else if (inputs[11] < 1.238)
		var -= weights[10] * inputs[2];
	else if (inputs[11] < 2.18)
		var -= weights[12] * fabs(inputs[2] - (4 + 2 * (inputs[11] - 1.238) / (2.18 - 1.238)));
	else
		var += weights[13] * inputs[2];

	var -= weights[14] * inputs[12];	//MET-J1
	var += weights[15] * inputs[13];	//MET-J2
	if (inputs[2] < 5.3)	//MET-J2 dependence on L1Pt
		var -= weights[16] * fabs(inputs[13] - (2.33 + (3.14159 - 2.33)*(inputs[2] - 4.0f) / (6.0f - 4.0f)));

	return var;
}
