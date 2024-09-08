//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import { MinimalAccount} from "../src/ethereum/MinimalAccount.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DeployMinimalAccount} from "../script/DeployMinimalAccount.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
contract MinimalAccountTest is Test{
    MinimalAccount minimalAccount;
    HelperConfig config;
    DeployMinimalAccount deployer;
    ERC20Mock usdc;

    uint256 constant AMOUNT = 1e18;


    function setUp() public {
        deployer = new DeployMinimalAccount();
        (config, minimalAccount) = deployer.run();

        usdc = new ERC20Mock();
    }

    //function execute(address destination, uint256 value, bytes calldata functionData
    function testOwnerCanExecuteCommands() public {
        //arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        //act
        vm.prank(minimalAccount.owner());
        minimalAccount.execute(destination, value, functionData);

        //assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }
}
