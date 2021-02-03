// SPDX-License-Identifier: no-licence

pragma solidity ^0.8.1;

// reputation for freeLancer
contract Reputation {           
    
    // Reputation Variables
    struct WithoutDispute{
        address freeLancer;      // address freeLancer
    }
    // Reputation Variables
    struct EmployeeWonDispute{
        address freeLancer;      // address freeLancer
    }
    // Reputation Variables
    struct LancerWonDispute{
        address freeLancer;      // address freeLancer
    }
    
    mapping(address => WithoutDispute[]) withoutDispute;  // freeLancer => withoutDispute
    mapping(address => EmployeeWonDispute[]) employeeWonDispute;  // freeLancer => employeeWonDispute
    mapping(address => LancerWonDispute[]) lancerWonDispute;  // freeLancer => lancerWonDispute
    
    // Return the number of successful projects w/o dispute for spesific freeLancer
    // It is used to measure freeLancer's reputation
    function getWithoutDispute(address _freeLancer) external view returns (uint) {
        return withoutDispute[_freeLancer].length;
    }
    // Return the number of disputes that freeLancer won...
    function getLancerWonDispute(address _freeLancer) external view returns(uint) {
        return lancerWonDispute[_freeLancer].length;
    }
    // Return the number of disputes that freeLancer lost and employee won...
    // This number would be a negative point for freeLancer 
    function getLancerLostDispute(address _freeLancer) external view returns(uint) {
        return employeeWonDispute[_freeLancer].length;
    }
    
    // set reputation for no dispute finalization
    function setWithoutDispute(address _freeLancer) external {
        withoutDispute[_freeLancer].push(WithoutDispute({freeLancer: _freeLancer}));
    }
    
    // set reputation for dispute and lancer win
    function setLanserWonDispute(address _freeLancer) external {
        lancerWonDispute[_freeLancer].push(LancerWonDispute({freeLancer: _freeLancer}));
    }
    
    // set reputation for dispute and lancer lost
    function setLanserLostDispute(address _freeLancer) external {
        employeeWonDispute[_freeLancer].push(EmployeeWonDispute({freeLancer: _freeLancer}));
    }
}