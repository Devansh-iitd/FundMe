//SPDX-License-Identifier: MIT

//1. Deploy mocks when we are on a local anvil chain
//2. Keep track of contract addresses of different chains
//3. For example Sepolia ETH/USD Address is 0x694AA1769357215DE4FAC081bf1f309aDC325306
//4. Mainnet ETH/USD Address is 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    // If we are on a local anvil, we deploy mocks, else grab address of live chains

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig {
        address priceFeed;
    }

    NetworkConfig public activeConfig;

    constructor() {
        // console.log(block.chainid);
        if (block.chainid == 11155111) {
            //11155111 is the chain id of the sepolia chain
            activeConfig = getSepoliaEthConfig();
        } else {
            activeConfig = getAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public returns (NetworkConfig memory) {
        return NetworkConfig(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    function getAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeConfig.priceFeed != address(0)) {
            return activeConfig;
        }
        //1. deploy the mocks
        //2. return the mock address

        vm.startBroadcast();
        MockV3Aggregator mockEthUsd = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();

        return NetworkConfig(address(mockEthUsd));
    }
}
