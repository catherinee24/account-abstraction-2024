//SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IAccount } from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract MinimalAccount is IAccount, Ownable {
    constructor() Ownable(msg.sender) { }

    //A signature is valid, if it is the MinimalAccount contract owner
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        returns (uint256 validationData)
    {
        _validateSignature(userOp, userOpHash);
    }

    // this userOpHash its going to be the EIP 191 version of the signed hash.
    function _validateSignature(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    )
        internal
        view
        returns (uint256 validationData)
    { }
}
