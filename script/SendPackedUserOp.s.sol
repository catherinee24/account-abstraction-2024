//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { IEntryPoint } from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract SendPackedUserOp is Script {
    using MessageHashUtils for bytes32;

    function run() public { }

    function generatedSignedUserOperation(
        bytes memory callData,
        HelperConfig.qNetworkConfig memory config
    )
        public
        view
        returns (PackedUserOperation memory)
    {
        //1. generate the unsigned data
        uint256 nonce = vm.getNonce(config.account);
        PackedUserOperation memory unsignedUserOp = _generateUnsignedUserOperation(callData, config.account, nonce);

        //2 get the userOp Hash
        bytes32 userOpHash = IEntryPoint(config.entryPoint).getUserOpHash(unsignedUserOp);
        bytes32 digest = userOpHash.toEthSignedMessageHash();

        //3. sign it and return it
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(config.account, digest);
        unsignedUserOp.signature = abi.encodePacked(r, s, v); //Note the order of r,s,v is different from asigning
            // variables (uint8 v, bytes32 r, bytes32 s)
        return unsignedUserOp;
    }

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
