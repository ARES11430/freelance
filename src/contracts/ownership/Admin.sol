// SPDX-License-Identifier: no-licence

pragma solidity ^0.8.1;

contract Admin {
    
    address owner;                      // address which sets admins
    mapping(address => bool) isAdmin;
    
    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function _msgSender() internal view returns (address) {                 // address of msg.sender
        return msg.sender;
    }

    function _msgValue() internal view returns (uint) {                     // amount of msg.value
        return msg.value;
    }

    modifier onlyOwner() {
        require(_msgSender() == owner, "You are not owner");
        _;
    }

    modifier validAdmin() {
        require(isAdmin[_msgSender()] == true || _msgSender() == owner, "You are not authorized");
        _;
    }

    constructor() {
        owner = _msgSender();
    }
    
    //Allows the current owner to transfer control of the contract to a newOwner.
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function addAdmin(address _admin) external onlyOwner {
        isAdmin[_admin] = true;
        emit AdminAdded(_admin);
    }

    function removeAdmin(address _admin) external onlyOwner {
        isAdmin[_admin] = false;
        emit AdminRemoved(_admin);
    }
    
    function checkAdmin(address _admin) external view onlyOwner returns(string memory) {
        
        if ( isAdmin[_admin] == true){
            return "This is admin";
        } 
        else return "This is not admin";
    }

}