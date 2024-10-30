// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe; //store / state variable

    address USER = makeAddr("user"); //Cheatcode to generate a artificial address to test the contracts | only works with foundry
    uint256 constant START_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant GAS_PRICE = 1;

    // will be run before each test
    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, START_BALANCE); // CheatCode to add a Balance to the USER
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // the next line | TX should revert
        // assert(This tx fails/reverts) --> It is successful if it fails
        fundMe.fund(); // send 0 value
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //the next TX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFunderToArrayOfFunder() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(USER, funder);
    }

    // you can add modifier to test function (public funded) to execute it before the test
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

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
        assertEq(endingFundMeBalance, 0);
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10; // uint160 to generate an address using address(i) | not possible with uint256
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //hoax includes vm.prank and vm.default
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        //uint256 gasStart = gasleft();
        //vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); //alternative vm.startPrank() und vm.stopPrank
        fundMe.withdraw();
        //uint256 gasEnde = gasleft();
        //uint256 gasUsed = (gasStart - gasEnde) * tx.gasprice; //tx.gasprice is a buildin function to get current gas price
        //console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
        assertEq(endingFundMeBalance, 0);
    }

    function testCheaperWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10; // uint160 to generate an address using address(i) | not possible with uint256
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //hoax includes vm.prank and vm.default
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        //uint256 gasStart = gasleft();
        //vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); //alternative vm.startPrank() und vm.stopPrank
        fundMe.cheaperWithdraw();
        //uint256 gasEnde = gasleft();
        //uint256 gasUsed = (gasStart - gasEnde) * tx.gasprice; //tx.gasprice is a buildin function to get current gas price
        //console.log(gasUsed);

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
        assertEq(endingFundMeBalance, 0);
    }
}
