//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { MinimalAccount } from "../src/ethereum/MinimalAccount.sol";
import { HelperConfig } from "../script/HelperConfig.s.sol";
import { SendPackedUserOp, PackedUserOperation } from "../script/SendPackedUserOp.s.sol";
import { DeployMinimalAccount } from "../script/DeployMinimalAccount.s.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IEntryPoint } from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MinimalAccountTest is Test {
    using MessageHashUtils for bytes32;

    MinimalAccount minimalAccount;
    HelperConfig config;
    DeployMinimalAccount deployer;
    ERC20Mock usdc;
    SendPackedUserOp sendPackedUserOp;

    address randomUser = makeAddr("randomUser");

    uint256 constant AMOUNT = 1e18;

    function setUp() public {
        deployer = new DeployMinimalAccount();
        (config, minimalAccount) = deployer.run();

        usdc = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
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

    function testNonOwnerCannotExecuteCommands() public {
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        //act
        vm.prank(randomUser);
        vm.expectRevert(MinimalAccount.MinimalAccount__NotFromEntryPointOrOwner.selector);
        minimalAccount.execute(destination, value, functionData);
    }

    function testRecoverSignedOp() public {
        //arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        //This line is basically saying: Heyy entryPoint contract call our contract and then our contract call usdc.mint
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, destination, value, functionData);
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generatedSignedUserOperation(executeCalldata, config.getConfig());

        bytes32 userOpHash = IEntryPoint(config.getConfig().entryPoint).getUserOpHash(packedUserOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        //act
        address actualSigner = ECDSA.recover(digest, packedUserOp.signature);

        //assert
        assertEq(actualSigner, minimalAccount.owner());
    }

    // sign userOp
    // call validateUserOp
    // assert the return is correct
    function testValidationOfUserOp() executeCommands public {
        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata = abi.encodeWithSelector(MinimalAccount.execute.selector, destination, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generatedSignedUserOperation(executeCalldata, config.getConfig());
        bytes32 userOpHash = IEntryPoint(config.getConfig().entryPoint).getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = 1e18;

        //Act
        vm.prank(address(config.getConfig().entryPoint));
        uint256 validationData = minimalAccount.validateUserOp(packedUserOp, userOpHash, missingAccountFunds);
        assertEq(validationData, 0);
    }

    function testEntryPointCanExecuteCommands() public {
        //arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata = abi.encodeWithSelector(MinimalAccount.execute.selector, destination, value, functionData);
        PackedUserOperation memory packedUserOp = sendPackedUserOp.generatedSignedUserOperation(executeCalldata, config.getConfig());

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        //-> tenemos que fondear minimalAccount
        vm.deal(address(minimalAccount), 1e18);

        //act > aqui vamos a probar que un usuario random "cualquier alt mempol node" puede submit al entryPoint, siempre y cuando nosotros ayamos firmado cualquiera puede enviar una tx
        vm.prank(randomUser);
        IEntryPoint(config.getConfig().entryPoint).handleOps(ops, payable(randomUser));

        //assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }
}
