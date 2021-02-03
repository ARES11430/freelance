const { assert } = require("chai");

const Admin = artifacts.require("Admin")

require("chai")
.use(require('chai-as-promised'))
.should();

contract("Reputation", async(accounts) => {

    let adminInstance = null;
    const signer1 = accounts[0]
    const signer2 = accounts[1]
    const signer3 = accounts[2]

    beforeEach(async() => {
        adminInstance = await Admin.new()
    })

    it("should transfer ownerShip", async() => {
        const result =  await adminInstance.transferOwnership(signer2, {from: signer1})
        const event = result.logs[0].args
        assert.notEqual(signer1, 0x0)
        console.log("old owner: ", event.previousOwner)
        console.log("new owner: ", event.newOwner)
    })

    it("should add admin", async() => {
        const result =  await adminInstance.addAdmin(signer3, {from: signer1})
        const event = result.logs[0].args
        assert.notEqual(signer1, 0x0)
        assert.notEqual(signer3, 0x0)
        console.log("added admin address: ", event.admin)
    })

    it("should remove admin", async() => {
        const result =  await adminInstance.removeAdmin(signer3, {from: signer1})
        const event = result.logs[0].args
        assert.notEqual(signer1, 0x0)
        assert.notEqual(signer3, 0x0)
        console.log("removed admin address: ", event.admin)
    })

    it("should Check admin", async() => {
        await adminInstance.addAdmin(signer2, {from: signer1})
        const address1 = await adminInstance.checkAdmin(signer2, {from: signer1})
        const address2 = await adminInstance.checkAdmin(signer3, {from: signer1})

        console.log("Check addres 1", address1.toString())
        console.log("Check addres 1", address2.toString())
    })
})