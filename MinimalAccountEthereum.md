# Account Abstraction Lesson 3: Ethereum Setup

Welcome to the third lesson of our Account Abstraction course! In this lesson, we’ll be:

* Creating a new Foundry project.
* Setting up our environment to work with Ethereum.
* Reviewing the EIP for ERC-4337.
* Going over the key code needed for our contract.

To start, make sure you have Foundry installed and updated. You can do this by running the following command in your terminal.

```bash 
foundryup;
forge init
```

## Creating the MinimalAccount contract in Ethereum.
* The first question is: what do we need to do?

The first thing we need to do is look up **EIP 4337** to see how these smart contracts should look.
> 📝 TIPS <br> To view a smart contract in an editor from Etherscan, we add deph.net to the link like this: etherscan.deph.net/address/.....

In the `src` folder, create two new folders

* **ethereum**
* **zksync**

1. Create minimal Account Abstraction on Ethereum
2. Create minimal Account Abstraction on zkSync
3. Deploy and send a userOp/transaction through them
    1. Not going to send an AA to Ethereum
    2. But we will send an AA tx to zksync

```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract MinimalAccount {

}
```
Next, we need to know what to put in our contract. Well, we know that we are working with **ERC-4337**.

**Quick Recall!**

<summary>Think back to lesson 1. Think about the Ethereum entry point.</summary> 
<summary>How would we complete this sentence?</summary> 
<summary>We know we're supposed to be sending transactions to the Alt Mempool.</summary>
<summary>Then it will be sent to the EntryPoint.sol. From there it will go to Our smart wallet contract.</summary>

From this information, we know that we will need some specific functions to make this happen. [Let's head over to the EIP](https://eips.ethereum.org/EIPS/eip-4337) and see what we need.

Here we will find the `UserOperation` containing all of the data that needs to go to the alt-mempools. When passed to on-chain contracts, a packed version of this called **EntryPoint definition** is used. You can have a [look at the contract on Etherscan here](https://etherscan.io/address/0x0000000071727de22e5e9d8baf0edac6f37da032).

Furthermore, we can [view the contract code directly in our browser here.](https://etherscan.deth.net/address/0x0000000071727de22e5e9d8baf0edac6f37da032) Go ahead and get there now. Once inside, it will look very similar to your code editor.

You will see that it takes a `PackedUserOperation` and an `address payable`. When we send our information to the alt-mempool nodes, we need to send it so that the nodes can then send the `PackedUserOperation`, which is essentially a struct and is a stand alone contract - `PackedUserOperation.sol`.
```solidity 
struct PackedUserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    bytes32 accountGasLimits;
    uint256 preVerificationGas;
    bytes32 gasFees;
    bytes paymasterAndData;
    bytes signature;
}
```
## Account Contract Interface
The function takes a **userOp**, **userOpHas**, and **missingAccountFunds** to determine whether or not the user operation is valid. If not valid, it will revert and the alt-mempool nodes won't be able to send the transaction.
```solidity
        function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData);
```

We are going to import this interface from [eth-infinitism/account-abstraction](https://github.com/eth-infinitism/account-abstraction/tree/develop).

> ❗ **IMPORTANT**Be sure to check the version. We are using v0.7 for this lesson.

Head back to your terminal and run the following to install it.
```bash 
$ forge install eth-infinitism/account-abstraction@v0.7.0 --no-commit
```
Since eth-infinitism already has **IAccount Interface** we can simply import it into our contract.

```js
import { IAccount } from "lib/account-abstraction/contracts/interfaces/IAccount.sol";
```

Next, we need to inherit it. Simply add `is IAccount` to our contract.

```solidity
contract MinimalAccount is IAccount {
    // entrypoint will eventually call this contract

}
```

Next, click on `IAccount` to go to the contract. Scroll down until you see the `validateUserOp` function. Let's add the function to our code.

```js
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    ) external returns (uint256 validationData) {}
```

Now we need to import the `PackedUserOperation`.

```js
import { PackedUserOperation } from "lib/account-abstraction/contracts/interfaces/PackedUserOperation.sol";
```

You can now click on the `PackedUserOperation` contract and see the struct.

We have now set up the foundation for our contract. If you want, you could take a moment to read the comments on both of the two contracts that we have just imported. This will give you an understanding of what they do.

## Let's Review

<summary>1. What does 'tx' mean? tx means transaction</summary> 
<summary>2. What does 'EIP' stand for? Ethereum Improvement Proposal</summary> 
<summary>3. What is the purpose of the `validateUserOp` function? validate user´s signatures and nonce, the entryPoint contract will make the call to the recipient as long as the validation is valid</summary>
<summary>4. The `UserOperation` contains all the data needed to be sent to the alt Mempool node.</summary>
<summary>5. The core interface required for an account to have is IAccount interface from infinitism/account-abstraction.</summary>
