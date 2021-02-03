const { assert } = require("chai");

const Reputation = artifacts.require("Reputation")

require("chai")
.use(require('chai-as-promised'))
.should();

contract("Reputation", async(accounts) => {

    let reputationInstance = null;

    beforeEach(async() => {
        reputationInstance = await Reputation.new()
    })

    describe("set reputations", () => {

        it("should set no dispute count", async() => {
            await reputationInstance.setWithoutDispute(accounts[1])
        })
        it("should set freelancer won dispute count", async() => {
            await reputationInstance.setLanserWonDispute(accounts[1])
        })
        it("should set freelancer lost dispute count", async() => {
            await reputationInstance.setLanserLostDispute(accounts[1])
        })

        it("should get no dispute count", async() => {
            await reputationInstance.setWithoutDispute(accounts[1])
            const noDispute = await reputationInstance.getWithoutDispute(accounts[1])
            console.log("no dispute count " , noDispute.toString())
        })
        it("should get freelancer won dispute count", async() => {
            await reputationInstance.setLanserWonDispute(accounts[1])
            const wonDispute = await reputationInstance.getLancerWonDispute(accounts[1])
            console.log("won dispute count ", wonDispute.toString())
        })
        it("should get freelancer lost dispute count", async() => {
            await reputationInstance.setLanserLostDispute(accounts[1])
            const lostDispute = await reputationInstance.getLancerLostDispute(accounts[1])
            console.log("lost dispute count ", lostDispute.toString())
        })
    })  
})