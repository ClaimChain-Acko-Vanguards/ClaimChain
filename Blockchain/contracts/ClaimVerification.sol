// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./UserData.sol";

contract ClaimVerification {
    UserData private userDataContract;
    
    // Track verified claims
    mapping(string => bool) private verifiedClaims; // claim_no => verified
    mapping(string => bool) private usedPolicyNumbers; // policy_no => used
    mapping(string => uint256) private claimsByPolicy; // policy_no => number of claims
    mapping(string => address) private claimOwners; // claim_no => owner
    
    // Verification status
    enum VerificationStatus { Pending, Approved, Rejected }
    
    struct ClaimVerificationDetails {
        VerificationStatus status;
        uint256 verificationDate;
        string reason;
        address verifier;
    }
    
    mapping(string => ClaimVerificationDetails) private claimVerificationDetails;
    
    // Events
    event ClaimVerified(string claim_no, address user, VerificationStatus status);
    event FraudulentClaimDetected(string claim_no, address user, string reason);
    
    // Only authorized verifiers can verify claims
    mapping(address => bool) private authorizedVerifiers;
    address private owner;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyVerifier() {
        require(authorizedVerifiers[msg.sender], "Only authorized verifiers can perform this action");
        _;
    }
    
    constructor(address _userDataContract) {
        userDataContract = UserData(_userDataContract);
        owner = msg.sender;
        authorizedVerifiers[msg.sender] = true;
    }
    
    function addVerifier(address _verifier) public onlyOwner {
        authorizedVerifiers[_verifier] = true;
    }
    
    function removeVerifier(address _verifier) public onlyOwner {
        authorizedVerifiers[_verifier] = false;
    }
    
    // Add new mappings
    mapping(string => string[]) private userPhoneToClaims; // phone_number => claim_ids
    mapping(string => string) private claimToPhone; // claim_id => phone_number
    
    function verifyClaim(
        string memory claim_id,
        string memory policy_no,
        address userAddress,
        VerificationStatus status,
        string memory reason
    ) public onlyVerifier {
        // Get user claim data from UserData contract
        (
            string memory id,
            string memory name,
            string memory claim_id_stored,
            string memory phone_number,
            string memory kyc,
            string memory government_id,
            string memory email,
            string memory insurance_type,
            string memory vehicle_no,
            ,,,
            bool multiple_claim_allowed,
            ,
        ) = userDataContract.getClaimInfo(userAddress);

        // Check for duplicate claims based on phone number
        string[] memory userClaims = userPhoneToClaims[phone_number];
        
        // For vehicle insurance claims
        if (keccak256(abi.encodePacked(insurance_type)) == keccak256(abi.encodePacked("car")) ||
            keccak256(abi.encodePacked(insurance_type)) == keccak256(abi.encodePacked("bike"))) {
            
            for (uint i = 0; i < userClaims.length; i++) {
                // Get previous claim details
                (,,,,,,, string memory prev_insurance_type, string memory prev_vehicle_no,,,,,,) = 
                    userDataContract.getClaimInfo(claimOwners[userClaims[i]]);
                
                // Check for duplicate vehicle claims
                if (keccak256(abi.encodePacked(prev_vehicle_no)) == keccak256(abi.encodePacked(vehicle_no)) &&
                    keccak256(abi.encodePacked(prev_insurance_type)) == keccak256(abi.encodePacked(insurance_type))) {
                    if (!multiple_claim_allowed) {
                        emit FraudulentClaimDetected(claim_id, userAddress, "Duplicate vehicle claim detected");
                        // Store verification details with Rejected status
                        claimVerificationDetails[claim_id] = ClaimVerificationDetails({
                            status: VerificationStatus.Rejected,
                            verificationDate: block.timestamp,
                            reason: "Duplicate vehicle claim detected",
                            verifier: msg.sender
                        });
                        return;
                    }
                }
            }
        }
        // For health, life, and travel insurance claims
        else {
            require(bytes(kyc).length > 0, "KYC details required for non-vehicle claims");
            // Additional KYC verification logic can be added here
        }

        // Check if claim has already been verified
        require(!verifiedClaims[claim_id], "Claim has already been verified");
        
        // Check for duplicate claim numbers
        require(claimOwners[claim_id] == address(0), "Claim number already exists");
        
        // Get policy claim count
        uint256 policyClaimCount = claimsByPolicy[policy_no];
        
        // Check for suspicious activity
        if (policyClaimCount >= 3) {
            emit FraudulentClaimDetected(claim_id, userAddress, "Multiple claims on same policy");
            status = VerificationStatus.Rejected;
        }
        
        // Store verification details
        claimVerificationDetails[claim_id] = ClaimVerificationDetails({
            status: status,
            verificationDate: block.timestamp,
            reason: reason,
            verifier: msg.sender
        });
        
        // Update claim tracking
        if (status == VerificationStatus.Approved) {
            verifiedClaims[claim_id] = true;
            claimOwners[claim_id] = userAddress;
            claimsByPolicy[policy_no]++;
        }
        
        // Update phone number to claims mapping
        userPhoneToClaims[phone_number].push(claim_id);
        claimToPhone[claim_id] = phone_number;
        
        emit ClaimVerified(claim_id, userAddress, status);
    }
    
    function getClaimVerificationStatus(string memory claim_id) public view returns (
        VerificationStatus status,
        uint256 verificationDate,
        string memory reason,
        address verifier
    ) {
        ClaimVerificationDetails memory details = claimVerificationDetails[claim_id];
        return (
            details.status,
            details.verificationDate,
            details.reason,
            details.verifier
        );
    }
    
    function isClaimVerified(string memory claim_id) public view returns (bool) {
        return verifiedClaims[claim_id];
    }
    
    function getPolicyClaimCount(string memory policy_no) public view returns (uint256) {
        return claimsByPolicy[policy_no];
    }
} 