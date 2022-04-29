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
    ICVXStakingContract cvxStakerContract = ICVXStakingContract(0xCF50b810E57Ac33B91dCF525C6ddd9881B139332);
    ICRVDepositor CRVDepositor = ICRVDepositor(0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae);

    function setUp() public {
  	//Give Tester ETH
        cheats = Cheats(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
        cheats.deal(address(this), 1000 ether);
	
	//Deploy tokenizer
	tokenizer = new cvxTokenizer();
    }
	
    function testDeposit() public{
        getCVX();
        CVX.approve(address(tokenizer), type(uint256).max);
        tokenizer.deposit(1e18,address(this));
	
    }

    function testWithdrawl() public {
        emit log_named_uint("CVX before deposit: ",CVX.balanceOf(address(this)));
	testDeposit();
	emit log_named_uint("CVX after deposit: ",CVX.balanceOf(address(this)));
	//cheats.roll(block.number+10);
	cheats.warp(block.timestamp + 1000000);
    	ConvexEarnsProfits(10000e18);
	cheats.warp(block.timestamp + 1000000);
        //emit log_named_uint("totalAssets(): ",tokenizer.totalAssets());
 	tokenizer.redeem(1e18,address(this),address(this));
    	emit log_named_uint("CVX after withdrawl: ",CVX.balanceOf(address(this)));
    }

    //We're transfering tokens from the Binance wallet
    function getCVX() public {
        cheats.startPrank(0x28C6c06298d514Db089934071355E5743bf21d60);
        CVX.transfer(address(this), 1000000e18);
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

