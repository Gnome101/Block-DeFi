// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../WormHole/WormholeRelayerSDK.sol";

library UMALib {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.WORMHOLE.storage");

    struct UMAState {
        uint256 counter;
    }

    function diamondStorage() internal pure returns (UMAState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // This OptimisticOracleV3 callback function needs to be defined so the OOv3 doesn't revert when it tries to call it.
}

contract UMAFacet {}
