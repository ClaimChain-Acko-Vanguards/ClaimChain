// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./ClaimStorage.sol";
import "./QueryInfo.sol";
import "./interfaces/IClaimTypes.sol";
import {UserData, BaseClaimInfo, AutoClaimInfo, HealthClaimInfo, LifeClaimInfo} from "./UserData.sol";

contract ClaimVerification {
    ClaimStorage private claimStorage;
    QueryInfo private queryInfoContract;
    UserData private userDataContract;

    // Simplified storage - just track claim metadata
    struct ClaimMetadata {
        uint256 submissionDate;
        address claimant;
    }

    mapping(string => ClaimMetadata) private claimMetadata;
    mapping(string => uint256) private claimsByPolicy;

    // Array to track all claim IDs
    string[] private allClaimIds;

    constructor(address _claimStorage, address _queryInfoContract, address _userData) {
        claimStorage = ClaimStorage(_claimStorage);
        queryInfoContract = QueryInfo(_queryInfoContract);
        userDataContract = UserData(_userData);
    }

    function storeClaim(
        string memory claim_id,
        string memory policy_no,
        address userAddress
    ) public {
        // Try to get claim from each type
        AutoClaimInfo memory autoClaim = userDataContract.getAutoClaimInfo(userAddress);
        HealthClaimInfo memory healthClaim = userDataContract.getHealthClaimInfo(userAddress);
        LifeClaimInfo memory lifeClaim = userDataContract.getLifeClaimInfo(userAddress);

        // Check which type of claim exists and use its data
        string memory policy_type;
        if (bytes(autoClaim.base.claim_id).length > 0) {
            policy_type = autoClaim.base.policy_type;
            // Update QueryInfo mappings with unencrypted strings
            queryInfoContract.updateClaimMappings(
                claim_id,
                autoClaim.base.phone_number,
                autoClaim.base.email_id,
                autoClaim.base.aadhar_id,
                autoClaim.vehicle_registration_no
            );
        } else if (bytes(healthClaim.base.claim_id).length > 0) {
            policy_type = healthClaim.base.policy_type;
            queryInfoContract.updateClaimMappings(
                claim_id,
                healthClaim.base.phone_number,
                healthClaim.base.email_id,
                healthClaim.base.aadhar_id,
                "" // No vehicle registration for health claims
            );
        } else if (bytes(lifeClaim.base.claim_id).length > 0) {
            policy_type = lifeClaim.base.policy_type;
            queryInfoContract.updateClaimMappings(
                claim_id,
                lifeClaim.base.phone_number,
                lifeClaim.base.email_id,
                lifeClaim.base.aadhar_id,
                "" // No vehicle registration for life claims
            );
        } else {
            revert("No claim found for user");
        }

        // Store basic claim metadata
        claimMetadata[claim_id] = ClaimMetadata({
            submissionDate: block.timestamp,
            claimant: userAddress
        });
        
        claimsByPolicy[policy_no]++;

        // Store claim in ClaimStorage
        claimStorage.storeClaim(claim_id, policy_type, userAddress, block.timestamp);

        // Add claim ID to array
        allClaimIds.push(claim_id);
    }
    
    function getClaimMetadata(string memory claim_id) public view returns (
        uint256 submissionDate,
        address claimant
    ) {
        ClaimMetadata memory metadata = claimMetadata[claim_id];
        return (
            metadata.submissionDate,
            metadata.claimant
        );
    }
    
    function getPolicyClaimCount(string memory policy_no) public view returns (uint256) {
        return claimsByPolicy[policy_no];
    }

    // Function to get all claims
    function getAllClaims() public view returns (ClaimStorage.ClaimData[] memory) {
        ClaimStorage.ClaimData[] memory allClaims = new ClaimStorage.ClaimData[](allClaimIds.length);
        
        for (uint i = 0; i < allClaimIds.length; i++) {
            allClaims[i] = claimStorage.getClaim(allClaimIds[i]);
        }
        
        return allClaims;
    }
    
    // New function to search claims by parameters
    function searchClaims(
        string memory searchParam,
        string memory searchType
    ) public view returns (ClaimStorage.ClaimData[] memory) {
        // If no search parameters, return all claims
        if (bytes(searchParam).length == 0) {
            return getAllClaims();
        }
        
        // Use QueryInfo contract to search by parameters
        QueryInfo.ClaimResponse[] memory responses = queryInfoContract.getClaims(searchParam, searchType);
        ClaimStorage.ClaimData[] memory filteredClaims = new ClaimStorage.ClaimData[](responses.length);
        
        for (uint i = 0; i < responses.length; i++) {
            filteredClaims[i] = claimStorage.getClaim(responses[i].claim_id);
        }
        
        return filteredClaims;
    }

    // Add these functions
    function setClaimStorageAddress(address _claimStorage) external {
        require(address(claimStorage) == address(0), "ClaimStorage already set");
        claimStorage = ClaimStorage(_claimStorage);
    }

    function setUserDataAddress(address _userData) external {
        require(address(userDataContract) == address(0), "UserData already set");
        userDataContract = UserData(_userData);
    }

    // Existing function
    function setQueryInfoAddress(address _queryInfo) external {
        require(address(queryInfoContract) == address(0), "QueryInfo already set");
        queryInfoContract = QueryInfo(_queryInfo);
    }
} 