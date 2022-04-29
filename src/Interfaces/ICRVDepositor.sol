pragma solidity 0.8.1;

interface ICRVDepositor {
     function deposit(uint256 _amount, bool _lock, address _stakeAddress) external; 
}
