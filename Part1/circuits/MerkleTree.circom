pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom"; // 두개의 input을 받고, selector(mux[i].s)를 기반으로 하나를 리턴하는 component

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves

    // Leaf 들의 중간 값을 저장
    signal intermediate[2**n-1];

    // 첫번째 layer에 leaf들을 assign
    for (var i = 0; i < 2**n; i++) {
        intermediate[i] = leaves[i];
    }

    for(var level = 0; level < n; level++){
        var levelSize = 2**(n-level-1);
        var halfSize = levelSize \ 2;

        for(var i = 0; i < levelSize; i++){
            intermediate[i] = Poseidon([intermediate[2*i], intermediate[2*i+1]]);
        }

    }
     root <== intermediate[0];
    }

template MerkleTreeInclusionProof(nLevels) {
    signal input leaf; // Merkle Tree에서 증명하고자 하는 리프 노드. 특정 데이터를 나타냄.
    signal input pathIndices[nLevels]; // 각 레벨에서 리프가 형제 노드와의 관계에서 왼쪽(0) vs 오른쪽(1)에 있는지를 나타내는 배열.
    signal input siblings[nLevels]; // 각 레벨에서 리프 노드와 비교/결합 될 형제 노드들의 해시값을 나타내는 배열. 해당 값들로 부모 노드의 해시값을 계산.

    signal output root; // Root 해시값. 리프 노드로부터 계산한 해시 값과 일치하면 특정 Leaf가 Merkle Tree에 있다는 것.
    
    // Poseidon 및 Mux 해시 함수 컴포넌트를 배열로 선언.
    component poseidons[nLevels];
    component mux[nLevels];

    signal hashes[nLevels + 1]; // 각 레벨에서 계산된 해시값을 저장하는 hash 배열. 마지막 인덱스는 root 해시 값을 저장.
    hashes[0] <== leaf; // hash 배열의 첫번째 값은 leaf로 초기화.

    for (var i = 0; i < nLevels; i++) {
		    
		    // pathIndices[i]은 1 혹은 0 이어야함. 
        pathIndices[i] * (1 - pathIndices[i]) === 0;

        poseidons[i] = Poseidon(2); // 2개의 입력을 받아 해시화.
        mux[i] = MultiMux1(2); // 2개의 입력중 하나를 선택하는 selector기반으로 하나를 리턴. 
				
				// Case. 1 pathIndices[i] === 0 이면, 
				// mux[i].out[0] == hashes[i]
				// mux[i].out[1] == siblings[i]
        mux[i].c[0][0] <== hashes[i]; //??
        mux[i].c[0][1] <== siblings[i]; // 여기서부터 어떻게 돌아가는건지 모르겠음.
				
				// Case. 2 pathIndices[i] === 1 이면,
				// mux[i].out[0] == siblings[i]
				// mux[i].out[1] == hashes[i]
        mux[i].c[1][0] <== siblings[i];
        mux[i].c[1][1] <== hashes[i];

        mux[i].s <== pathIndices[i];
				
        poseidons[i].inputs[0] <== mux[i].out[0];
        poseidons[i].inputs[1] <== mux[i].out[1];

        hashes[i + 1] <== poseidons[i].out;
    }

    root <== hashes[nLevels];
}