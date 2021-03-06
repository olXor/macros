#pragma once
#include <vector>

float getSpline(float left, float right, float leftderiv, float rightderiv, float place) {
	float a = leftderiv - (right - left);
	float b = -rightderiv + (right - left);
	return (1 - place)*left + place*right + place*(1 - place)*(a*(1 - place) + b*place);
}

inline void interpolate(std::vector<float>* in, std::vector<float>* out, float trueOutSize) {
	if (in->size() == 0)
		return;
	std::vector<float> inDerivs(in->size());
	for (size_t i = 0; i < in->size(); i++) {
		if (i == 0)
			inDerivs[i] = (*in)[i + 1] - (*in)[i];
		else if (i == in->size() - 1)
			inDerivs[i] = (*in)[i] - (*in)[i - 1];
		else
			inDerivs[i] = ((*in)[i + 1] - (*in)[i - 1]) / 2;
	}

	for (size_t i = 0; i < out->size(); i++) {
		float origpoint = 1.0f*i*(in->size() - 1) / (trueOutSize - 1);
		size_t origindex = (size_t)origpoint;
		if (origindex >= in->size() - 1)
			origindex = in->size() - 2;
		float remainder = origpoint - (float)origindex;

		(*out)[i] = getSpline((*in)[origindex], (*in)[origindex + 1], inDerivs[origindex], inDerivs[origindex + 1], remainder);
	}
}