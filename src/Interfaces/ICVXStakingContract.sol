// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ICVXStakingContract {
    function withdraw(uint256 _amount, bool claim) external;
    function stake(uint _amount, bool claim) external;
    function balanceOf(address) external view returns(uint);
    function rewardPerToken() external view returns(uint);
    function userRewardPerTokenPaid(address) external view returns(uint);
    function rewards(address) external view returns(uint);
}
