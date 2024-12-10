// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract UserData {
    using ECDSA for bytes32;
    
    mapping(address => bytes32) private userEncryptionKeys;

    struct UserBasicInfo {
        string name;
        bytes32 user_id_encrypted;
        bytes32 government_id_encrypted;
        bytes32 phone_no_encrypted;
        bytes32 email_encrypted;
    }

    struct VehicleInfo {
        string vehicle_no;
        string vehicle_make;
        string vehicle_model;
        uint256 vehicle_year;
    }

    struct ClaimInfo {
        bytes32 id_encrypted;
        string name;
        bytes32 claim_id_encrypted;
        bytes32 phone_number_encrypted;
        bytes32 kyc_encrypted;
        bytes32 government_id_encrypted;
        bytes32 email_encrypted;
        string insurance_type; // car, bike, life, travel
        bytes32 vehicle_no_encrypted; // optional
        MetaData meta_data;
    }

    struct MetaData {
        string insurance_company;
        uint256 purchase_year;
        uint256 claim_amount;
        bool multiple_claim_allowed;
        bool eligible_for_more_claim;
        string claim_status;
    }

    struct ClaimSubmission {
        // Basic Info
        string id;
        string name;
        string claim_id;
        string phone_number;
        string kyc;
        string government_id;
        string email;
        string insurance_type;
        string vehicle_no;
        // MetaData
        string insurance_company;
        uint256 purchase_year;
        uint256 claim_amount;
        bool multiple_claim_allowed;
        bool eligible_for_more_claim;
        string claim_status;
    }

    mapping(address => UserBasicInfo) private userBasicInfo;
    mapping(address => VehicleInfo) private vehicleInfo;
    mapping(address => ClaimInfo) private claimInfo;

    event ClaimSubmitted(string claim_no, address user);

    function encryptData(string memory data, bytes32 key) private pure returns (bytes32) {
        bytes32 dataHash = keccak256(abi.encodePacked(data));
        return dataHash ^ key;
    }

    function decryptData(bytes32 encrypted, bytes32 key) private pure returns (string memory) {
        bytes32 decrypted = encrypted ^ key;
        return bytes32ToString(decrypted);
    }

    function bytes32ToString(bytes32 _bytes32) private pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
            if (_bytes32[i] == 0) {
                assembly {
                    mstore(bytesArray, i)
                }
                break;
            }
        }
        return string(bytesArray);
    }

    function setEncryptionKey(bytes32 key) public {
        userEncryptionKeys[msg.sender] = key;
    }

    function submitClaim(ClaimSubmission memory submission) public {
        bytes32 userKey = userEncryptionKeys[msg.sender];
        require(userKey != bytes32(0), "Encryption key not set");

        userBasicInfo[msg.sender] = UserBasicInfo(
            submission.name,
            encryptData(submission.claim_id, userKey),
            encryptData(submission.government_id, userKey),
            encryptData(submission.phone_number, userKey),
            encryptData(submission.email, userKey)
        );

        vehicleInfo[msg.sender] = VehicleInfo(
            submission.vehicle_no,
            "",
            "",
            0
        );

        claimInfo[msg.sender] = ClaimInfo(
            encryptData(submission.id, userKey),
            submission.name,
            encryptData(submission.claim_id, userKey),
            encryptData(submission.phone_number, userKey),
            encryptData(submission.kyc, userKey),
            encryptData(submission.government_id, userKey),
            encryptData(submission.email, userKey),
            submission.insurance_type,
            encryptData(submission.vehicle_no, userKey),
            MetaData(
                submission.insurance_company,
                submission.purchase_year,
                submission.claim_amount,
                submission.multiple_claim_allowed,
                submission.eligible_for_more_claim,
                submission.claim_status
            )
        );

        emit ClaimSubmitted(submission.claim_id, msg.sender);
    }

    function getUserBasicInfo(address _user) public view returns (
        string memory name,
        string memory user_id,
        string memory government_id,
        string memory phone_no,
        string memory email
    ) {
        UserBasicInfo memory info = userBasicInfo[_user];
        return (
            info.name,
            decryptData(info.user_id_encrypted, userEncryptionKeys[_user]),
            decryptData(info.government_id_encrypted, userEncryptionKeys[_user]),
            decryptData(info.phone_no_encrypted, userEncryptionKeys[_user]),
            decryptData(info.email_encrypted, userEncryptionKeys[_user])
        );
    }

    function getVehicleInfo(address _user) public view returns (
        string memory vehicle_no,
        string memory vehicle_make,
        string memory vehicle_model,
        uint256 vehicle_year
    ) {
        VehicleInfo memory info = vehicleInfo[_user];
        return (
            info.vehicle_no,
            info.vehicle_make,
            info.vehicle_model,
            info.vehicle_year
        );
    }

    function getClaimInfo(address _user) public view returns (
        string memory id,
        string memory name,
        string memory claim_id,
        string memory phone_number,
        string memory kyc,
        string memory government_id,
        string memory email,
        string memory insurance_type,
        string memory vehicle_no,
        string memory insurance_company,
        uint256 purchase_year,
        uint256 claim_amount,
        bool multiple_claim_allowed,
        bool eligible_for_more_claim,
        string memory claim_status
    ) {
        ClaimInfo memory info = claimInfo[_user];
        return (
            decryptData(info.id_encrypted, userEncryptionKeys[_user]),
            info.name,
            decryptData(info.claim_id_encrypted, userEncryptionKeys[_user]),
            decryptData(info.phone_number_encrypted, userEncryptionKeys[_user]),
            decryptData(info.kyc_encrypted, userEncryptionKeys[_user]),
            decryptData(info.government_id_encrypted, userEncryptionKeys[_user]),
            decryptData(info.email_encrypted, userEncryptionKeys[_user]),
            info.insurance_type,
            decryptData(info.vehicle_no_encrypted, userEncryptionKeys[_user]),
            info.meta_data.insurance_company,
            info.meta_data.purchase_year,
            info.meta_data.claim_amount,
            info.meta_data.multiple_claim_allowed,
            info.meta_data.eligible_for_more_claim,
            info.meta_data.claim_status
        );
    }

    function verifyData(
        bytes32 encrypted,
        string memory original,
        bytes32 key
    ) public pure returns (bool) {
        return encrypted == encryptData(original, key);
    }

    function getUserEncryptionKey(address user) public view returns (bytes32) {
        return userEncryptionKeys[user];
    }
}