// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {UserData, BaseClaimInfo, AutoClaimInfo, HealthClaimInfo, LifeClaimInfo} from "./UserData.sol";
import "./ClaimVerification.sol";
import "./ClaimUtils.sol";
import "./interfaces/IClaimTypes.sol";

contract QueryInfo {
    using ClaimUtils for string;
    using ClaimUtils for bytes32;

    UserData private userDataContract;
    ClaimVerification private claimVerificationContract;
    
    // Query mappings
    mapping(string => string[]) private emailToClaims;
    mapping(string => string[]) private aadharToClaims;
    mapping(string => string[]) private vehicleRegToClaims;
    mapping(string => string[]) private userPhoneToClaims;

    struct ClaimResponse {
        string claim_id;
        string policy_type;
        address claimant;
        uint256 submissionDate;
    }
    
    constructor(address _userDataContract, address _claimVerificationContract) {
        userDataContract = UserData(_userDataContract);
        claimVerificationContract = ClaimVerification(_claimVerificationContract);
    }

    function getClaims(
        string calldata searchParam,
        string calldata searchType
    ) external view returns (ClaimResponse[] memory) {
        if (searchParam.isEmptyString()) {
            return new ClaimResponse[](0);
        }

        string[] storage relevantClaimIds;
        
        if (searchType.compareStrings("PHONE")) {
            relevantClaimIds = userPhoneToClaims[searchParam];
        } 
        else if (searchType.compareStrings("EMAIL")) {
            relevantClaimIds = emailToClaims[searchParam];
        }
        else if (searchType.compareStrings("AADHAR")) {
            relevantClaimIds = aadharToClaims[searchParam];
        }
        else if (searchType.compareStrings("VEHICLE")) {
            relevantClaimIds = vehicleRegToClaims[searchParam];
        }
        else {
            revert("Invalid search type");
        }

        return buildClaimResponses(relevantClaimIds);
    }

    function buildClaimResponses(string[] storage claimIds) private view returns (ClaimResponse[] memory) {
        ClaimResponse[] memory responses = new ClaimResponse[](claimIds.length);
        
        for (uint i = 0; i < claimIds.length; i++) {
            (uint256 submissionDate, address claimant) = claimVerificationContract.getClaimMetadata(claimIds[i]);
            
            responses[i] = ClaimResponse({
                claim_id: claimIds[i],
                policy_type: getPolicyType(claimant),
                claimant: claimant,
                submissionDate: submissionDate
            });
        }
        
        return responses;
    }

    function getPolicyType(address userAddress) private view returns (string memory) {
        AutoClaimInfo memory autoClaim = userDataContract.getAutoClaimInfo(userAddress);
        if (!autoClaim.base.claim_id.isEmptyString()) {
            return autoClaim.base.policy_type;
        }
        
        HealthClaimInfo memory healthClaim = userDataContract.getHealthClaimInfo(userAddress);
        if (!healthClaim.base.claim_id.isEmptyString()) {
            return healthClaim.base.policy_type;
        }
        
        LifeClaimInfo memory lifeClaim = userDataContract.getLifeClaimInfo(userAddress);
        return lifeClaim.base.policy_type;
    }

    function updateClaimMappings(
        string calldata claim_id,
        string calldata phoneNumber,
        string calldata email,
        string calldata aadhar,
        string calldata vehicleReg
    ) external {
        require(msg.sender == address(claimVerificationContract), "Only ClaimVerification can update mappings");
        
        if (!phoneNumber.isEmptyString()) {
            userPhoneToClaims[phoneNumber].push(claim_id);
        }
        if (!email.isEmptyString()) {
            emailToClaims[email].push(claim_id);
        }
        if (!aadhar.isEmptyString()) {
            aadharToClaims[aadhar].push(claim_id);
        }
        if (!vehicleReg.isEmptyString()) {
            vehicleRegToClaims[vehicleReg].push(claim_id);
        }
    }
}
