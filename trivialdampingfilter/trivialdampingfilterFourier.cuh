#pragma once
#include "math.h"
#include <vector>

#define MATH_PI 3.14159265358979323846

/**
* C++ implementation of FFT
*
* Source: http://paulbourke.net/miscellaneous/dft/
*/

/*
This computes an in-place complex-to-complex FFT
x and y are the real and imaginary arrays of 2^m points.
dir =  1 gives forward transform
dir = -1 gives reverse transform
*/
inline void FFT(short int dir, long m, float *x, float *y)
{
	long n, i, i1, j, k, i2, l, l1, l2;
	float c1, c2, tx, ty, t1, t2, u1, u2, z;

	/* Calculate the number of points */
	n = 1;
	for (i = 0; i<m; i++)
		n *= 2;

	/* Do the bit reversal */
	i2 = n >> 1;
	j = 0;
	for (i = 0; i<n - 1; i++) {
		if (i < j) {
			tx = x[i];
			ty = y[i];
			x[i] = x[j];
			y[i] = y[j];
			x[j] = tx;
			y[j] = ty;
		}
		k = i2;
		while (k <= j) {
			j -= k;
			k >>= 1;
		}
		j += k;
	}

	/* Compute the FFT */
	c1 = -1.0;
	c2 = 0.0;
	l2 = 1;
	for (l = 0; l<m; l++) {
		l1 = l2;
		l2 <<= 1;
		u1 = 1.0;
		u2 = 0.0;
		for (j = 0; j<l1; j++) {
			for (i = j; i<n; i += l2) {
				i1 = i + l1;
				t1 = u1 * x[i1] - u2 * y[i1];
				t2 = u1 * y[i1] + u2 * x[i1];
				x[i1] = x[i] - t1;
				y[i1] = y[i] - t2;
				x[i] += t1;
				y[i] += t2;
			}
			z = u1 * c1 - u2 * c2;
			u2 = u1 * c2 + u2 * c1;
			u1 = z;
		}
		c2 = sqrt((1.0 - c1) / 2.0);
		if (dir == 1)
			c2 = -c2;
		c1 = sqrt((1.0 + c1) / 2.0);
	}

	/* Scaling for forward transform */
	if (dir == 1) {
		for (i = 0; i<n; i++) {
			x[i] /= n;
			y[i] /= n;
		}
	}
}

#define FOURIER_FIT_SQUARE_NORM true
float calculateBWFit(float in, float cor, std::vector<float>* coef, std::vector<float>* deriv, std::vector<double>* absderiv) {
	if (coef->size() != 9 || (deriv != NULL && deriv->size() != 9))
		return 0;
	float val = 0;

	//exponential
	val += (*coef)[0] * exp(-(*coef)[1] * in);

	//Damping Gaussian (amplitude scales with 1/sqrt(mean))
	float mean = (*coef)[2];
	float sigma = (*coef)[3];
	float mag = (*coef)[4];
	float prefactor = 1.0f / sqrt(mean);// 1 / sqrt(2 * MATH_PI*sigma*sigma);
	float exponent = -(in - mean)*(in - mean) / (2 * sigma*sigma);
	float exponential = exp(exponent);
	val += mag*prefactor*exponential;

	//Constant
	val += (*coef)[5];

	//Feature Gaussian (amplitude scales with 1/sqrt(mean))
	float featureMean = (*coef)[6];
	float featureSigma = (*coef)[7];
	float featureMag = (*coef)[8];
	float featurePrefactor = 1.0f / sqrt(mean);// 1 / sqrt(2 * MATH_PI*sigma*sigma);
	float featureExponent = -(in - featureMean)*(in - featureMean) / (2 * featureSigma*featureSigma);
	float featureExponential = exp(featureExponent);
	val += featureMag*featurePrefactor*featureExponential;

	if (deriv != NULL) {
		float d = (cor - val)*(exp(-(*coef)[1] * in));
		(*deriv)[0] += d;
		if (FOURIER_FIT_SQUARE_NORM)
			(*absderiv)[0] += d*d;
		else
			(*absderiv)[0] += fabs(d);

		d = (cor - val)*(-(*coef)[0] * in*exp(-(*coef)[1] * in));
		(*deriv)[1] += d;
		if (FOURIER_FIT_SQUARE_NORM)
			(*absderiv)[1] += d*d;
		else
			(*absderiv)[1] += fabs(d);

		//d = (cor - val)*(mag*(in - mean)*exponential / (sqrt(2 * MATH_PI)*fabs(sigma*sigma*sigma)));
		d = (cor - val)*((mag*(in - mean)*exponential / (sqrt(mean)*sigma*sigma)) - exponential / (2 * mean*sqrt(mean)));
		(*deriv)[2] += d;
		if (FOURIER_FIT_SQUARE_NORM)
			(*absderiv)[2] += d*d;
		else
			(*absderiv)[2] += fabs(d);

		//d = (cor - val)*(-mag*exponential*(sigma*sigma - (in - mean)*(in - mean)) / (sqrt(2 * MATH_PI)*sigma*sigma*sigma*fabs(sigma)));
		d = (cor - val)*(mag*(in - mean)*(in - mean)*exponential / (sqrt(mean)*sigma*sigma*sigma));
		(*deriv)[3] += d;
		if (FOURIER_FIT_SQUARE_NORM)
			(*absderiv)[3] += d*d;
		else
			(*absderiv)[3] += fabs(d);

		d = (cor - val)*prefactor*exponential;
		(*deriv)[4] += d;
		if (FOURIER_FIT_SQUARE_NORM)
			(*absderiv)[4] += d*d;
		else
			(*absderiv)[4] += fabs(d);

		d = (cor - val);
		(*deriv)[5] += d;
		if (FOURIER_FIT_SQUARE_NORM)
			(*absderiv)[5] += d*d;
		else
			(*absderiv)[5] += fabs(d);

		d = (cor - val)*((featureMag*(in - featureMean)*featureExponential / (sqrt(featureMean)*featureSigma*featureSigma)) - featureExponential / (2 * featureMean*sqrt(featureMean)));
		(*deriv)[6] += d;
		if (FOURIER_FIT_SQUARE_NORM)
			(*absderiv)[6] += d*d;
		else
			(*absderiv)[6] += fabs(d);

		d = (cor - val)*(featureMag*(in - featureMean)*(in - featureMean)*featureExponential / (sqrt(featureMean)*featureSigma*featureSigma*featureSigma));
		(*deriv)[7] += d;
		if (FOURIER_FIT_SQUARE_NORM)
			(*absderiv)[7] += d*d;
		else
			(*absderiv)[7] += fabs(d);

		d = (cor - val)*featurePrefactor*featureExponential;
		(*deriv)[8] += d;
		if (FOURIER_FIT_SQUARE_NORM)
			(*absderiv)[8] += d*d;
		else
			(*absderiv)[8] += fabs(d);
	}

	return val;
}

#define FOURIER_FIT_ITERATIONS 5000
#define FOURIER_FIT_STEP 0.3
#define FOURIER_FIT_STEPDOWN 0.9995
#define FOURIER_FEATURE_SWITCH_ON 100
inline void fourierBWFit(float* in, float* out, std::vector<float>* coef, size_t numPoints) {
	coef->clear();
	coef->resize(9);
	(*coef)[0] = 0.0f;
	(*coef)[1] = 0.0f;
	(*coef)[2] = 60.0f;
	(*coef)[3] = 10.0f;
	(*coef)[4] = 1.0f;
	(*coef)[5] = 0.0f;
	(*coef)[6] = 20.0f;
	(*coef)[7] = 10.0f;
	std::vector<float> deriv(9);
	std::vector<double> absderiv(9);

	float step = FOURIER_FIT_STEP;
	for (size_t iter = 0; iter < FOURIER_FIT_ITERATIONS; iter++) {
		if (iter < FOURIER_FEATURE_SWITCH_ON) {
			(*coef)[8] = 0.0f;
		}
		else if (iter == FOURIER_FEATURE_SWITCH_ON) {
			(*coef)[8] = 1.0f;
		}
		deriv.clear();
		deriv.resize(9);
		absderiv.clear();
		absderiv.resize(9);
		for (size_t i = 0; i < numPoints; i++) {
			out[i] = calculateBWFit((float)i, in[i], coef, &deriv, &absderiv);
		}
		for (size_t i = 0; i < coef->size(); i++) {
			float locDeriv = deriv[i];
			float locAbsDeriv = absderiv[i];
			double denom;
			if (FOURIER_FIT_SQUARE_NORM)
				denom = numPoints * (sqrt(absderiv[i] / numPoints));
			else
				denom = absderiv[i];
			if (denom > 0)
				(*coef)[i] += step*deriv[i] / denom;
		}
		if ((*coef)[0] < 0)
			(*coef)[0] = 0;
		if ((*coef)[1] < 0.001)
			(*coef)[1] = 0.001;
		if ((*coef)[2] < 40.0f)
			(*coef)[2] = 40.0f;
		else if ((*coef)[2] > numPoints)
			(*coef)[2] = numPoints;
		if ((*coef)[3] < 1.0f)
			(*coef)[3] = 1.0f;
		if ((*coef)[4] < 0)
			(*coef)[4] = 0;
		/*
		if ((*coef)[5] > 0.1)
		(*coef)[5] = 0.1;
		if ((*coef)[5] < -0.1)
		(*coef)[5] = -0.1;
		*/
		if ((*coef)[6] < 0)
			(*coef)[6] = 0;
		else if ((*coef)[6] > 30.0f)
			(*coef)[6] = 30.0f;
		if ((*coef)[7] < 1.0f)
			(*coef)[7] = 1.0f;
		if ((*coef)[7] > 15.0f)
			(*coef)[7] = 15.0f;
		if ((*coef)[8] < 0)
			(*coef)[8] = 0;

		step *= FOURIER_FIT_STEPDOWN;
	}
}