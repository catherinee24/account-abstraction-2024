//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { HelperConfig } from "./HelperConfig.s.sol";
import { MinimalAccount } from "../src/ethereum/MinimalAccount.sol";

/**
 * @title DeployMinimalAccount
 * @dev Script to deploy the MinimalAccount contract with network-specific configurations.
 */
contract DeployMinimalAccount is Script {
    /**
     * @notice Deploys the MinimalAccount contract and returns the configuration and the deployed contract.
     * @dev This function is executed when running the script. Calls deployMinimalAccont.
     * @return HelperConfig The configuration used for deployment.
     * @return MinimalAccount The deployed MinimalAccount contract instance.
     */
    function run() external returns (HelperConfig, MinimalAccount) {
        return deployMinimalAccont();
    }

    /**
     * @notice Deploys a new MinimalAccount contract and transfers ownership to a predefined account.
     * @dev Uses the HelperConfig contract to get network-specific configurations.
     * Starts a broadcast to the blockchain, deploys the contract, and transfers ownership.
     * @return HelperConfig The configuration used for deployment.
     * @return MinimalAccount The deployed MinimalAccount contract instance.
     */
    function deployMinimalAccont() public returns (HelperConfig, MinimalAccount) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfig();

        vm.startBroadcast(config.account);
        MinimalAccount minimalAccount = new MinimalAccount(config.entryPoint);
        minimalAccount.transferOwnership(config.account);
        vm.stopBroadcast();
        return (helperConfig, minimalAccount);
    }
}
