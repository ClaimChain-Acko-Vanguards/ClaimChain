// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Move struct definitions outside the contract
struct BaseClaimInfo {
    // Non-sensitive information stored as plain text
    string ledger_id;
    string policy_type;
    string policy_number;
    string claim_id;
    string claimant_name;
    // Sensitive information that needs encryption
    string phone_number;
    string email_id;
    string aadhar_id;
    // Rest of the non-sensitive information
    string insurer_name;
    uint8 claim_status;
    uint32 claim_date;
    uint128 claim_amount;
    uint128 settlement_amount;
    uint32 settlement_date;
    uint8 fraud_score;
    uint24 pincode;
    string city;
    string state;
    string cause_proof;
    string cause_statement;
    bool third_party_involvement;
    string error_codes;
    uint16 claim_processing_time;
    string supporting_documents;
    string reason_for_claim;
}

struct AutoClaimInfo {
    BaseClaimInfo base;
    string vehicle_registration_no;
    uint8 vehicle_type;
    string vehicle_make_and_model;
    uint8 car_bike_age;
    uint32 accident_date;
    string accident_location;
    string garage_name;
    uint128 repair_estimate;
    string driving_behavior_data;
    bool iot_data_available;
}

struct HealthClaimInfo {
    BaseClaimInfo base;
    string abha_id;
    string hospital_name;
    string diagnosis_or_illness;
    uint32 hospitalization_start_date;
    uint32 hospitalization_end_date;
    uint128 total_medical_expenses;
    uint128 pre_approved_amount;
    string hospital_bills;
    string test_reports;
    string initial_analysis;
    string final_analysis;
    bool iot_data_available;
}

struct LifeClaimInfo {
    BaseClaimInfo base;
    string nominee_name;
    uint128 policy_coverage;
}

contract UserData {
    using ECDSA for bytes32;
    
    mapping(address => bytes32) private userEncryptionKeys;
    mapping(address => AutoClaimInfo) private autoClaimInfo;
    mapping(address => HealthClaimInfo) private healthClaimInfo;
    mapping(address => LifeClaimInfo) private lifeClaimInfo;

    event ClaimSubmitted(string claim_type, address user);

    // Updated submit claim functions - one for each type
    function submitAutoClaim(AutoClaimInfo memory claim) public {
        autoClaimInfo[msg.sender] = claim;
        emit ClaimSubmitted("AUTO", msg.sender);
    }

    function submitHealthClaim(HealthClaimInfo memory claim) public {
        healthClaimInfo[msg.sender] = claim;
        emit ClaimSubmitted("HEALTH", msg.sender);
    }

    function submitLifeClaim(LifeClaimInfo memory claim) public {
        lifeClaimInfo[msg.sender] = claim;
        emit ClaimSubmitted("LIFE", msg.sender);
    }

    // Keep only basic getter functions
    function getAutoClaimInfo(address _user) public view returns (AutoClaimInfo memory) {
        return autoClaimInfo[_user];
    }

    function getHealthClaimInfo(address _user) public view returns (HealthClaimInfo memory) {
        return healthClaimInfo[_user];
    }

    function getLifeClaimInfo(address _user) public view returns (LifeClaimInfo memory) {
        return lifeClaimInfo[_user];
    }
}