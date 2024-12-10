# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

## Prerequisites

- Node.js (v14+ recommended)
- npm or yarn package manager

## Installation

1. Clone the repository and install dependencies:

```shell
git clone <your-repo-url>
cd <project-directory>
npm install
```

2. Install Hardhat and Ethereum development dependencies:

```shell
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox @nomicfoundation/hardhat-network-helpers @nomicfoundation/hardhat-chai-matchers @nomicfoundation/hardhat-ethers @nomicfoundation/hardhat-verify chai ethers hardhat-gas-reporter solidity-coverage @typechain/hardhat typechain @typechain/ethers-v6
```

## Available Commands

Try running some of the following tasks:

```shell
# Show all available commands
npx hardhat help

# Run tests
npx hardhat test

# Run tests with gas reporting
REPORT_GAS=true npx hardhat test

# Start local Ethereum node
npx hardhat node

# Deploy contract using Hardhat Ignition
npx hardhat ignition deploy ./ignition/modules/Lock.js

# Compile contracts
npx hardhat compile

# Deploy to local network
npx hardhat run scripts/deploy.js --network localhost

# Deploy to testnet (e.g., Sepolia)
npx hardhat run scripts/deploy.js --network sepolia
```

## Configuration

1. Create a `.env` file in the root directory:

```shell
PRIVATE_KEY=your_wallet_private_key
ETHERSCAN_API_KEY=your_etherscan_api_key
ALCHEMY_API_KEY=your_alchemy_api_key
```

2. Update `hardhat.config.js` with your network configurations if needed.

## Development Workflow

1. Write your smart contracts in the `contracts/` directory
2. Write tests in the `test/` directory
3. Create deployment scripts in the `scripts/` directory
4. Test locally using Hardhat network
5. Deploy to testnet for final testing
6. Deploy to mainnet when ready

## Additional Resources

- [Hardhat Documentation](https://hardhat.org/docs)
- [Ethereum Development Documentation](https://ethereum.org/developers)
- [Solidity Documentation](https://docs.soliditylang.org)
