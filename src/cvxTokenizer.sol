// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

//Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
import {ERC4626} from "@solmate/mixins/ERC4626.sol";
import {ICVXStakingContract} from "./Interfaces/ICVXStakingContract.sol";
import {IUniRouter} from "./Interfaces/IUniRouter.sol";
import {IERC20} from "@openzeppelin/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol"; 
 
abstract contract cvxTokenizer is ERC4626, Ownable {
    
    ICVXStakingContract cvxStaking = ICVXStakingContract(0xCF50b810E57Ac33B91dCF525C6ddd9881B139332);
    IUniRouter router = IUniRouter(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);
    IERC20 cvxCRV = IERC20(0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7);
    IERC20 CVX = IERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    address CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /**
    *Total CVX controlled by the contract is composed of:
    *totalAssets = pending rewards + staked CVX + CVX balance
    */
    function totalAssets() public view override returns (uint256){
        //Get outstanding cvxCRV rewards
        uint pendingRewards = calcOutstandingRewards();
        //Get outstanding reward value in CVX
        address[] memory route = new address[](4);
        route[0] = address(cvxCRV);
        route[1] = CRV;
        route[2] = WETH;
        route[3] = address(CVX);
        uint[] memory pendingCVX = router.getAmountsOut(pendingRewards, route);
        //Return total amount of earned CVX
	return(cvxStaking.balanceOf(address(this)) + CVX.balanceOf(address(this)) + pendingCVX[0]);
    }
    
    /**
    *Unstake CVX and convert cvxCRV to CVX
    */
    function beforeWithdraw(uint256 assets, uint256 shares) internal override {
        //withdraw assets from CVX Staking
        cvxStaking.withdraw(assets, true);
        
        //approve selling of cvxCRV via sushi router
        cvxCRV.approve(address(router),assets);
        
        //Swap cvxCRV for WETH
        address[] memory route = new address[](4);
        route[0] = address(cvxCRV);
        route[1] = CRV;
        route[2] = WETH;
        route[3] = address(CVX);
        router.swapExactTokensForTokens(assets, 0, route, address(this), block.timestamp + 1);
    }

    /**
    *Stake CVX
    */
    function afterDeposit(uint256 assets, uint256 shares) internal override {
        //approve transfer of CVX into staking contract
        CVX.approve(address(cvxStaking),assets);

        //deposit assets into CVX Staking
        cvxStaking.stake(assets, false);
    }

    /**
    *Calculate amount of cvxCRV that this contract has outstanding
    */
    function calcOutstandingRewards() internal view returns(uint){
        uint pendingRewardPerToken = (cvxStaking.rewardPerToken() - cvxStaking.userRewardPerTokenPaid(address(this)));
        uint outstandingRewards = (cvxStaking.balanceOf(address(this)) * pendingRewardPerToken / 1e18);
        return  outstandingRewards + cvxStaking.rewards(address(this));
    }

    /**
    *Withdraw any tokens that might airdropped or mistakenly be send to this address
    */
    function saveTokens(address _token, uint _amount) external onlyOwner{
        IERC20(_token).transfer(msg.sender, _amount);
    }
}
