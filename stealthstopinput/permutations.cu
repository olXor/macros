#include "permutations.cuh"

PermutationArray createPermutation(size_t numIndices) {
	PermutationArray perm;
	perm.indices.resize(numIndices);
	perm.directions.resize(numIndices);
	for (size_t i = 0; i < numIndices; i++) {
		perm.indices[i] = i + 1;
		if (i == 0)
			perm.directions[i] = 0;
		else
			perm.directions[i] = -1;
	}
	return perm;
}

bool iteratePermutation(PermutationArray* perm) {
	size_t maxMover = 0;
	size_t maxIndex = 0;	//index of index array :) confusing
	for (size_t i = 0; i < perm->indices.size(); i++) {
		if (perm->indices[i] > maxMover && perm->directions[i] != 0) {
			maxMover = perm->indices[i];
			maxIndex = i;
		}
	}
	if (maxMover == 0)
		return false;

	//swap max index in chosen direction
	if ((size_t)(maxIndex + perm->directions[maxIndex] >= perm->indices.size())) {
		std::cout << "Tried to swap permutation index out of bounds" << std::endl;
		throw new std::runtime_error("Tried to swap permutation index out of bounds");
	}

	size_t tmpVal = perm->indices[maxIndex];
	size_t tmpDir = perm->directions[maxIndex];
	size_t swapIndex = maxIndex + perm->directions[maxIndex];
	perm->indices[maxIndex] = perm->indices[swapIndex];
	perm->indices[swapIndex] = tmpVal;
	perm->directions[maxIndex] = perm->directions[swapIndex];
	perm->directions[swapIndex] = tmpDir;

	//set direction of swapped index to zero if it runs into the edge of the array or a larger index
	if (swapIndex == 0 || swapIndex == perm->indices.size() - 1 || perm->indices[swapIndex + perm->directions[swapIndex]] > perm->indices[swapIndex])
		perm->directions[swapIndex] = 0;

	//set all indices greater than the swapped index to move towards the swapped index
	for (size_t i = 0; i < perm->indices.size(); i++) {
		if (perm->indices[i] > perm->indices[swapIndex]) {
			if (i < swapIndex)
				perm->directions[i] = 1;
			else
				perm->directions[i] = -1;
		}
	}

	return true;
}