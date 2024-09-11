//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script, console2 } from "forge-std/Script.sol";
import { EntryPoint } from "lib/account-abstraction/contracts/core/EntryPoint.sol";

/**
 * @title HelperConfig
 * @dev Provides network-specific configurations for deployment scripts.
 * Supports configurations for Sepolia, zkSync, and local Anvil network.
 */
contract HelperConfig is Script {
    error HelperConfig__InvalidConfig();

    struct NetworkConfig {
        address entryPoint;
        address account;
    }

    uint256 constant ETH_SEPOLIA_CHAIN_ID = 11_155_111;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
    uint256 constant LOCAL_CHAIN_ID = 31_337;
    address constant BURNER_WALLET = 0x8a01151030f0a115B1B9dcfbF23583B44cA3d25E;
    address constant FOUNDRY_DEFAULT_WALLET = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    address constant ANVIL_DEFAULT_KEY = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getEthSepoliaConfig();
        networkConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getZkSyncSepoliaConfig();
    }

    /**
     * @notice Returns the network configuration based on the current network's chain ID.
     * @dev Determines the network's configuration using the chain ID of the current network.
     * @return NetworkConfig The network-specific configuration for the current network.
     */
    function getConfig() public returns (NetworkConfig memory) {
        return getConfigByChainId(block.chainid);
    }

    /**
     * @notice Returns the network configuration for a specific chain ID.
     * @dev Checks if the configuration exists for the given chain ID. Reverts if it does not.
     * @param chainId The chain ID of the target network.
     * @return NetworkConfig The network-specific configuration for the specified chain ID.
     */
    function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
            /**
             * Si ya existe una configuración para esta red (es decir, si la cuenta no es una dirección vacía),
             * devuelve esa configuración guardada. Es una forma de verificar si la configuración ya ha sido
             * registrada previamente y, de ser así, devolverla para evitar tener que crearla de nuevo.
             */
        } else if (networkConfigs[chainId].account != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidConfig();
        }
    }

    /**
     * @notice Provides the configuration for the Ethereum Sepolia network.
     * @dev This is a hardcoded configuration for Ethereum's Sepolia testnet.
     * @return NetworkConfig The configuration containing the EntryPoint address and the Burner wallet.
     */
    function getEthSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({ entryPoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789, account: BURNER_WALLET });
    }

    /**
     * @notice Provides the configuration for the zkSync Sepolia network.
     * @dev This is a hardcoded configuration for zkSync's Sepolia network.
     * @return NetworkConfig The configuration containing the EntryPoint address and the Burner wallet.
     */
    function getZkSyncSepoliaConfig() public pure returns (NetworkConfig memory) {
        return NetworkConfig({ entryPoint: address(0), account: BURNER_WALLET });
    }

    /**
     * @notice Provides or creates a configuration for the local Anvil network.
     * @dev Deploys a new EntryPoint mock contract if none exists for the local network.
     * Logs the deployment and broadcasts the transaction from the default Anvil account.
     * @return NetworkConfig The configuration for the local network.
     */
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (localNetworkConfig.account != address(0)) {
            return localNetworkConfig;
        }

        //deploy entryPoint mock
        console2.log("Deploying EntryPoint...");
        vm.startBroadcast(ANVIL_DEFAULT_KEY);
        EntryPoint entryPoint = new EntryPoint();
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({ entryPoint: address(entryPoint), account: ANVIL_DEFAULT_KEY });

        return localNetworkConfig;
    }
}
