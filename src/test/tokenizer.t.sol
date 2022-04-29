pragma solidity ^0.8.1;

import "ds-test/test.sol";
import "../cvxTokenizer.sol";
import "@solmate/tokens/ERC20.sol";
import {ICRVDepositor} from "../Interfaces/ICRVDepositor.sol";
import {ICVXStakingContract} from "../Interfaces/ICVXStakingContract.sol";

interface Cheats {
    function deal(address who, uint256 amount) external;
    function startPrank(address sender) external;
    function stopPrank() external;
    function roll(uint256) external;
    function warp(uint256) external;
}

/**
 * Helper contract for this project's tests
 */
contract TokenizerSetup is DSTest {
    
    cvxTokenizer public tokenizer;

    Cheats public cheats;

    ERC20 CVX = ERC20(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);
    ERC20 CRV = ERC20(0xD533a949740bb3306d119CC777fa900bA034cd52);
    ERC20 sCVX;
    ICVXStakingContract cvxStakerContract = ICVXStakingContract(0xCF50b810E57Ac33B91dCF525C6ddd9881B139332);
    ICRVDepositor CRVDepositor = ICRVDepositor(0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae);

    address Ben;
    address Anna;

    function setUp() public {
  	//Give Tester ETH
        cheats = Cheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        cheats.deal(address(this), 1000 ether);
	
	//Setup Test Users
	Anna = 0x601d14B29CB847206568D0aE322f23B32403247F;
        Ben = 0x5aE34F68cbeCCa41Dfdebed59156B9F90eb7514d;
	cheats.deal(Anna, 1000 ether);
	cheats.deal(Ben, 1000 ether);

	//Deploy tokenizer
	tokenizer = new cvxTokenizer();
    	sCVX = ERC20(address(tokenizer));
    }
	
    function testDeposit() public{
	uint sCVXBalanceBeforeDeposit = sCVX.balanceOf(address(this));
	depositCVX(1e18,address(this));
        uint sCVXBalanceAfterDeposit = sCVX.balanceOf(address(this));

	assertEq(sCVXBalanceBeforeDeposit+1e18,sCVXBalanceAfterDeposit);
    }

    function testWithdrawl() public {
	//Deposit CVX into tokenizer
	depositCVX(1e18,address(this));
	
	//CVX Earns Rewards
    	ConvexEarnsProfits(10000e18);
	cheats.warp(block.timestamp + 1000000);

	//Estimated user redeem amount
	uint estimatedAmount = tokenizer.previewRedeem(1e18);
	uint balanceBeforeRedeem = CVX.balanceOf(address(this));

	//Withdraw CVX + Rewards
 	tokenizer.redeem(1e18,address(this),address(this));
    	//emit log_named_uint("CVX after withdrawl: ",CVX.balanceOf(address(this)));
        uint balanceAfterRedeem = CVX.balanceOf(address(this));
	assertEq(balanceAfterRedeem-balanceBeforeRedeem,estimatedAmount);
    }

    function testMultiUserWithdraw() public {
	//Anna Deposits
	depositCVX(1e18,Anna);

	//CVX Earns Rewards
        ConvexEarnsProfits(10000e18);
        cheats.warp(block.timestamp + 1000000);

	//Ben Deposits
	depositCVX(1e18,Ben);

	//CVX Earns Rewards
        ConvexEarnsProfits(10000e18);
        cheats.warp(block.timestamp + 1000000);

	//Withdraw CVX + Rewards
	cheats.startPrank(Anna);

	//Estimated Anna redeem amount
        uint estimatedAmount = tokenizer.previewRedeem(1e18);
        uint balanceBeforeRedeem = CVX.balanceOf(Anna);

        tokenizer.redeem(1e18,Anna,Anna);
	uint balanceAfterRedeem = CVX.balanceOf(Anna);
	assertEq(balanceAfterRedeem-balanceBeforeRedeem,estimatedAmount);	
    	cheats.stopPrank();
    }

    function depositCVX(uint _amount, address _staker) public{
	receiveCVXFunds(_amount,_staker);
        cheats.startPrank(_staker);
	CVX.approve(address(tokenizer), _amount);
        tokenizer.deposit(_amount,_staker);
    	cheats.stopPrank();
    }

    //We're transfering tokens from the Binance wallet
    function receiveCVXFunds(uint _amount, address _staker) public {
        cheats.startPrank(0x28C6c06298d514Db089934071355E5743bf21d60);
        CVX.transfer(_staker, _amount);
        cheats.stopPrank();
    }
	
    //We transfer CRV from Binance wallet to CVX rewards contract
    function ConvexEarnsProfits(uint _amounts) public {
    	cheats.startPrank(0xD533a949740bb3306d119CC777fa900bA034cd52);
        CRV.transfer(address(cvxStakerContract),_amounts);
	//CRV.approve(address(CRVDepositor),type(uint).max);
	//CRVDepositor.deposit(_amounts, false, address(0));
	cheats.stopPrank();
    }
}

