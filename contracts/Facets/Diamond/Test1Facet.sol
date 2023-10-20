// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Example library to show a simple example of diamond storage

library TestLib {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.test.storage");

    struct TestState {
        address myAddress;
        uint256 myNum;
        string word;
    }

    function diamondStorage() internal pure returns (TestState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function num() internal view returns (uint256) {
        TestState storage testState = diamondStorage();
        return testState.myNum;
    }

    function setNum(uint256 n) internal {
        TestState storage testState = diamondStorage();
        testState.myNum = n * 3;
    }

    function getNum() internal view returns (uint256) {
        return 5;
    }
}

contract Test1Facet {
    event TestEvent(address something);

    function num() external view returns (uint256) {
        return TestLib.num();
    }

    function setNum(uint256 n) external {
        TestLib.setNum(n);
    }

    function getNum() external view returns (uint256) {
        return TestLib.getNum();
    }
}
