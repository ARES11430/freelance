
var HDWalletProvider = require("@truffle/hdwallet-provider");
var mnemonic = "cat trade perfect fabric crack young lumber secret mouse detail minor want";

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*" // Match any network id
    }
    /*  ,bsc: {
        provider: () => new HDWalletProvider(mnemonic,
          "https://data-seed-prebsc-1-s1.binance.org:8545/"),
        network_id: 97,
        skipDryRun: true
      } */
    },  
  contracts_directory: './src/contracts/',
  contracts_build_directory: './src/abis/',
  
  compilers: {
    solc: {
      version: "0.8.1",
      optimizer: {
        enabled: true,
        runs: 50
      },
    }
  }
}