const { assert } = require("chai");

const Freelancer = artifacts.require("Freelancer")
const Reputation = artifacts.require("Reputation")
const Token = artifacts.require("ERC20Test")

require("chai")
.use(require('chai-as-promised'))
.should();

contract("Freelancer", async(accounts) => {

    let freelancerInstance = null
    let reputationInstance = null
    let tokenInstance = null

    const signer1 = accounts[5]
    const signer2 = accounts[6]
    const signer3 = accounts[7]

    beforeEach(async() => {
        reputationInstance = await Reputation.new({from: signer1});
        tokenInstance = await Token.new({from: signer1});
        freelancerInstance = await Freelancer.new(reputationInstance.address, signer1, {from: signer1})
        
        let tokenValue = web3.utils.toWei("1000000000")
        await tokenInstance.transfer(signer2 , tokenValue, {from: signer1})
        
    })

    it("should get owner address", async() => {
        const owner = await freelancerInstance.getOwner({from: signer1})
        assert.equal(owner, signer1)
        console.log(owner)
    })

    it("should get wallet address", async() => {
        const wallet = await freelancerInstance.showWallet({from: signer1})
        assert.equal(wallet, signer1)
        console.log(wallet)
    })

    it("should change wallet", async() => {
        const result = await freelancerInstance.changeWallet(signer2, {from: signer1})
        const event = result.logs[0].args
        assert.notEqual(signer1, 0x0)
        assert.notEqual(signer2, 0x0)
        console.log("old wallet is ", event.oldWallet)
        console.log("new wallet is ", event.newWallet)
        console.log("change date is ", event.walletChangeDate.toString())
    })

    it("should create project with ether then check the project counter", async() => {
        let value = web3.utils.toWei("0.00001")
        let value2 = web3.utils.toWei("0.000011")
        const result = await freelancerInstance.createProject(value, "0",
             "0x0000000000000000000000000000000000000000", {value: value2})
        const event = result.logs[0].args
        console.log("project Id: ", event.projectId.toString())
        console.log("employee address : ", event.employee)
        console.log("budget amount : ", event.budget.toString())
        console.log("project Type : ", event.projectType.toString())
        console.log("currency : ", event.currency)
        console.log("creation date : ", event.projectCreationDate.toString())

        const projectCounter = await freelancerInstance.projectCounter()
        console.log("project counter is ", projectCounter.toString())
    })

    it("should create project with token then check the project counter", async() => {
        
        let tokenValue = web3.utils.toWei("1000000000")
        await tokenInstance.approve(freelancerInstance.address, tokenValue, {from: signer2})

        let value = web3.utils.toWei("1")
        const result = await freelancerInstance.createProject(value, "2",
             tokenInstance.address.toString(), {from: signer2})
        const event = result.logs[0].args
        console.log("project Id: ", event.projectId.toString())
        console.log("employee address : ", event.employee)
        console.log("budget amount : ", event.budget.toString())
        console.log("project Type : ", event.projectType.toString())
        console.log("currency : ", event.currency)
        console.log("creation date : ", event.projectCreationDate.toString())

        const projectCounter = await freelancerInstance.projectCounter()
        console.log("project counter is ", projectCounter.toString())
    })

    it("should cancel project and return the budget+escrow to employee", async() => {
       
        // create the project 
        let tokenValue = web3.utils.toWei("1000000000")
        await tokenInstance.approve(freelancerInstance.address, tokenValue, {from: signer2})

        let value = web3.utils.toWei("1")
        const result = await freelancerInstance.createProject(value, "2",
             tokenInstance.address.toString(), {from: signer2})
             const event = result.logs[0].args
             console.log("project Id: ", event.projectId.toString())
             console.log("employee address : ", event.employee)
             console.log("budget amount : ", event.budget.toString())
             console.log("project Type : ", event.projectType.toString())
             console.log("currency : ", event.currency)
             console.log("creation date : ", event.projectCreationDate.toString())
     
             const projectCounter = await freelancerInstance.projectCounter()
             console.log("project counter is ", projectCounter.toString())

        let balance1 = await tokenInstance.balanceOf(signer2)
        console.log("balance 1 ", balance1.toString()) 
             
        // cancel the project
        const result2 = await freelancerInstance.cancelProject(projectCounter, {from: signer2})
        const event2 = result2.logs[0].args
        console.log("project Id: ", event2.projectId.toString())
        console.log("employee address : ", event2.employee)
        console.log("cancel date : ", event2.projectCancelDate.toString())

        let balance2 = await tokenInstance.balanceOf(signer2)
        console.log("balance 2 ", balance2.toString())
    })

    it("should create proposal", async() => {
        
        // create project
        let tokenValue = web3.utils.toWei("1000000000")
        await tokenInstance.approve(freelancerInstance.address, tokenValue, {from: signer2})

        let value = web3.utils.toWei("1")
        const result = await freelancerInstance.createProject(value, "2",
             tokenInstance.address.toString(), {from: signer2})
        const event = result.logs[0].args
        console.log("project Id: ", event.projectId.toString())
        console.log("employee address : ", event.employee)
        console.log("budget amount : ", event.budget.toString())
        console.log("project Type : ", event.projectType.toString())
        console.log("currency : ", event.currency)
        console.log("creation date : ", event.projectCreationDate.toString())

        const projectCounter = await freelancerInstance.projectCounter()
        console.log("project counter is ", projectCounter.toString())
        
        // create proposal
        const proposal = await freelancerInstance.createProposal(projectCounter, value, "15000", {from: signer3})
        const proposalCreated = proposal.logs[0].args
        console.log("project Id: ", proposalCreated.projectId.toString())
        console.log("freelancer: ", proposalCreated.freeLancer)
        console.log("proposed amount: ", proposalCreated.proposedAmount.toString())
        console.log("proposed time: ", proposalCreated.proposedTime.toString())
        console.log("proposal creation date: ", proposalCreated.proposalCreationDate.toString())
    })

    it("should implement a full no dispute project proceedure", async() => {
        
        // create project
        let tokenValue = web3.utils.toWei("1000000000")
        await tokenInstance.approve(freelancerInstance.address, tokenValue, {from: signer2})

        let value = web3.utils.toWei("1")
        const result = await freelancerInstance.createProject(value, "2",
             tokenInstance.address.toString(), {from: signer2})
        const event = result.logs[0].args
        console.log("project Id: ", event.projectId.toString())
        console.log("employee address : ", event.employee)
        console.log("budget amount : ", event.budget.toString())
        console.log("project Type : ", event.projectType.toString())
        console.log("currency : ", event.currency)
        console.log("creation date : ", event.projectCreationDate.toString())

        const projectCounter = await freelancerInstance.projectCounter()
        console.log("project counter is ", projectCounter.toString())
        
        // create proposal
        const proposal = await freelancerInstance.createProposal(projectCounter, value, "15000", {from: signer3})
        const proposalCreated = proposal.logs[0].args
        console.log("project Id: ", proposalCreated.projectId.toString())
        console.log("freelancer: ", proposalCreated.freeLancer)
        console.log("proposed amount: ", proposalCreated.proposedAmount.toString())
        console.log("proposed time: ", proposalCreated.proposedTime.toString())
        console.log("proposal creation date: ", proposalCreated.proposalCreationDate.toString())

        // accept proposal
        const accept = await freelancerInstance.acceptProposal(projectCounter, "0", {from: signer2})
        const proposalAccepted = accept.logs[0].args
        console.log("project Id: ", proposalAccepted.projectId.toString())
        console.log("proposal Id: ", proposalAccepted.proposalId.toString())
        console.log("accept date: ", proposalAccepted.acceptDate.toString())

        // deliver project
        const delivered = await freelancerInstance.deliverProject(projectCounter, "0", {from: signer3})
        const projectDelivered = delivered.logs[0].args
        console.log("project Id: ", projectDelivered.projectId.toString())
        console.log("proposal Id: ", projectDelivered.proposalId.toString())
        console.log("delivered date: ", projectDelivered.deliveredDate.toString())

        // finalize project
        const finalized = await freelancerInstance.finalizeProject(projectCounter, "0", {from: signer2})
        const projectFinalized = finalized.logs[0].args
        console.log("project Id: ", projectFinalized.projectId.toString())
        console.log("proposal Id: ", projectFinalized.proposalId.toString())
        console.log("finalized date: ", projectFinalized.finalizedDate.toString())

        let balanceEmployee = await tokenInstance.balanceOf(signer2)
        console.log("balanceEmployee  ", balanceEmployee.toString())

        let balanceEmployer = await tokenInstance.balanceOf(signer3)
        console.log("balanceEmployer  ", balanceEmployer.toString())
    })

    it("should implement a full project with arbitration", async() => {
        
        // create project
        let tokenValue = web3.utils.toWei("1000000000")
        await tokenInstance.approve(freelancerInstance.address, tokenValue, {from: signer2})

        let value = web3.utils.toWei("1")
        const result = await freelancerInstance.createProject(value, "2",
             tokenInstance.address.toString(), {from: signer2})
        const event = result.logs[0].args
        console.log("project Id: ", event.projectId.toString())
        console.log("employee address : ", event.employee)
        console.log("budget amount : ", event.budget.toString())
        console.log("project Type : ", event.projectType.toString())
        console.log("currency : ", event.currency)
        console.log("creation date : ", event.projectCreationDate.toString())

        const projectCounter = await freelancerInstance.projectCounter()
        console.log("project counter is ", projectCounter.toString())
        
        // create proposal
        const proposal = await freelancerInstance.createProposal(projectCounter, value, "15000", {from: signer3})
        const proposalCreated = proposal.logs[0].args
        console.log("project Id: ", proposalCreated.projectId.toString())
        console.log("freelancer: ", proposalCreated.freeLancer)
        console.log("proposed amount: ", proposalCreated.proposedAmount.toString())
        console.log("proposed time: ", proposalCreated.proposedTime.toString())
        console.log("proposal creation date: ", proposalCreated.proposalCreationDate.toString())

        // accept proposal
        const accept = await freelancerInstance.acceptProposal(projectCounter, "0", {from: signer2})
        const proposalAccepted = accept.logs[0].args
        console.log("project Id: ", proposalAccepted.projectId.toString())
        console.log("proposal Id: ", proposalAccepted.proposalId.toString())
        console.log("accept date: ", proposalAccepted.acceptDate.toString())

        // deliver project
        const delivered = await freelancerInstance.deliverProject(projectCounter, "0", {from: signer3})
        const projectDelivered = delivered.logs[0].args
        console.log("project Id: ", projectDelivered.projectId.toString())
        console.log("proposal Id: ", projectDelivered.proposalId.toString())
        console.log("delivered date: ", projectDelivered.deliveredDate.toString())

        // arbitration
        const arbitration = await freelancerInstance.arbitration(projectCounter, "0", "1", {from: signer1})
        const projectArbitrated = arbitration.logs[0].args
        console.log("project Id: ", projectArbitrated.projectId.toString())
        console.log("proposal Id: ", projectArbitrated.proposalId.toString())
        console.log("vote number: ", projectArbitrated.vote.toString())
        console.log("delivered date: ", projectArbitrated.arbitrationDate.toString())

        let balanceEmployee = await tokenInstance.balanceOf(signer2)
        console.log("balanceEmployee  ", balanceEmployee.toString())

        let balanceEmployer = await tokenInstance.balanceOf(signer3)
        console.log("balanceEmployer  ", balanceEmployer.toString())
    })

    it("should disable the project", async() => {

        // create project
        let tokenValue = web3.utils.toWei("1000000000")
        await tokenInstance.approve(freelancerInstance.address, tokenValue, {from: signer2})

        let value = web3.utils.toWei("1")
        const result = await freelancerInstance.createProject(value, "2",
             tokenInstance.address.toString(), {from: signer2})
        const event = result.logs[0].args
        console.log("project Id: ", event.projectId.toString())
        console.log("employee address : ", event.employee)
        console.log("budget amount : ", event.budget.toString())
        console.log("project Type : ", event.projectType.toString())
        console.log("currency : ", event.currency)
        console.log("creation date : ", event.projectCreationDate.toString())

        const projectCounter = await freelancerInstance.projectCounter()
        console.log("project counter is ", projectCounter.toString())

        const disable = await freelancerInstance.disableProject(projectCounter, {from: signer1})
        const projectDisabled = disable.logs[0].args
        console.log("project Id: ", projectDisabled.projectId.toString())
        console.log("disable date: ", projectDisabled.disableDate.toString())
        
    })
   
})

