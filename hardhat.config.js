/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require("dotenv").config();
require("@nomiclabs/hardhat-ethers");
require("@openzeppelin/hardhat-upgrades");
require("@nomiclabs/hardhat-etherscan");

const { API_URL, PRIVATE_KEY, ACCOUNT1_PK } = process.env;
module.exports = {
  solidity: "0.8.4",
  defaultNetwork: "localhost",
  networks: {
    hardhat: {
      chainId: 1337,
    },
    ropsten: {
      url: API_URL,
      accounts: [`0x${PRIVATE_KEY}`],
      gas: "auto",
      gasMultiplier: 2,
    },
    rinkeby: {
      url: API_URL,
      accounts: [`0x${PRIVATE_KEY}`],
      gas: 2100000, 
      gasPrice: 8000000000
      //gas: "auto",
      //gasMultiplier: 2,
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
      gas: "auto",
      gasMultiplier: 1.5,
      // gas: "auto",
      // gasMultiplier: 2,
    },
  },
  etherscan: {
    apiKey: "TJGFDFSCM8PZMMHSFFMUY8BW4T3U8CJSH2"
  },
};
