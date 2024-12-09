//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {Test, console} from "forge-std/Test.sol";

contract InteractionsTest is Test {
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

    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();

        // vm.prank(USER); // next TX will be from USER

        fundFundMe.fundFundMe(address(fundMe));
        //fundFundMe.runFund();
        assertEq(fundMe.getAddresstoAmountFunded(msg.sender), SEND_VALUE);
        assertEq(fundMe.getFunder(0), msg.sender); //we had to use prank USER because the fund TX was done by testFundMe contract and not msg.sender
    }

    // modifier funded() {
    //     vm.prank(USER);
    //     fundFundMe.runFund();
    //     _;
    // }

    function testOwnerCanWithdrawInteractions() public {
        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Account
        //vm.prank(fundMe.getOwner());
        withdrawFundMe.withdrawFundMe(address(fundMe));

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }
}
