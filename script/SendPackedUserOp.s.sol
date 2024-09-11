//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { IEntryPoint } from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title SendPackedUserOp
 * @dev This contract generates and signs a `PackedUserOperation` according to EIP-4337.
 */
contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    function run() public { }

    /**
     * @notice Generates and signs a `PackedUserOperation` for a given minimal account.
     * @param callData The calldata to be included in the user operation.
     * @param config The network configuration for the operation (`entryPoint` and `account`).
     * @param minimalAccount The address of the account to generate the operation for.
     * @return A signed `PackedUserOperation` with the provided details.
     */
    function generatedSignedUserOperation(
        bytes memory callData,
        HelperConfig.NetworkConfig memory config,
        address minimalAccount
    )
        public
        view
        returns (PackedUserOperation memory)
    {
        //1. generate the unsigned data
        uint256 nonce = vm.getNonce(minimalAccount) - 1;
        PackedUserOperation memory userOp = _generateUnsignedUserOperation(callData, minimalAccount, nonce);

        //2 get the userOp Hash
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(userOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        //3. sign it and return it
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 ANVIL_DEFAULT_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        if (block.chainid == 31_337) {
            (v, r, s) = vm.sign(ANVIL_DEFAULT_KEY, digest);
        } else {
            (v, r, s) = vm.sign(config.account, digest);
        }

        userOp.signature = abi.encodePacked(r, s, v); //Note the order of r,s,v is different from asigning
            // variables (uint8 v, bytes32 r, bytes32 s)
        return userOp;
    }

    /**
     * @notice Generates an unsigned `PackedUserOperation` for a given sender and calldata.
     * @param callData The calldata to be included in the user operation.
     * @param sender The address of the sender for the operation.
     * @param nonce The nonce of the user operation.
     * @return A `PackedUserOperation` without a signature.
     */
    function _generateUnsignedUserOperation(
        bytes memory callData,
        address sender,
        uint256 nonce
    )
        internal
        pure
        returns (PackedUserOperation memory)
    {
        uint128 verificationGasLimit = 16_777_216;
        uint128 callGasLimit = verificationGasLimit;
        uint128 maxPriorityFeePerGas = 256;
        uint128 maxFeePerGas = maxPriorityFeePerGas;

        /**
         * struct PackedUserOperation {
         * address sender;
         * uint256 nonce;
         * bytes initCode;
         * bytes callData;
         * bytes32 accountGasLimits;
         * uint256 preVerificationGas;
         * bytes32 gasFees;
         * bytes paymasterAndData;
         * bytes signature;
         * }
         */
        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32(uint256(callGasLimit) << 128 | callGasLimit),
            preVerificationGas: verificationGasLimit,
            gasFees: bytes32(uint256(maxPriorityFeePerGas) << 128 | maxPriorityFeePerGas),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
