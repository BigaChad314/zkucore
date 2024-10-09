//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Groth16Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        // 초기 8개의 리프 노드를 0으로 설정 후 해시
        for (uint256 i = 0; i < 8; i++) {
            hashes.push(PoseidonT3.poseidon([uint256(0), uint256(0)])); // 리프 노드 0 해시값
        }

        // 부모 노드들 계산 (3 레벨이므로)
        uint256 levelSize = 8; // 첫 레벨 리프 개수
        uint256 nodeIndex = 0; // 현재 노드 인덱스

        // 부모 레벨 해시 생성 (위쪽으로)
        while (levelSize > 1) {
            for (uint256 i = 0; i < levelSize; i += 2) {
                hashes.push(PoseidonT3.poseidon([hashes[nodeIndex + i], hashes[nodeIndex + i + 1]]));
            }
            nodeIndex += levelSize;
            levelSize /= 2;
        }
        
        // 루트 설정
        root = hashes[hashes.length - 1];
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        require(index < 8, "Tree is full"); // 트리가 꽉 찼는지 확인
    
        // 새로운 리프 추가
        hashes[index] = hashedLeaf;

        // 상위 노드 갱신
        uint256 currentIndex = index;
        uint256 currentLevelSize = 8; // 첫 레벨 크기
        uint256 offset = 0;

        while (currentLevelSize > 1) {
            uint256 siblingIndex = currentIndex % 2 == 0 ? currentIndex + 1 : currentIndex - 1;
            uint256 parentIndex = currentLevelSize + offset + currentIndex / 2;

            // 부모 노드 갱신
            hashes[parentIndex] = PoseidonT3.poseidon([hashes[currentIndex], hashes[siblingIndex]]);

            // 다음 레벨로
            currentIndex /= 2;
            currentLevelSize /= 2;
            offset += currentLevelSize;
        }

        // 루트 갱신
        root = hashes[hashes.length - 1];
        index++; // 인덱스 갱신

        return root;
    }

    function verify(
            uint[2] calldata a,
            uint[2][2] calldata b,
            uint[2] calldata c,
            uint[1] calldata input
        ) public view returns (bool) {

        // [assignment] verify an inclusion proof and check that the proof root matches current root
        // 증명된 루트가 현재 루트와 일치하는지 확인
        return (input[0] == root && Groth16Verifier.verifyProof(a, b, c, input));
    }
}
