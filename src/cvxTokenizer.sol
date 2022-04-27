// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

//Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/mixins/ERC4626.sol)
import {ERC4626} from "@solmate/mixins/ERC4626.sol";
import {ICVXStakingContract} from "../Interfaces/IcvxStakingCOntract";
 
abstract contract cvxTokenizer is ERC4626 {
    
    ICVXStakingContract cvxStaking = ICVXStakingContract(0xCF50b810E57Ac33B91dCF525C6ddd9881B139332)
    
    function totalAssets() public view override returns (uint256){
        returns ICVXStakingContract.balanceOf(address.this);
    }

    function beforeWithdraw(uint256 assets, uint256 shares) internal override returns (uint256){
        //withdraw assets from CVX Staking
        ICVXStakingContract.withdraw(assets, bool claim);
        //Sell rewards
        

        return()
    }

    function afterDeposit(uint256 assets, uint256 shares) internal override returns (uint256){
        //deposit assets into CVX Staking
    }
}
