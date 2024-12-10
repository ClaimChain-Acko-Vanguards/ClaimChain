const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Claim System", function () {
    let userData;
    let claimVerification;
    let owner;
    let encryptionKey;

    beforeEach(async function () {
        // Get test accounts
        [owner] = await ethers.getSigners();

        // Deploy UserData contract
        const UserData = await ethers.getContractFactory("UserData");
        userData = await UserData.deploy();
        await userData.waitForDeployment();

        // Deploy ClaimVerification contract
        const ClaimVerification = await ethers.getContractFactory("ClaimVerification");
        claimVerification = await ClaimVerification.deploy(await userData.getAddress());
        await claimVerification.waitForDeployment();

        // Generate encryption key properly as bytes32
        encryptionKey = ethers.hexlify(ethers.randomBytes(32));
        await userData.setEncryptionKey(encryptionKey);
    });

    it("Should submit and retrieve a claim successfully", async function () {
        const claimData = {
            id: "ID123",
            name: "John Doe",
            claim_id: "CLM123",
            phone_number: "1234567890",
            kyc: "KYC123",
            government_id: "GOV123",
            email: "john@example.com",
            insurance_type: "car",
            vehicle_no: "ABC123",
            insurance_company: "Sample Insurance Co",
            purchase_year: 2023,
            claim_amount: ethers.parseEther("1"),
            multiple_claim_allowed: true,
            eligible_for_more_claim: true,
            claim_status: "PENDING"
        };

        // Submit claim
        await userData.submitClaim({
            id: claimData.id,
            name: claimData.name,
            claim_id: claimData.claim_id,
            phone_number: claimData.phone_number,
            kyc: claimData.kyc,
            government_id: claimData.government_id,
            email: claimData.email,
            insurance_type: claimData.insurance_type,
            vehicle_no: claimData.vehicle_no,
            insurance_company: claimData.insurance_company,
            purchase_year: claimData.purchase_year,
            claim_amount: claimData.claim_amount,
            multiple_claim_allowed: claimData.multiple_claim_allowed,
            eligible_for_more_claim: claimData.eligible_for_more_claim,
            claim_status: claimData.claim_status
        });

        // Retrieve claim
        const storedClaim = await userData.getClaimInfo(owner.address);

        // Verify non-encrypted fields
        expect(storedClaim[1]).to.equal(claimData.name);
        expect(storedClaim[7]).to.equal(claimData.insurance_type);
        expect(storedClaim[9]).to.equal(claimData.insurance_company);
        expect(storedClaim[10]).to.equal(claimData.purchase_year);
        expect(storedClaim[11]).to.equal(claimData.claim_amount);
        expect(storedClaim[12]).to.equal(claimData.multiple_claim_allowed);
        expect(storedClaim[13]).to.equal(claimData.eligible_for_more_claim);
        expect(storedClaim[14]).to.equal(claimData.claim_status);

        // Verify an encrypted field (id)
        const hashedId = ethers.keccak256(ethers.toUtf8Bytes(claimData.id));
        const encryptionKeyBigInt = BigInt(encryptionKey);
        const hashedIdBigInt = BigInt(hashedId);
        const encryptedValue = hashedIdBigInt ^ encryptionKeyBigInt;
        
        // Convert the BigInt to a proper hex string with padding
        const encryptedHex = "0x" + encryptedValue.toString(16).padStart(64, '0');
        
        const isIdValid = await userData.verifyData(
            encryptedHex,
            claimData.id,
            encryptionKey
        );
        expect(isIdValid).to.be.true;
    });

    it("Should verify a claim successfully", async function () {
        // First submit a claim (reusing the claim data from previous test)
        const claimData = {
            id: "ID123",
            name: "John Doe",
            claim_id: "CLM123",
            phone_number: "1234567890",
            kyc: "KYC123",
            government_id: "GOV123",
            email: "john@example.com",
            insurance_type: "car",
            vehicle_no: "ABC123",
            insurance_company: "Sample Insurance Co",
            purchase_year: 2023,
            claim_amount: ethers.parseEther("1"),
            multiple_claim_allowed: true,
            eligible_for_more_claim: true,
            claim_status: "PENDING"
        };

        await userData.submitClaim(claimData);

        // Now verify the claim
        const policy_no = "POL123"; // Example policy number
        const verificationReason = "All documents verified";
        
        // Verify the claim using ClaimVerification contract
        await claimVerification.verifyClaim(
            claimData.claim_id,
            policy_no,
            owner.address,
            0, // VerificationStatus.Pending
            verificationReason
        );

        // Get and verify the claim verification status
        const [status, verificationDate, reason, verifier] = 
            await claimVerification.getClaimVerificationStatus(claimData.claim_id);
        
        expect(status).to.equal(0); // Pending
        expect(reason).to.equal(verificationReason);
        expect(verifier).to.equal(owner.address);
        expect(verificationDate).to.be.gt(0);

        // Verify claim with Approved status
        await claimVerification.verifyClaim(
            claimData.claim_id,
            policy_no,
            owner.address,
            1, // VerificationStatus.Approved
            "Claim approved after verification"
        );

        // Check if claim is marked as verified
        const isVerified = await claimVerification.isClaimVerified(claimData.claim_id);
        expect(isVerified).to.be.true;

        // Check policy claim count
        const claimCount = await claimVerification.getPolicyClaimCount(policy_no);
        expect(claimCount).to.equal(1);
    });

    it("Should detect fraudulent duplicate vehicle claims", async function () {
        // Submit first claim
        const claimData1 = {
            id: "ID124",
            name: "Jane Doe",
            claim_id: "CLM124",
            phone_number: "1234567891",
            kyc: "KYC124",
            government_id: "GOV124",
            email: "jane@example.com",
            insurance_type: "car",
            vehicle_no: "XYZ789",
            insurance_company: "Sample Insurance Co",
            purchase_year: 2023,
            claim_amount: ethers.parseEther("1"),
            multiple_claim_allowed: false, // Important: set to false
            eligible_for_more_claim: false,
            claim_status: "PENDING"
        };

        await userData.submitClaim(claimData1);

        // Verify first claim
        await claimVerification.verifyClaim(
            claimData1.claim_id,
            "POL124",
            owner.address,
            1, // Approved
            "First claim approved"
        );

        // Submit second claim with same vehicle number
        const claimData2 = {
            ...claimData1,
            id: "ID125",
            claim_id: "CLM125",
            // Keep same vehicle_no to trigger duplicate detection
        };

        await userData.submitClaim(claimData2);

        // Verify second claim - should be rejected due to duplicate vehicle
        await claimVerification.verifyClaim(
            claimData2.claim_id,
            "POL125",
            owner.address,
            0, // Status will be automatically set to Rejected
            "Checking duplicate"
        );

        // Check if the claim verification status is correctly set to Rejected
        const [status, , reason] = 
            await claimVerification.getClaimVerificationStatus(claimData2.claim_id);
        expect(status).to.equal(2); // Rejected
        expect(await claimVerification.isClaimVerified(claimData2.claim_id)).to.be.false;
    });
});