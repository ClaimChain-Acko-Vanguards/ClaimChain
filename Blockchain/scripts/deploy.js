const hre = require("hardhat");

async function main() {
    // Deploy UserData contract
    const UserData = await hre.ethers.getContractFactory("UserData");
    const userData = await UserData.deploy();
    await userData.waitForDeployment();
    console.log("UserData deployed to:", await userData.getAddress());

    // Deploy ClaimVerification contract
    const ClaimVerification = await hre.ethers.getContractFactory("ClaimVerification");
    const claimVerification = await ClaimVerification.deploy(await userData.getAddress());
    await claimVerification.waitForDeployment();
    console.log("ClaimVerification deployed to:", await claimVerification.getAddress());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });