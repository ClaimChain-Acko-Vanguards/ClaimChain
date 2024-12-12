// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

library ClaimUtils {
    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function isEmptyString(string memory str) internal pure returns (bool) {
        return bytes(str).length == 0;
    }

    function isEmptyBytes32(bytes32 value) internal pure returns (bool) {
        return value == bytes32(0);
    }
} 