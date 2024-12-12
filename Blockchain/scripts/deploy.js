const hre = require("hardhat");

async function main() {
    // Deploy UserData contract
    const UserData = await hre.ethers.getContractFactory("UserData");
    const userData = await UserData.deploy();
    await userData.waitForDeployment();
    console.log("UserData deployed to:", await userData.getAddress());

    // Deploy ClaimStorage contract
    const ClaimStorage = await hre.ethers.getContractFactory("ClaimStorage");
    const claimStorage = await ClaimStorage.deploy();
    await claimStorage.waitForDeployment();
    console.log("ClaimStorage deployed to:", await claimStorage.getAddress());

    // First deploy ClaimVerification with a temporary QueryInfo address
    const ClaimVerification = await hre.ethers.getContractFactory("ClaimVerification");
    const claimVerification = await ClaimVerification.deploy(
        await claimStorage.getAddress(),
        "0x0000000000000000000000000000000000000000", // Temporary QueryInfo address
        await userData.getAddress()
    );
    await claimVerification.waitForDeployment();
    console.log("ClaimVerification deployed to:", await claimVerification.getAddress());

    // Deploy QueryInfo with correct addresses
    const QueryInfo = await hre.ethers.getContractFactory("QueryInfo");
    const queryInfo = await QueryInfo.deploy(
        await userData.getAddress(),
        await claimVerification.getAddress()
    );
    await queryInfo.waitForDeployment();
    console.log("QueryInfo deployed to:", await queryInfo.getAddress());

    // Update ClaimVerification with the correct QueryInfo address
    // Note: You'll need to add a function in ClaimVerification to update the QueryInfo address
    // await claimVerification.setQueryInfoAddress(await queryInfo.getAddress());
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });