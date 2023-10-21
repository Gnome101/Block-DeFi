// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Example library to show a simple example of diamond storage

library TestLib {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.test.storage");

    struct TestState {
        uint256 number;
    }

    function diamondStorage() internal pure returns (TestState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setNumber(
        uint256[] memory n
    ) internal returns (uint256 i, uint256 j) {
        TestState storage testState = diamondStorage();
        testState.number = n[0];
        return (n[0] + 3, n[0] * 2);
    }

    function getNumber() internal view returns (uint256) {
        TestState storage testState = diamondStorage();
        return testState.number;
    }

    function getSum(uint256[] memory nums) internal pure returns (uint256) {
        return nums[0] + nums[1];
    }
}

contract Test1Facet {
    event TestEvent(address something);

    function setNumber(
        uint256[] memory n
    ) public returns (uint256 i, uint256 j) {
        return TestLib.setNumber(n);
    }

    function getNumber() public view returns (uint256) {
        return TestLib.getNumber();
    }

    function getSum(uint256[] memory nums) public pure returns (uint256) {
        return TestLib.getSum(nums);
    }
}
