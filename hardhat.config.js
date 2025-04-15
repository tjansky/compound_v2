require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    pulsechain: {
      url: "https://rpc.pulsechain.com",  // Mainnet RPC
      chainId: 369,
      accounts: [PRIVATE_KEY] // Load private key from .env
    }
  }
};
