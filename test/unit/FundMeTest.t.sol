//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    DeployFundMe deployFundMe;
    address USER = makeAddr("USER"); //cheatcode in foundry to create a new address
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 100 ether;

    function setUp() external {
        // us -> FundMeTest -> FundMe  therefore the owner of FundMe is FundMeTest and not us
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumUsd() public {
        assertEq(fundMe.MINIMUM_USD(), 5 * 10 ** 18);
        //console.log("Minimum USD is: ", fundMe.MINIMUM_USD()); u need to include -vv to see the output of only 1 statement as 1 v
    }

    function testOwner() public {
        assertEq(fundMe.getOwner(), msg.sender); //address(this) is the address of the fundMetest, which deploys the fund me
    }

    function testPriceFeedVersion() public {
        console.log("Price Feed Version: ", fundMe.getVersion());
        assertEq(fundMe.getVersion(), 4);
    }

    function testfundFailsWithoutEnoughETH() public {
        //test in the beginning is important for function to be recognized as a test
        vm.expectRevert(); // the next line should revert for test to fail
        fundMe.fund(); //not sending anything , sens 0 value
    }

    function testFundUpdatesDS() public {
        vm.prank(USER); // next TX will be from USER
        fundMe.fund{value: SEND_VALUE}();
        assertEq(fundMe.getAddresstoAmountFunded(USER), SEND_VALUE);
        assertEq(fundMe.getFunder(0), USER); //we had to use prank USER because the fund TX was done by testFundMe contract and not msg.sender
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Account
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawWithMultipleFunders() public {
        // prank and deal can be combined with hoax
        //address(i) can be used to create an address
        uint256 numberOfFunders = 10;
        uint160 startingIndex = 1;
        for (uint160 i = startingIndex; i <= numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Account
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank(); //works same as start and stop broadcast

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    //running forge test with --fork-url enables us to run the test on a simulated network
}
