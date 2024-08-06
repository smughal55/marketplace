import { HardhatUserConfig } from "hardhat/config"
import "@nomicfoundation/hardhat-toolbox"

require("dotenv").config()

const config: HardhatUserConfig = {
    solidity: {
        version: "0.8.26",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
            viaIR: true,
        },
    },
    defaultNetwork: "hardhat",
    networks: {
        // for mainnet
        "base-mainnet": {
            url: "https://mainnet.base.org",
            accounts: [process.env.WALLET_KEY as string],
            gasPrice: 1000000000,
        },
        // for testnet
        "base-sepolia": {
            url: "https://sepolia.base.org",
            accounts: [process.env.WALLET_KEY as string],
            gasPrice: 1000000000,
        },
        // for local dev environment
        "base-local": {
            url: "http://localhost:8545",
            accounts: [process.env.WALLET_KEY as string],
            gasPrice: 1000000000,
        },
    },
    etherscan: {
        apiKey: {
            "base-sepolia": process.env.ETHERSCAN_API_KEY as string,
        },
        customChains: [
            {
                network: "base-sepolia",
                chainId: 84532,
                urls: {
                    apiURL: "https://api-sepolia.basescan.org/api",
                    browserURL: "https://sepolia.basescan.org",
                },
            },
        ],
    },
    mocha: {
        timeout: 200000, // 200 seconds max for running tests
    },
}

export default config
