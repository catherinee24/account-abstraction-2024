//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IAccount } from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS } from "lib/account-abstraction/contracts/core/Helpers.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { IEntryPoint } from "lib/account-abstraction/contracts/interfaces/IEntryPoint.sol";

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

    /*/////////////////////////////////////////////////////////////////////////////////////////////////////////
                                         EXTERNAL AND PULIC FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////////////////////////////////*/
    function execute(
        address destination,
        uint256 value,
        bytes calldata functionData
    )
        external
        requireFromEntryPointOrOwner
    {
        (bool success, bytes memory result) = destinatio.call{ value: value }(functionData);

        if (!success) {
            revert MinimalAccount__CallFailed(result);
        }
    }

    //A signature is valid, if it is the MinimalAccount contract owner
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
    // this userOpHash its going to be the EIP 191 version of the signed hash.
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

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success) = payable(msg.sender).call{ value: missingAccountFunds, gas: type(uint256).max }("");
            (success);
        }
    }

    /*/////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                 GETTER FUNCTIONS
    /////////////////////////////////////////////////////////////////////////////////////////////////////////*/
    function getEntryPoint() public view returns (address) {
        return address(i_entryPoint);
    }
}
