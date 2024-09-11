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

    /**
     * @dev Tests that the owner of the `MinimalAccount` contract can execute commands.
     * Verifies that the USDC balance of the `MinimalAccount` increases after executing the mint command.
     */
    function testOwnerCanExecuteCommands() public {
        //arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);

        //function execute(address destination, uint256 value, bytes calldata functionData
        //act
        vm.prank(minimalAccount.owner());
        minimalAccount.execute(destination, value, functionData);

        //assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }

    /**
     * @dev Tests that a non-owner cannot execute commands on the `MinimalAccount` contract.
     * Expects a revert if a non-owner tries to execute a command.
     */
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

    /**
     * @dev Tests the recovery of the signed operation.
     * Verifies that the signature of a `PackedUserOperation` matches the expected owner's address.
     */
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
            sendPackedUserOp.generatedSignedUserOperation(executeCalldata, config.getConfig(), address(minimalAccount));

        bytes32 userOpHash = IEntryPoint(config.getConfig().entryPoint).getUserOpHash(packedUserOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        //act
        address actualSigner = ECDSA.recover(digest, packedUserOp.signature);

        //assert
        assertEq(actualSigner, minimalAccount.owner());
    }

    /**
     * @dev Tests the validation of a `PackedUserOperation`` by the `MinimalAccount` contract.
     * Verifies that the `validateUserOp` function returns the expected validation result.
     * This is intended to be called by the `EntryPoint` contract.
     */
    function testValidationOfUserOp() public {
        // sign userOp
        // call validateUserOp
        // assert the return is correct

        // Arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, destination, value, functionData);
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generatedSignedUserOperation(executeCalldata, config.getConfig(), address(minimalAccount));
        bytes32 userOpHash = IEntryPoint(config.getConfig().entryPoint).getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = 1e18;

        //Act
        vm.prank(address(config.getConfig().entryPoint));
        uint256 validationData = minimalAccount.validateUserOp(packedUserOp, userOpHash, missingAccountFunds);
        /**
         * this 0 represents the success of the validation SIG_VALIDATION_SUCCESS =  { SIG_VALIDATION_FAILED,
         * SIG_VALIDATION_SUCCESS } from "lib/account-abstraction/contracts/core/Helpers.sol"
         */
        assertEq(validationData, 0);
    }

    /**
     * @dev Tests that the `EntryPoint` contract can execute commands using a signed `PackedUserOperation`.
     * Verifies that the `USDC` balance of `MinimalAccount` increases after handling the operation by `EntryPoint`.
     */
    function testEntryPointCanExecuteCommands() public {
        //arrange
        assertEq(usdc.balanceOf(address(minimalAccount)), 0);
        address destination = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(minimalAccount), AMOUNT);
        bytes memory executeCalldata =
            abi.encodeWithSelector(MinimalAccount.execute.selector, destination, value, functionData);
        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generatedSignedUserOperation(executeCalldata, config.getConfig(), address(minimalAccount));

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        //-> tenemos que fondear minimalAccount para asegurarnos de prefondear la tx. _payPrefund()
        vm.deal(address(minimalAccount), 1e18);

        //act > aqui vamos a probar que un usuario random "cualquier alt mempol node" puede submit al entryPoint,
        // siempre y cuando nosotros hayamos firmado, cualquiera puede enviar una tx.
        vm.prank(randomUser);
        IEntryPoint(config.getConfig().entryPoint).handleOps(ops, payable(randomUser));

        //assert
        assertEq(usdc.balanceOf(address(minimalAccount)), AMOUNT);
    }
}
