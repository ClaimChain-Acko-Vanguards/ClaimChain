// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

contract ClaimStorage {
    struct ClaimData {
        string claim_id;
        string policy_type;
        address claimant;
        uint256 verificationDate;
    }

    mapping(string => ClaimData) private claims;

    function storeClaim(
        string memory claim_id,
        string memory policy_type,
        address claimant,
        uint256 verificationDate
    ) external {
        claims[claim_id] = ClaimData({
            claim_id: claim_id,
            policy_type: policy_type,
            claimant: claimant,
            verificationDate: verificationDate
        });
    }

    function getClaim(string memory claim_id) external view returns (ClaimData memory) {
        return claims[claim_id];
    }
} 