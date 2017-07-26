#include <iostream>
#include <string>
#include <ctime>
#include <fstream>
#include <vector>
#include <sstream>
#include <chrono>

struct DataPoint {
	float value;
	int time;
};

std::chrono::system_clock::time_point markedStartTime;
void throwError(std::string err);
void markTime();
long long getTimeSinceMark();

int convertTime(std::string str);
std::string timeToStr(int time);
float getSpline(float left, float right, float leftderiv, float rightderiv, float place);
float evaluateWindow(std::vector<DataPoint>* truthwindow, std::vector<DataPoint>* predictwindow, int offset, float averageWidth, float truthNormalizeFactor, float predictNormalizeFactor);
float getNormalizeFactor(std::vector<DataPoint>* window, float averageWidth);
bool readWindow(std::ifstream* file, size_t start, size_t end, size_t* lineNum, float windowTime, std::vector<DataPoint>* truthwindow, std::vector<DataPoint>* predictwindow, size_t predictcol);

int main() {
	std::string fname;
	std::cout << "Enter name of combined artline-sensor file: ";
	std::cin >> fname;

	size_t predictcol;
	std::cout << "Enter prediction column number: ";
	std::cin >> predictcol;

	float windowTime;
	std::cout << "Enter window length (in s): ";
	std::cin >> windowTime;

	size_t intervalsBetweenSync;
	std::cout << "Enter the number of windows between syncs (use 0 for infinity): ";
	std::cin >> intervalsBetweenSync;

	size_t start;
	size_t end;
	std::cout << "Enter start line: ";
	std::cin >> start;
	std::cout << "Enter end line (0 for whole file): ";
	std::cin >> end;

	float maxOffset;
	float offsetComb;
	std::cout << "Enter max offest (in s): ";
	std::cin >> maxOffset;
	std::cout << "Enter offset comb size (in ms): ";
	std::cin >> offsetComb;

	float avgWidth;
	std::cout << "Enter width of the baseline moving average (in s): ";
	std::cin >> avgWidth;

	int maxOffsetMS = (int)fabs(maxOffset * 1000);
	int offsetCombMS = (int)fabs(offsetComb);

	std::vector<DataPoint> truthwindow;
	std::vector<DataPoint> predictwindow;
	std::ifstream file(fname);
	std::string dum;
	std::getline(file, dum);	//header

	size_t line = 1;
	size_t intNum = 0;
	while (readWindow(&file, start, end, &line, windowTime, &truthwindow, &predictwindow, predictcol)) {
		intNum++;
		float maxR2 = -9999;
		int bestOffset = 0;
		float truthNormalizeFactor = getNormalizeFactor(&truthwindow, avgWidth);
		float predictNormalizeFactor = getNormalizeFactor(&predictwindow, avgWidth);
		for (int off = -maxOffsetMS; off < maxOffsetMS; off += offsetCombMS) {
			float r2 = evaluateWindow(&truthwindow, &predictwindow, off, avgWidth, truthNormalizeFactor, predictNormalizeFactor);
			if (r2 > maxR2) {
				maxR2 = r2;
				bestOffset = off;
			}
		}
		std::cout << "Interval " << intNum << " best offset: " << bestOffset << " at " << maxR2 << " | ";

		for (size_t i = 0; intervalsBetweenSync == 0 || i < intervalsBetweenSync && readWindow(&file, start, end, &line, windowTime, &truthwindow, &predictwindow, predictcol); i++) {
			float r2 = evaluateWindow(&truthwindow, &predictwindow, bestOffset, avgWidth, truthNormalizeFactor, predictNormalizeFactor);
			std::cout << r2 << " ";
		}
		std::cout << std::endl;
	}

	system("pause");
}

void throwError(std::string err) {
	std::cout << err << std::endl;
	throw std::runtime_error(err);
}

void markTime() {
	markedStartTime = std::chrono::high_resolution_clock::now();
}

long long getTimeSinceMark() {
	auto elapsed = std::chrono::high_resolution_clock::now() - markedStartTime;
	long long time = std::chrono::duration_cast<std::chrono::microseconds>(elapsed).count();
	return time / 1000000;
}

int convertTime(std::string str) {
	int hour = 0;
	int minute = 0;
	int second = 0;
	int msecond = 0;
	char dum;
	std::string pm;

	std::stringstream strs;
	strs << str;
	strs >> hour;
	strs >> dum;	//":"
	strs >> minute;
	strs >> dum;	//":"
	strs >> second;
	strs >> dum;	//"."
	strs >> msecond;

	int time = 3600000 * hour + 60000 * minute + 1000*second + msecond;

	return time;
}
std::string timeToStr(int time) {
	if (time < 0)
		return "0";
	std::stringstream ss;
	ss << time / 3600000 << ":";
	time = time - 3600000 * (time / 3600000);
	ss << time / 60000 << ":";
	time = time - 60000 * (time / 60000);
	ss << time / 1000 << ".";
	time = time - 1000 * (time / 1000);
	return ss.str();
}

bool readWindow(std::ifstream* file, size_t start, size_t end, size_t* lineNum, float windowTime, std::vector<DataPoint>* truthwindow, std::vector<DataPoint>* predictwindow, size_t predictcol) {
	truthwindow->clear();
	predictwindow->clear();

	std::string line;
	while ((*lineNum) < start && std::getline((*file), line)) {
		(*lineNum)++;
	}

	int startTime = 0;
	while ((end == 0 || (*lineNum) <= end)) {
		if (!std::getline((*file), line))
			return false;
		int time;
		std::string dum;

		std::stringstream lss(line);
		std::string tok;
		std::getline(lss, tok, ',');
		time = convertTime(tok);
		if (startTime == 0)
			startTime = time;
		else if (time > startTime + (int)(windowTime * 1000))
			break;

		for (size_t c = 0; c < predictcol; c++)
			std::getline(lss, tok, ',');

		if (tok != "") {
			float predictvalue;
			std::stringstream tss;
			tss.str(tok);
			tss >> predictvalue;
			DataPoint pt;
			pt.value = predictvalue;
			pt.time = time;
			predictwindow->push_back(pt);
		}

		for (size_t c = predictcol; c < 4; c++)
			std::getline(lss, tok, ',');

		std::getline(lss, tok, ',');	//pTime
		std::getline(lss, tok, ',');	//aTime

		std::getline(lss, tok, ',');
		if (tok != "") {
			float truthvalue;
			std::stringstream tss;
			tss.str(tok);
			tss >> truthvalue;
			DataPoint pt;
			pt.value = truthvalue;
			pt.time = time;
			truthwindow->push_back(pt);
		}
		*lineNum++;
	}

	if (end != 0 && *lineNum > end)
		return false;
	return true;
}

float getSpline(float left, float right, float leftderiv, float rightderiv, float place) {
	float a = leftderiv - (right - left);
	float b = -rightderiv + (right - left);
	return (1 - place)*left + place*right + place*(1 - place)*(a*(1 - place) + b*place);
}

float getNormalizeFactor(std::vector<DataPoint>* window, float averageWidth) {
	float maxD = -9999;
	float minD = 9999;

	size_t leftAvgEdge = 0;
	size_t rightAvgEdge = 0;
	float avgTot = 0;
	int msAvgW = (int)fabs(averageWidth * 1000);
	size_t numAvgPts = 0;

	for (size_t i = 0; i < window->size(); i++) {
		int time = (*window)[i].time;
		while (rightAvgEdge < window->size() && (*window)[rightAvgEdge].time <= time + msAvgW) {
			avgTot += (*window)[rightAvgEdge].value;
			numAvgPts++;
			rightAvgEdge++;
		}
		while (leftAvgEdge < window->size() && (*window)[leftAvgEdge].time < time - msAvgW) {
			avgTot -= (*window)[leftAvgEdge].value;
			numAvgPts--;
			leftAvgEdge++;
		}

		float dev = (*window)[i].value - avgTot / numAvgPts;

		if (dev > maxD)
			maxD = dev;
		if (dev < minD)
			minD = dev;
	}

	if (maxD <= minD)
		return 0.0f;
	return 1.0f / (maxD - minD);
}

float evaluateWindow(std::vector<DataPoint>* truthwindow, std::vector<DataPoint>* predictwindow, int offset, float averageWidth, float truthNormalizeFactor, float predictNormalizeFactor) {
	float squaredResidues = 0;
	size_t numMatchedPoints = 0;
	float truthMatchedAvg = 0;
	float truthMatchedSquares = 0;

	size_t nextPredict = 0;

	size_t leftTruthAvgEdge = 0;
	size_t rightTruthAvgEdge = 0;
	float truthAvgTot = 0;
	int msAvgW = (int)fabs(averageWidth * 1000);
	size_t numTruthAvgPts = 0;
	size_t leftPredictAvgEdge = 0;
	size_t rightPredictAvgEdge = 0;
	float predictAvgTot = 0;
	size_t numPredictAvgPts = 0;
	for (size_t i = 0; i < truthwindow->size(); i++) {
		//calculate moving averages
		int time = (*truthwindow)[i].time;
		while (rightTruthAvgEdge < truthwindow->size() && (*truthwindow)[rightTruthAvgEdge].time <= time + msAvgW) {
			truthAvgTot += (*truthwindow)[rightTruthAvgEdge].value;
			numTruthAvgPts++;
			rightTruthAvgEdge++;
		}
		while (leftTruthAvgEdge < truthwindow->size() && (*truthwindow)[leftTruthAvgEdge].time < time - msAvgW) {
			truthAvgTot -= (*truthwindow)[leftTruthAvgEdge].value;
			numTruthAvgPts--;
			leftTruthAvgEdge++;
		}
		while (rightPredictAvgEdge < predictwindow->size() && (*predictwindow)[rightPredictAvgEdge].time + offset <= time + msAvgW) {
			predictAvgTot += (*predictwindow)[rightPredictAvgEdge].value;
			numPredictAvgPts++;
			rightPredictAvgEdge++;
		}
		while (leftPredictAvgEdge < predictwindow->size() && (*predictwindow)[leftPredictAvgEdge].time + offset < time - msAvgW) {
			predictAvgTot -= (*predictwindow)[leftPredictAvgEdge].value;
			numPredictAvgPts--;
			leftPredictAvgEdge++;
		}

		while (nextPredict < predictwindow->size() && (*predictwindow)[nextPredict].time + offset <= time) {
			nextPredict++;
		}
		if (nextPredict >= predictwindow->size())
			break;

		if (nextPredict > 0) {
			float leftderiv;
			float predictTimeWidth = (*predictwindow)[nextPredict].time - (*predictwindow)[nextPredict - 1].time;
			if (nextPredict - 1 == 0)
				leftderiv = ((*predictwindow)[1].value - (*predictwindow)[0].value) / ((*predictwindow)[1].time - (*predictwindow)[0].time) * predictTimeWidth;
			else
				leftderiv = ((*predictwindow)[nextPredict].value - (*predictwindow)[nextPredict - 2].value) / ((*predictwindow)[nextPredict].time - (*predictwindow)[nextPredict - 2].time) * predictTimeWidth;

			float rightderiv;
			if (nextPredict == predictwindow->size() - 1)
				rightderiv = ((*predictwindow)[nextPredict].value - (*predictwindow)[nextPredict - 1].value) / ((*predictwindow)[nextPredict].time - (*predictwindow)[nextPredict - 1].time) * predictTimeWidth;
			else
				rightderiv = ((*predictwindow)[nextPredict + 1].value - (*predictwindow)[nextPredict - 1].value) / ((*predictwindow)[nextPredict + 1].time - (*predictwindow)[nextPredict - 1].time) * predictTimeWidth;

			float place = (time - offset - (*predictwindow)[nextPredict - 1].time) / ((*predictwindow)[nextPredict].time - (*predictwindow)[nextPredict - 1].time);
			float predictvalue = getSpline((*predictwindow)[nextPredict - 1].value, (*predictwindow)[nextPredict].value, leftderiv, rightderiv, place);
			float predictdev = predictNormalizeFactor*(predictvalue - predictAvgTot / numPredictAvgPts);
			float truthdev = truthNormalizeFactor*((*truthwindow)[i].value - truthAvgTot / numTruthAvgPts);

			float unsquare = truthdev - predictdev;
			squaredResidues += unsquare*unsquare;
			numMatchedPoints++;
			truthMatchedAvg += truthdev;
			truthMatchedSquares += truthdev*truthdev;
		}
	}

	squaredResidues /= numMatchedPoints;
	truthMatchedAvg /= numMatchedPoints;
	truthMatchedSquares /= numMatchedPoints;
	float truthVariance = truthMatchedSquares - truthMatchedAvg*truthMatchedAvg;

	return 1.0f - squaredResidues / truthVariance;
}