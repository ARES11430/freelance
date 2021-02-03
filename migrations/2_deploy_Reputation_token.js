const Token = artifacts.require("ERC20Test");
const Reputation = artifacts.require("Reputation");
const FreeLancer = artifacts.require("FreeLancer");

module.exports = async (deployer, network, accounts) => {

    await deployer.deploy(Reputation);
    await deployer.deploy(Token);

    const reputation = await Reputation.deployed();
    await deployer.deploy(FreeLancer, reputation.address , accounts[1]);

};