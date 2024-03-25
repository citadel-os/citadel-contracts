/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-etherscan");
require('hardhat-contract-sizer');

const { API_URL, PRIVATE_KEY, ACCOUNT1_PK } = process.env;
module.exports = {
  solidity: "0.8.24",
  defaultNetwork: "localhost",
  allowUnlimitedContractSize: true,
  networks: {
    hardhat: {
      chainId: 1337,
    },
    localhost: {
      url: API_URL,
      accounts: "remote",
      gas: "auto",
      gasMultiplier: 4,
    },
    mainnet: {
      url: API_URL,
      accounts: [`0x${PRIVATE_KEY}`],
      gas: "auto",
      gasMultiplier: 1.5,
      //gasLimit: 1746472,
      //gasPrice: 12
    },
    goerli: {
      url: API_URL,
      accounts: [`0x${PRIVATE_KEY}`],
      // gas: "auto",
      // gasMultiplier: 1.5
      gas: 2100000,
      gasPrice: 8000000000,
      gasLimit: 5000000
    },
    sepolia: {
      url: API_URL,
      accounts: [`0x${PRIVATE_KEY}`],
      gas: "auto",
      gasMultiplier: 5
    },
    arbitrumgoerli: {
      url: API_URL,
      accounts: [`0x${PRIVATE_KEY}`],
      gas: "auto",
      gasMultiplier: 1.5
    },
    mumbai: {
      url: API_URL,
      accounts: [`0x${PRIVATE_KEY}`],
      gas: "auto",
      gasMultiplier: 1.5
    },
  },
  etherscan: {
    apiKey: "TJGFDFSCM8PZMMHSFFMUY8BW4T3U8CJSH2"
  },
};
