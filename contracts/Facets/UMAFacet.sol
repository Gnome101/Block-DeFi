// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "UMA/packages/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol";

library UMALib {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.umaUMAumaUma.storage");
    struct DataAssertion {
        bytes32 dataId; // The dataId that was asserted.
        bytes32 data; // This could be an arbitrary data type.
        address asserter; // The address that made the assertion.
        bool resolved; // Whether the assertion has been resolved.
    }
    struct UMAState {
        OptimisticOracleV3Interface oov3;
        mapping(bytes32 => DataAssertion) public assertionsData;
    }

    function diamondStorage() internal pure returns (UMAState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setOOV3(address optimisticAddress) internal {
        UMAState memory umaState = diamondStorage();
        umaState.oov3 = optimisticAddress;
    }
    function getData(bytes32 assertionId) public view returns (bool, bytes32) {
        if (!assertionsData[assertionId].resolved) return (false, 0);
        return (true, assertionsData[assertionId].data);
    }
}

contract UMAFacet {
    function setOOV3(address optimisticAddress) external {
        UMALib.setOOV3(optimisticAddress);
    }
}
