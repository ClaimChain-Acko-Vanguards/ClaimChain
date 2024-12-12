require('dotenv').config();
const express = require('express');
const { ethers } = require('ethers');
const UserData = require('../Blockchain/artifacts/contracts/UserData.sol/UserData.json');
const ClaimVerification = require('../Blockchain/artifacts/contracts/ClaimVerification.sol/ClaimVerification.json');

const app = express();
app.use(express.json());


const USER_DATA_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3";
const CLAIM_VERIFICATION_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0";
const CLAIM_STORAGE_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";
const QUERY_INFO_ADDRESS = "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9";


const provider = new ethers.JsonRpcProvider("http://127.0.0.1:8545");


const signer = new ethers.Wallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80", provider);


const userDataContract = new ethers.Contract(USER_DATA_ADDRESS, UserData.abi, signer);
const claimVerificationContract = new ethers.Contract(CLAIM_VERIFICATION_ADDRESS, ClaimVerification.abi, signer);


let currentNonce;


async function initializeNonce() {
    currentNonce = await provider.getTransactionCount(signer.address);
    console.log('Initialized nonce:', currentNonce);
}


async function resetNonce() {
    currentNonce = await provider.getTransactionCount(signer.address);
    console.log('Reset nonce to:', currentNonce);
}


async function initializeContracts() {
    try {
        // Check if contracts need to be linked
        const code = await provider.getCode(CLAIM_VERIFICATION_ADDRESS);
        if (code === '0x') {
            throw new Error('ClaimVerification contract not found');
        }

        // Set addresses using the setter functions
        try {
            await claimVerificationContract.setClaimStorageAddress(CLAIM_STORAGE_ADDRESS, { nonce: currentNonce++ });
            console.log('ClaimStorage address set');
        } catch (e) {
            if (e.message.includes("ClaimStorage already set")) {
                console.log('ClaimStorage address already set');
            } else {
                console.error('Error setting ClaimStorage:', e.message);
            }
        }

        try {
            await claimVerificationContract.setUserDataAddress(USER_DATA_ADDRESS, { nonce: currentNonce++ });
            console.log('UserData address set');
        } catch (e) {
            if (e.message.includes("UserData already set")) {
                console.log('UserData address already set');
            } else {
                console.error('Error setting UserData:', e.message);
            }
        }

        try {
            await claimVerificationContract.setQueryInfoAddress(QUERY_INFO_ADDRESS, { nonce: currentNonce++ });
            console.log('QueryInfo address set');
        } catch (e) {
            if (e.message.includes("QueryInfo already set")) {
                console.log('QueryInfo address already set');
            } else {
                console.error('Error setting QueryInfo:', e.message);
            }
        }

    } catch (error) {
        console.error('Failed to initialize contracts:', error);
        throw error;
    }
}


initializeNonce()
    .then(() => initializeContracts())
    .then(() => {
        const PORT = process.env.PORT || 3000;
        app.listen(PORT, () => {
            console.log(`Server running on port ${PORT}`);
        });
    })
    .catch(error => {
        console.error('Failed to initialize:', error);
        process.exit(1);
    });

// Submit a new claim
app.post('/api/claims', async (req, res) => {
    try {
        // Verify contract deployment
        const code = await provider.getCode(USER_DATA_ADDRESS);
        if (code === '0x') {
            throw new Error('UserData contract not deployed');
        }
        
        const { policy_type, ...claimData } = req.body;

        // Convert sensitive data to bytes32
        // In server.js, modify the baseInfo object creation:

const baseInfo = {
    ledger_id: claimData.ledger_id,
    policy_type,
    policy_number: claimData.policy_number,
    claim_id: claimData.claim_id,
    claimant_name: claimData.claimant_name,
    // Use plain strings instead of encrypted values
    phone_number: claimData.phone_number || "",
    email_id: claimData.email_id || "",
    aadhar_id: claimData.aadhar_id || "",
    insurer_name: claimData.insurer_name,
    claim_status: claimData.claim_status || 0,
    claim_date: claimData.claim_date || Math.floor(Date.now() / 1000),
    claim_amount: claimData.claim_amount || 0,
    settlement_amount: claimData.settlement_amount || 0,
    settlement_date: claimData.settlement_date || 0,
    fraud_score: claimData.fraud_score || 0,
    pincode: claimData.pincode || 0,
    city: claimData.city || "",
    state: claimData.state || "",
    cause_proof: claimData.cause_proof || "",
    cause_statement: claimData.cause_statement || "",
    third_party_involvement: claimData.third_party_involvement || false,
    error_codes: claimData.error_codes || "",
    claim_processing_time: claimData.claim_processing_time || 0,
    supporting_documents: claimData.supporting_documents || "",
    reason_for_claim: claimData.reason_for_claim || ""
};

        let tx;
        switch(policy_type) {
            case "AUTO":
                const autoClaimData = {
                    base: {
                        ledger_id: claimData.ledger_id,
                        policy_type: policy_type,
                        policy_number: claimData.policy_number,
                        claim_id: claimData.claim_id,
                        claimant_name: claimData.claimant_name,
                        phone_number: claimData.phone_number || "",
                        email_id: claimData.email_id || "",
                        aadhar_id: claimData.aadhar_id || "",
                        insurer_name: claimData.insurer_name,
                        claim_status: Number(claimData.claim_status) || 0,
                        claim_date: Number(claimData.claim_date) || Math.floor(Date.now() / 1000),
                        claim_amount: ethers.parseUnits(String(claimData.claim_amount || 0), 0),
                        settlement_amount: ethers.parseUnits(String(claimData.settlement_amount || 0), 0),
                        settlement_date: Number(claimData.settlement_date) || 0,
                        fraud_score: Number(claimData.fraud_score) || 0,
                        pincode: Number(claimData.pincode) || 0,
                        city: claimData.city || "",
                        state: claimData.state || "",
                        cause_proof: claimData.cause_proof || "",
                        cause_statement: claimData.cause_statement || "",
                        third_party_involvement: Boolean(claimData.third_party_involvement),
                        error_codes: claimData.error_codes || "",
                        claim_processing_time: Number(claimData.claim_processing_time) || 0,
                        supporting_documents: claimData.supporting_documents || "",
                        reason_for_claim: claimData.reason_for_claim || ""
                    },
                    vehicle_registration_no: claimData.vehicle_registration_no || "",
                    vehicle_type: Number(claimData.vehicle_type) || 0,
                    vehicle_make_and_model: claimData.vehicle_make_and_model || "",
                    car_bike_age: Number(claimData.car_bike_age) || 0,
                    accident_date: Number(claimData.accident_date) || 0,
                    accident_location: claimData.accident_location || "",
                    garage_name: claimData.garage_name || "",
                    repair_estimate: ethers.parseUnits(String(claimData.repair_estimate || 0), 0),
                    driving_behavior_data: claimData.driving_behavior_data || "",
                    iot_data_available: Boolean(claimData.iot_data_available)
                };
                tx = await userDataContract.submitAutoClaim(autoClaimData);
                break;

            case "HEALTH":
                const healthClaimData = {
                    base: baseInfo,
                    abha_id: claimData.abha_id || "",
                    hospital_name: claimData.hospital_name || "",
                    diagnosis_or_illness: claimData.diagnosis_or_illness || "",
                    hospitalization_start_date: claimData.hospitalization_start_date || 0,
                    hospitalization_end_date: claimData.hospitalization_end_date || 0,
                    total_medical_expenses: claimData.total_medical_expenses || 0,
                    pre_approved_amount: claimData.pre_approved_amount || 0,
                    hospital_bills: claimData.hospital_bills || "",
                    test_reports: claimData.test_reports || "",
                    initial_analysis: claimData.initial_analysis || "",
                    final_analysis: claimData.final_analysis || "",
                    iot_data_available: claimData.iot_data_available || false
                };
                tx = await userDataContract.submitHealthClaim(healthClaimData);
                break;

            case "LIFE":
                const lifeClaimData = {
                    base: baseInfo,
                    nominee_name: claimData.nominee_name || "",
                    policy_coverage: claimData.policy_coverage || 0
                };
                tx = await userDataContract.submitLifeClaim(lifeClaimData);
                break;

            default:
                throw new Error("Invalid policy type");
        }

        await tx.wait();

        // Store claim in verification contract
        const verificationTx = await claimVerificationContract.storeClaim(
            claimData.claim_id,
            claimData.policy_number,
            signer.address,
            { nonce: currentNonce++ }
        );
        await verificationTx.wait();

        res.json({
            success: true,
            message: "Claim submitted successfully",
            transactionHash: tx.hash
        });
    } catch (error) {
        console.error(error);
        // If nonce error, reset the nonce
        if (error.message.includes('nonce too high') || error.message.includes('Nonce too high')) {
            await resetNonce();
            res.status(500).json({
                success: false,
                error: 'Transaction failed due to nonce issue. Please try again.'
            });
        } else {
            res.status(500).json({
                success: false,
                error: error.message
            });
        }
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

// Get all claims
app.get('/api/claims', async (req, res) => {
    try {
        // Add contract verification
        const code = await provider.getCode(CLAIM_VERIFICATION_ADDRESS);
        if (code === '0x') {
            throw new Error(`No contract found at address ${CLAIM_VERIFICATION_ADDRESS}`);
        }

        // Get all claims from the contract
        const claims = await claimVerificationContract.getAllClaims();
        
        // Parse and format the claims if needed
        const formattedClaims = Array.isArray(claims) ? claims : [];

        res.json({
            success: true,
            claims: formattedClaims
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// Search claims by parameter
app.get('/api/claims/search', async (req, res) => {
    try {
        const { searchParam, searchType } = req.query;
        const claims = await claimVerificationContract.searchClaims(
            searchParam,
            searchType
        );
        res.json({
            success: true,
            claims: claims
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});