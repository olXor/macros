#pragma once
#include <vector>
#include <iostream>

struct PermutationArray {
	std::vector<size_t> indices;
	std::vector<int> directions;
};

bool iteratePermutation(PermutationArray* perm);
PermutationArray createPermutation(size_t numIndices);