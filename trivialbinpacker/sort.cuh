#pragma once
#include <vector>
template <typename T> void randomizeVector(std::vector<T>* vec) {
	for (size_t i = 0; i < vec->size(); i++) {
		size_t j = (RAND_MAX*rand() + rand()) % vec->size();
		T tmp = (*vec)[i];
		(*vec)[i] = (*vec)[j];
		(*vec)[j] = tmp;
	}
}

template <typename T> void swap(std::vector<T>* A, size_t i, size_t j) {
	T tmp = (*A)[i];
	(*A)[i] = (*A)[j];
	(*A)[j] = tmp;
}

template <typename T> T median(T a, T b, T c) {
	return max(min(a, b), min(max(a, b), c));
}

template <typename T> void quicksort(std::vector<T>* A, size_t lo, size_t hi) {
	if (lo >= hi)
		return;
	T pivot = median((*A)[lo], (*A)[hi], (*A)[(lo + hi) / 2]);
	size_t i = lo - 1;
	size_t j = hi + 1;
	while (true) {
		do {
			i++;
		} while (i <= hi && (*A)[i] < pivot);
		do{
			j--;
		} while (j >= lo && (*A)[j] > pivot);
		if (i >= j)
			break;
		swap(A, i, j);
	}
	quicksort(A, lo, j);
	quicksort(A, j + 1, hi);
}

template <typename T> void sortVector(std::vector<T>* A, size_t lo = 0, size_t hi = 0) {
	if (A->size() == 0)
		return;
	if (hi == 0)
		hi = A->size() - 1;
	quicksort(A, lo, hi);
}
