// SPDX-License-Identifier: no-licence

pragma solidity ^0.8.1;

import "../token/IERC20.sol";
import "../ownership/Admin.sol";
import "../reputation/Reputation.sol";
import "../lib/SafeMath.sol";

contract Freelancer is Admin {
    
    // address ether :0x0000000000000000000000000000000000000000
    
    using SafeMath for *;
    
    uint constant private ESCROW_PERCENTAGE = 10;
    uint constant private PENALTY_PERCENTAGE = 10;
    
    // type of project
    enum ProjectType {Programing, Art, Translate, Graphics, Marketing, Others} 
    
    // Project made by employee
    struct Project {
        uint projectId;         // id
        uint budget;            // amount of budged payed by employee
        uint escrow;            // escrow saved by employee 
        address employee;       // address employee
        address employer;       // address accpeted freeLancer (default is null)
        uint deliveredDate;     // delivered date of project by freeLancer
        ProjectType projectType;
        IERC20 currency;
        uint8 status;   // 0: created, 1: inProgress , 2: finished , 3: disabled, 4: canceled by user, 5: delivered
        bool isCurrencyEther;
    }
    
    // proposal made by freeLancer
    struct Proposal {
        address freeLancer;
        uint proposedTime;          // offered time requires to finish project in seconds 
        uint proposedAmout;
        uint acceptedDate;          // acceptedDate 
        uint8 status;               // 0: not accepted, 1: accepted
    }
    
    // global project counter in smart contract
    uint public projectCounter = 0;     
    
    // address which used to recieve payments
    address wallet;                

    // global object of reputation
    Reputation reputation;  
    
    // project instance
    Project projectInstance;
    
    // proposal instance
    Proposal proposalInstance;
    
    mapping (uint => Project) projects;     // projectId => Project
    mapping (uint => Proposal[]) proposals;    // projectId => Proposal
    
    constructor(address _reputation, address _wallet) {
        owner = _msgSender();
        reputation = Reputation(_reputation);
        wallet = _wallet;
    }
    
    // view functions
    // shows the owner address
    function getOwner() external validAdmin view returns(address) {
        return owner;
    }
    
    // shows the current owner wallet
    function showWallet() external view validAdmin returns(address) {       
        return wallet;
    }
    
    
    // changes the current owner wallet
    function changeWallet(address _newWallet) external onlyOwner {          
        emit WalletChanged(wallet, _newWallet, block.timestamp);
        wallet = _newWallet;
    }
    
    // employee creates new project
    function createProject(uint _budget, ProjectType _projectType, IERC20 _currency) external payable {
        
        require(_budget >= 100 ,"invalid amount");
        // payment calculations
        uint x = SafeMath.div(_budget, 100);
        uint _escrow = SafeMath.mul(x, ESCROW_PERCENTAGE);
        uint payment = SafeMath.add(_budget, _escrow);
        
        projectInstance.projectId = SafeMath.add(projectCounter, 1);
        projectInstance.budget = _budget;
        projectInstance.escrow = _escrow;
        projectInstance.employee = _msgSender();
        projectInstance.employer = address(0x0);
        projectInstance.deliveredDate = 0;
        projectInstance.projectType = _projectType;
        projectInstance.currency = _currency;
        projectInstance.status = 0;
        projectInstance.isCurrencyEther = true;
        
        // use ether
        if (address(_currency) == address(0x0)) {   
            require(_msgValue() == payment, "Coin value doesn't match offer");
            // create new project and insert it in projects
            projects[SafeMath.add(projectCounter, 1)] = projectInstance;
            // deposit ether in project
            emit CoinTransferred(_msgSender(), address(this), payment);
        }
        // use Token
        else { 
            require(_msgValue() == 0, "Coin would be lost");
            
            projectInstance.isCurrencyEther = false;
            
            projects[SafeMath.add(projectCounter, 1)] = projectInstance;
            // deposit token in project
            require(_currency.transferFrom(_msgSender(), address(this), payment),"transferFrom failed");
            emit TokenTransferred(_msgSender(), address(this),_currency ,payment);
        }
        
        // increase the projectId for next project
        projectCounter = SafeMath.add(projectCounter, 1);  
        emit ProjectCreated(projectCounter, _msgSender(), _budget, _projectType, _currency, block.timestamp);
    }
    
    // disable Project and withdraw budget and escrow
    function cancelProject(uint _projectId) external {      // only employee
        
        Project storage project = projects[_projectId];
        require(project.status == 0, "This project cannot be deleted");
        require(_msgSender() == project.employee, "You are not employee of this project");
        
        // no reentrancy attack
        uint payment = SafeMath.add(project.budget, project.escrow);
        project.budget = 0;
        require(payment != 0, "You have already withdrawn");
        
        // use ether
        if (project.isCurrencyEther == true) {
            // pay employee
            payable(project.employee).transfer(payment); 
            emit CoinTransferred(address(this), project.employee, payment);
        }
        // use token
        else if (project.isCurrencyEther == false) {
            // pay employee
            require(project.currency.transfer(project.employee, payment),"transfer token failed");
            emit TokenTransferred(address(this), project.employee, project.currency, payment);
        }
        // set status to canceled by user
        project.status = 4;
        emit ProjectCanceled(_projectId, project.employee, block.timestamp);
    }
    
    // freeLancers create proposals
    function createProposal(uint _projectId, uint _proposedAmount, uint _proposedTime) external {
        
        Project memory project = projects[_projectId];
        require(_msgSender() != project.employee, "You cannot propose on your own project");
        require(project.status == 0, "This project cannot accept proposals anymore");
        require(_proposedAmount <= project.budget, "You cannot propose more than budget");
        require(_proposedTime > 0, "invalid Amount");
        
        proposalInstance.freeLancer = _msgSender();
        proposalInstance.proposedTime = _proposedTime;
        proposalInstance.proposedAmout = _proposedAmount;
        proposalInstance.acceptedDate = 0;
        proposalInstance.status = 0;
        
        // create proposals for spesific project
        proposals[project.projectId].push(proposalInstance);
        
        emit ProposalCreated(_projectId, _msgSender(), _proposedAmount, _proposedTime, block.timestamp);
    }
    
    // employee accpets certain proposal
    function acceptProposal(uint _projectId, uint _proposalId) external {
        
        Proposal storage proposal = proposals[_projectId][_proposalId];
        Project storage project = projects[_projectId];
        
        require(_msgSender() == project.employee, "You are not employee of this project");
        require(proposal.status == 0, "This proposal is already accepted");
        require(project.status == 0, "This project cannot accept proposals anymore");
        require(proposal.proposedAmout <= project.budget, "You don't have enough budget, please add more");
        
        // set employer in project
        project.employer = proposal.freeLancer;
        // set project status to inProgress
        project.status = 1;
        // set proposal status to accepted
        proposal.status = 1;
        // set proposal accept date
        proposal.acceptedDate = block.timestamp;
        
        emit ProposalAccepted(_projectId, _proposalId, proposal.acceptedDate);
    }
    
    // freeLancer call this function and deliver the Project
    function deliverProject(uint _projectId, uint _proposalId) external {
        
        Proposal memory proposal = proposals[_projectId][_proposalId];
        Project storage project = projects[_projectId];
        require(_msgSender() == project.employer && _msgSender() == proposal.freeLancer
        , "You are not freeLancer of this project");
        require(proposal.status == 1, "Your proposal is not accepted yet");
        require(project.status == 1, "You cannot deliver this project any more");
        // set deliver date
        project.deliveredDate = block.timestamp;
        // set delivered status
        project.status = 5;
        
        emit ProjectDelivered(_projectId, _proposalId, block.timestamp);
    }
    
    // employee finalizes the Project
    function finalizeProject(uint _projectId, uint _proposalId) external {
        
        Project storage project = projects[_projectId];
        Proposal storage proposal = proposals[_projectId][_proposalId];
        require(_msgSender() == project.employee, "You are not employee of this project"); 
        require(proposal.status == 1, "You cannot finalize yet");
        require(project.status != 2, "already finalized");
        require(project.status == 5, "project is not delivered yet");
    
        // calculate exceeded budget 
        uint exceedAmount = SafeMath.sub(project.budget, proposal.proposedAmout);
        
        // no reentrancy attack
        uint payment = proposal.proposedAmout;
        project.budget = 0;
        proposal.proposedAmout = 0;
        require(payment != 0, "No multiple withdraw !");
        
        // no reentrancy attack
        uint escrowPayment = SafeMath.add(project.escrow, exceedAmount);
        project.escrow = 0;
        require(escrowPayment != 0, "No multiple withdraw !");
        
        // timeWindow for delivering project without penalty
        uint timeWindow = SafeMath.add(proposal.acceptedDate, proposal.proposedTime); 
        
        // calculations for penalty
        // %PENALTY_PERCENTAGE penalty subtracted from freeLancer and added to employee
        uint x = SafeMath.div(payment, 100);
        uint penaltyAmount = SafeMath.mul(x, PENALTY_PERCENTAGE);
                
        uint freeLancerPayment = SafeMath.sub(payment, penaltyAmount);
        require(freeLancerPayment != 0, "No multiple withdraw !");
        
        uint employeePayment = SafeMath.add(escrowPayment, penaltyAmount);
        require(employeePayment != 0, "No multiple withdraw !");
        
        // use ether
        if (project.isCurrencyEther == true) {  
            
            // late delivered
            if (timeWindow <= project.deliveredDate) {
                // pay freeLancer
                payable(proposal.freeLancer).transfer(freeLancerPayment);
                emit CoinTransferred(address(this), proposal.freeLancer, freeLancerPayment);
                // pay to employee
                payable(project.employee).transfer(employeePayment);
                emit CoinTransferred(address(this), project.employee, employeePayment);
            }
            // regular delivered
            else {
                // pay freeLancer
                payable(proposal.freeLancer).transfer(payment); 
                emit CoinTransferred(address(this), proposal.freeLancer, payment);
                // pay to employee
                payable(project.employee).transfer(escrowPayment);
                emit CoinTransferred(address(this), project.employee, escrowPayment);
            }
        }
        // use tokens
        else if (project.isCurrencyEther == false) {
            
            // late delivered
            if (timeWindow <= project.deliveredDate) {
                // pay freeLancer
                require(project.currency.transfer(proposal.freeLancer, freeLancerPayment),"transfer token failed");
                emit TokenTransferred(address(this), proposal.freeLancer, project.currency, freeLancerPayment);
                // pay to employee
                require(project.currency.transfer(project.employee, employeePayment),"transfer token failed");
                emit TokenTransferred(address(this), project.employee, project.currency, employeePayment);
            }
            // regular delivered
            else {
                // pay freeLancer
                require(project.currency.transfer(proposal.freeLancer, payment),"transfer token failed");
                 emit TokenTransferred(address(this), proposal.freeLancer, project.currency, payment);
                // pay to employee
                require(project.currency.transfer(project.employee, escrowPayment),"transfer token failed");
                emit TokenTransferred(address(this), project.employee, project.currency, escrowPayment);
            }
        }
        // set status to finished
        project.status = 2;
        // set reputation point
        reputation.setWithoutDispute(project.employer);
        
        emit ProjectFinalized(_projectId, _proposalId, block.timestamp);
    }

    // admins use this for dispute resolution
    function arbitration(uint _projectId, uint _proposalId, uint _vote) external validAdmin {
        // vote 1: employee, vote 2: freeLancer
        
        Project storage project = projects[_projectId];
        Proposal memory proposal = proposals[_projectId][_proposalId];
        require(project.status != 2, "already finalized");
        require(proposal.status == 1, "This proposal is not accpted");
        require(project.status == 1 || project.status == 5, "This project is not inProgress any more");
        
        // calculate exceeded budget 
        uint exceedAmount = SafeMath.sub(project.budget, proposal.proposedAmout);
        // no reentrancy attack
        uint payment = proposal.proposedAmout;
        project.budget = 0;
        proposal.proposedAmout = 0;
        require(payment != 0, "No multiple withdraw !");
        
        // no reentrancy attack
        uint escrowPayment = project.escrow;
        project.escrow = 0;
        require(escrowPayment != 0, "No multiple withdraw !");
        
        // employee won disputation
        if(_vote == 1) {
            
            // pay employee
            uint employeePayment = SafeMath.add(payment, exceedAmount);
            // use ether
            if (project.isCurrencyEther == true) {  
               
                // pay employee
                payable(project.employee).transfer(employeePayment); 
                emit CoinTransferred(address(this), project.employee, employeePayment);
                // pay project escrow as arbitration commission to marketplace owner
                payable(wallet).transfer(escrowPayment);
                emit CoinTransferred(address(this), wallet, escrowPayment);
            }
            // use tokens
            else if (project.isCurrencyEther == false) {
                // pay employee
                require(project.currency.transfer(project.employee, employeePayment),"transfer token failed");
                emit TokenTransferred(address(this), project.employee, project.currency, employeePayment);
                // pay project escrow as arbitration commission to marketplace owner
                require(project.currency.transfer(wallet, escrowPayment),"transfer token failed");
                emit TokenTransferred(address(this), wallet, project.currency, escrowPayment);
            }
            // set status to finished
            project.status = 2;
            // set reputation point
            reputation.setLanserLostDispute(project.employer);
        }
        // freeLancer won disputation
        else if (_vote == 2) {
            
            // pay freeLancer
            uint freeLancerPayment = SafeMath.add(payment, exceedAmount);
            // use ether
            if (project.isCurrencyEther == true) {  
                // pay freeLancer
                payable(proposal.freeLancer).transfer(freeLancerPayment);
                emit CoinTransferred(address(this), proposal.freeLancer, freeLancerPayment);
                // pay project escrow as arbitration commission to marketplace owner
                payable(wallet).transfer(escrowPayment);
                emit CoinTransferred(address(this), wallet, escrowPayment);
            }
            // use tokens
            else if (project.isCurrencyEther == false) {
                // pay freeLancer
                require(project.currency.transfer(proposal.freeLancer, freeLancerPayment),"transfer token failed");
                emit TokenTransferred(address(this), proposal.freeLancer, project.currency, freeLancerPayment);
                // pay project escrow as arbitration commission to marketplace owner
                require(project.currency.transfer(wallet, escrowPayment),"transfer token failed");
                emit TokenTransferred(address(this), wallet, project.currency, escrowPayment);
            }
            // set status to finished
            project.status = 2;
            // set reputation point
            reputation.setLanserWonDispute(project.employer);
        }
        emit ProjectArbitrated(_projectId, _proposalId, _vote, block.timestamp);
    }
    
    // admin can ban projects violating rules and take escrow as penalty
    function disableProject(uint _projectId) external validAdmin {
        
        Project storage project = projects[_projectId];
        require(project.status != 3, "already banned");
        require(project.status == 0 || project.status == 1,
        "This project is finished, banned, delivered or canceled");
        
        // no reentrancy attack
        uint payment = project.budget;
        project.budget = 0;
        require(payment != 0, "No multiple withdraw !");
        
        // no reentrancy attack
        uint escrowPayment = project.escrow;
        project.escrow = 0;
        require(escrowPayment != 0, "No multiple withdraw !");
        // use ether
        if (project.isCurrencyEther == true) {  
            // pay employee
            payable(project.employee).transfer(payment); 
            emit CoinTransferred(address(this), project.employee, payment);
            // pay project escrow to marketplace owner as penalty to rule violation
            payable(wallet).transfer(escrowPayment);
            emit CoinTransferred(address(this), wallet, escrowPayment);
        }
        // use tokens
        else if (project.isCurrencyEther == false) {
            // pay employee
            require(project.currency.transfer(project.employee, payment),"transfer token failed");
            emit TokenTransferred(address(this), project.employee, project.currency, payment);
            // pay project escrow to marketplace owner as penalty to rule violation
            require(project.currency.transfer(wallet, escrowPayment),"transfer token failed");  
            emit TokenTransferred(address(this), wallet, project.currency, escrowPayment);
        }
        // set project status to banned 
        project.status = 3;
        
        emit ProjectDisabled(_projectId, block.timestamp);
    }
    
    event CoinTransferred(address indexed sender, address indexed receiver, uint value);
    event TokenTransferred(address indexed sender, address indexed receiver, IERC20 currency, uint value); 
    event WalletChanged(address indexed oldWallet, address indexed newWallet, uint walletChangeDate);
    event ProjectCreated(uint indexed projectId, address indexed employee, uint budget, ProjectType projectType, IERC20 currency, uint projectCreationDate);
    event ProjectCanceled(uint indexed projectId, address indexed employee, uint projectCancelDate);
    event ProposalCreated(uint indexed projectId, address indexed freeLancer, uint proposedAmount, uint proposedTime, uint proposalCreationDate);
    event ProposalAccepted(uint indexed projectId, uint indexed proposalId, uint acceptDate);
    event ProjectDelivered(uint indexed projectId, uint indexed proposalId, uint deliveredDate);
    event ProjectFinalized(uint indexed projectId, uint indexed proposalId, uint finalizedDate);
    event ProjectArbitrated(uint indexed projectId, uint indexed proposalId, uint vote, uint arbitrationDate);
    event ProjectDisabled(uint indexed projectId, uint disableDate);
}