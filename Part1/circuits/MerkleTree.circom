pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves

    // Leaf 들의 중간 값을 저장
    signal intermediate[2**n-1]

    // 첫번째 layer에 leaf들을 assign
    for (var i = 0; i < 2**n; i++) {
        intermediate[i] = leaves[i];
    }

    // 각 레벨별로 hashing
    var offset = 0;
    for (var level = 0; level < n; level++) {
        var numNodes = 2**(n - level - 1); // 현 레벨의 노드 개수

        for (var i = 0; i < numNodes; i++) {
            // Poseidon을 사용해서 두 child node의 해시값을 계산
            intermediate[offset + numNodes + i] = poseidon([intermediate[offset + 2*i], intermediate[offset + 2*i + 1]])
        }
    }
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    // Initial hash는 leaf 에서부터 시작.
    signal hash = leaf;

    // 각 레벨별로 for-loop을 실행
    for (var i = 0; i < n; i++) {
        // 가르키는 element가 오른쪽에 있는지 왼쪽에 있는지 확인
        if (path_index[i] == 0) {
            hash = poseidon([hash, path_elements[i]]); // 왼쪽에 있는경우
        } else {
            hash = poseidon([path_elements[i], hash]); // 오른쪽에 있는경우
        }
    }

    // 해시 값 비교
    root === hash; // Poseidon 해시 값이 주어진 해시 값과 같은지 확인
}