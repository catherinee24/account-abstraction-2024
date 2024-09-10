//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IAccount } from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS } from "lib/account-abstraction/contracts/core/Helpers.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IEntryPoint } from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

/**
 * @author: CatellaTech
 * @author: Original work by Cyfrin Updraft 
 * @title MinimalAccount
 * @notice This contract implements a minimalistic version of an Account Abstraction according to EIP-4337.
 * It allows executing transactions through the `EnntryPoint` and validating user operations.
 */
contract MinimalAccount is IAccount, Ownable {
    /*/////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                ERRORS
    /////////////////////////////////////////////////////////////////////////////////////////////////////////*/
    error MinimalAccount__NotFromEntryPoint();
    error MinimalAccount__NotFromEntryPointOrOwner();
    error MinimalAccount__CallFailed(bytes);
    /*/////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                STATE VARIABLES 
    /////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    IEntryPoint private immutable i_entryPoint;

    /*/////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                 MODIFIERS
    /////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    modifier requireFromEntryPoint() {
        if (msg.sender != address(i_entryPoint)) {
            revert MinimalAccount__NotFromEntryPoint();
        }
        _;
    }

    modifier requireFromEntryPointOrOwner() {
        if (msg.sender != address(i_entryPoint) && msg.sender != owner()) {
            revert MinimalAccount__NotFromEntryPointOrOwner();
        }
        _;
    }
    /*/////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                CONSTRUCTOR
    /////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    constructor(address entryPoint) Ownable(msg.sender) {
        i_entryPoint = IEntryPoint(entryPoint);
    }

    /**
     * @notice Fallback function to receive Ether.
     */
    receive() external payable { }
    /*/////////////////////////////////////////////////////////////////////////////////////////////////////////
                                         EXTERNAL AND PULIC FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////////////////////////////////*/
    /**
     * @notice Executes a transaction to the specified destination.
     * @param destination The address to send the call.
     * @param value The amount of Ether to send.
     * @param functionData The data to be sent in the call.
     */

    function execute(
        address destination,
        uint256 value,
        bytes calldata functionData
    )
        external
        requireFromEntryPointOrOwner
    {
        (bool success, bytes memory result) = destination.call{ value: value }(functionData);

        if (!success) {
            revert MinimalAccount__CallFailed(result);
        }
    }

    /**
     * @notice Validates a User Operation and pre-funds the transaction if necessary.
     * @param userOp The packed user operation.
     * @param userOpHash The hash of the user operation.
     * @param missingAccountFunds The missing amount of funds to pre-fund the operation.
     * @return validationData The result of the signature validation.
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        requireFromEntryPoint
        returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);
        //_validateNonce(userOp.nonce);
        _payPrefund(missingAccountFunds);
    }

    /*/////////////////////////////////////////////////////////////////////////////////////////////////////////
                                         INTERNAL AND PRIVATE FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////////////////////////////////*/
    /**
     * @dev Validates the signature of the User Operation.
     * @param userOp The packed user operation.
     * @param userOpHash The hash of the user operation.
     * @return validationData The result of the signature validation.
     */
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    )
        internal
        view
        returns (uint256 validationData)
    {
        bytes32 ethSingedMessageHash = MessageHashUtils.toEthSignedMessageHash(userOpHash);
        address signer = ECDSA.recover(ethSingedMessageHash, userOp.signature);
        if (signer != owner()) {
            return SIG_VALIDATION_FAILED;
        } else {
            return SIG_VALIDATION_SUCCESS;
        }
    }

    /**
     * @dev Prefunds the transaction with the missing account funds.
     * @param missingAccountFunds The amount of funds required to pre-fund the operation.
     */
    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{ value: missingAccountFunds, gas: type(uint256).max }("");
            (success);
        }
    }

    /*/////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                 GETTER FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////////////////////////////////*/
    /**
     * @notice Returns the address of the EntryPoint contract.
     * @return The address of the EntryPoint contract.
     */
    function getEntryPoint() public view returns (address) {
        return address(i_entryPoint);
    }
}
