require('dotenv').config();
const express = require('express');
const { ethers } = require('ethers');
const UserData = require('../Blockchain/artifacts/contracts/UserData.sol/UserData.json');
const ClaimVerification = require('../Blockchain/artifacts/contracts/ClaimVerification.sol/ClaimVerification.json');

const app = express();
app.use(express.json());


const USER_DATA_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const CLAIM_VERIFICATION_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";


const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");


const signer = new ethers.Wallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", provider);


const userDataContract = new ethers.Contract(USER_DATA_ADDRESS, UserData.abi, signer);
const claimVerificationContract = new ethers.Contract(CLAIM_VERIFICATION_ADDRESS, ClaimVerification.abi, signer);


let currentNonce;


async function initializeNonce() {
    currentNonce = await provider.getTransactionCount(signer.address);
}


initializeNonce().then(() => {
    const PORT = process.env.PORT || 3000;
    app.listen(PORT, () => {
        console.log(`Server running on port ${PORT}`);
    });
}).catch(error => {
    console.error('Failed to initialize nonce:', error);
    process.exit(1);
});

// Submit a new claim
app.post('/api/claims', async (req, res) => {
    try {
        const {
            userId,
            name,
            claimId,
            phoneNumber,
            kyc,
            governmentId,
            email,
            insuranceType,
            vehicleNo,
            insuranceCompany,
            purchaseYear,
            claimAmount,
            multipleClaimAllowed,
            eligibleForMoreClaim,
        } = req.body;

        // Generate a random encryption key
        const encryptionKey = ethers.randomBytes(32);
        
        // Set encryption key with current nonce
        await userDataContract.setEncryptionKey(encryptionKey, {
            nonce: currentNonce++
        });

        // Submit claim with incremented nonce
        const claimSubmission = {
            id: userId,
            name: name,
            claim_id: claimId,
            phone_number: phoneNumber,
            kyc: kyc,
            government_id: governmentId,
            email: email,
            insurance_type: insuranceType,
            vehicle_no: vehicleNo,
            insurance_company: insuranceCompany,
            purchase_year: purchaseYear,
            claim_amount: ethers.parseEther(claimAmount.toString()),
            multiple_claim_allowed: multipleClaimAllowed,
            eligible_for_more_claim: eligibleForMoreClaim,
            claim_status: "PENDING"
        };

        const tx = await userDataContract.submitClaim(claimSubmission, {
            nonce: currentNonce++
        });
        await tx.wait();

        res.json({
            success: true,
            message: "Claim submitted successfully",
            transactionHash: tx.hash
        });
    } catch (error) {
        console.error(error);
        // If nonce error, refresh the nonce
        if (error.code === 'NONCE_EXPIRED') {
            currentNonce = await provider.getTransactionCount(signer.address);
        }
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Verify a claim
app.post('/api/claims/verify', async (req, res) => {
    try {
        const {
            claimId,
            policyNo,
            userAddress,
            status, // 0: Pending, 1: Approved, 2: Rejected
            reason
        } = req.body;

        const tx = await claimVerificationContract.verifyClaim(
            claimId,
            policyNo,
            userAddress,
            status,
            reason,
            {
                nonce: currentNonce++
            }
        );
        await tx.wait();

        res.json({
            success: true,
            message: "Claim verified successfully",
            transactionHash: tx.hash
        });
    } catch (error) {
        console.error(error);
        // If nonce error, refresh the nonce
        if (error.code === 'NONCE_EXPIRED') {
            currentNonce = await provider.getTransactionCount(signer.address);
        }
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Get claim verification status
app.get('/api/claims/:claimId/status', async (req, res) => {
    try {
        const { claimId } = req.params;
        const status = await claimVerificationContract.getClaimVerificationStatus(claimId);

        res.json({
            success: true,
            status: {
                verificationStatus: status[0], // 0: Pending, 1: Approved, 2: Rejected
                verificationDate: new Date(status[1] * 1000).toISOString(),
                reason: status[2],
                verifier: status[3]
            }
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
}); 