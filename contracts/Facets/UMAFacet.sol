// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "UMA/packages/core/contracts/optimistic-oracle-v3/interfaces/OptimisticOracleV3Interface.sol";
import "UMA/packages/core/contracts/optimistic-oracle-v3/implementation/ClaimData.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library UMALib {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.umaUMAumaUma.storage");
    struct DataAssertion {
        bytes32 dataId; // The dataId that was asserted.
        bytes32 data; // This could be an arbitrary data type.
        address asserter; // The address that made the assertion.
        bool resolved; // Whether the assertion has been resolved.
    }
    uint64 public constant assertionLiveness = 60;

    struct UMAState {
        OptimisticOracleV3Interface oov3;
        mapping(bytes32 => DataAssertion) assertionsData;
        bytes32[] assertionIDs;
        mapping(bytes32 => bytes32) messageToAssertionID;
        bytes32 defaultIdentifier;
        address currency;
    }

    function diamondStorage() internal pure returns (UMAState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setOOV3(address optimisticAddress) internal {
        UMAState storage umaState = diamondStorage();
        umaState.oov3 = OptimisticOracleV3Interface(optimisticAddress);
        umaState.defaultIdentifier = umaState.oov3.defaultIdentifier();
    }

    function setCurrency(address token) internal {
        UMAState storage umaState = diamondStorage();
        umaState.currency = token;
    }

    function getData(
        bytes32 assertionId
    ) internal view returns (bool, bytes32) {
        UMAState storage umaState = diamondStorage();

        if (!umaState.assertionsData[assertionId].resolved) return (false, 0);
        return (true, umaState.assertionsData[assertionId].data);
    }

    function getAssertionID(uint256 index) internal view returns (bytes32) {
        UMAState storage umaState = diamondStorage();
        return umaState.assertionIDs[index];
    }

    function assertDataFor(
        bytes32 dataId,
        bytes32 hyperlaneMessage,
        address asserter
    ) internal returns (bytes32 assertionId) {
        UMAState storage umaState = diamondStorage();
        asserter = asserter == address(0) ? msg.sender : asserter;

        uint256 bond = umaState.oov3.getMinimumBond(address(umaState.currency));

        SafeERC20.safeTransferFrom(
            IERC20(umaState.currency),
            msg.sender,
            address(this),
            bond
        );
        SafeERC20.safeApprove(
            IERC20(umaState.currency),
            address(umaState.oov3),
            bond
        );

        // The claim we want to assert is the first argument of assertTruth. It must contain all of the relevant
        // details so that anyone may verify the claim without having to read any further information on chain. As a
        // result, the claim must include both the data id and data, as well as a set of instructions that allow anyone
        // to verify the information in publicly available sources.
        // See the UMIP corresponding to the defaultIdentifier used in the OptimisticOracleV3 "ASSERT_TRUTH" for more
        // information on how to construct the claim.
        assertionId = umaState.oov3.assertTruth(
            abi.encodePacked(
                "Data asserted: 0x", // in the example data is type bytes32 so we add the hex prefix 0x.
                ClaimData.toUtf8Bytes(hyperlaneMessage),
                " for dataId: 0x",
                ClaimData.toUtf8Bytes(dataId),
                " and asserter: 0x",
                ClaimData.toUtf8BytesAddress(asserter),
                " at timestamp: ",
                ClaimData.toUtf8BytesUint(block.timestamp),
                " in the DataAsserter contract at 0x",
                ClaimData.toUtf8BytesAddress(address(this)),
                " is valid."
            ),
            asserter,
            address(this),
            address(0), // No sovereign security.
            assertionLiveness,
            IERC20(umaState.currency),
            bond,
            umaState.defaultIdentifier,
            bytes32(0) // No domain.
        );
        umaState.assertionsData[assertionId] = DataAssertion(
            dataId,
            hyperlaneMessage,
            asserter,
            false
        );
        umaState.assertionIDs.push(assertionId);
    }

    function settleAndGetAssertionResult(
        bytes32 assertionID
    ) internal returns (bool) {
        UMAState storage umaState = diamondStorage();
        if (!umaState.assertionsData[assertionID].resolved) {
            bool result = umaState.oov3.settleAndGetAssertionResult(
                assertionID
            );
            umaState.assertionsData[assertionID].resolved = result;
            return result;
        }
        return true;
    }

    // OptimisticOracleV3 resolve callback.
    function assertionResolvedCallback(
        bytes32 assertionId,
        bool assertedTruthfully
    ) internal {
        UMAState storage umaState = diamondStorage();

        require(msg.sender == address(umaState.oov3));
        // If the assertion was true, then the data assertion is resolved.
        if (assertedTruthfully) {
            umaState.assertionsData[assertionId].resolved = true;
            DataAssertion memory dataAssertion = umaState.assertionsData[
                assertionId
            ];

            // Else delete the data assertion if it was false to save gas.
        } else delete umaState.assertionsData[assertionId];
    }

    // If assertion is disputed, do nothing and wait for resolution.
    // This OptimisticOracleV3 callback function needs to be defined so the OOv3 doesn't revert when it tries to call it.
}

contract UMAFacet {
    function setOOV3(address optimisticAddress) external {
        UMALib.setOOV3(optimisticAddress);
    }

    function setCurrency(address token) external {
        UMALib.setCurrency(token);
    }

    function getData(
        bytes32 assertionId
    ) external view returns (bool, bytes32) {
        return UMALib.getData(assertionId);
    }

    function assertDataFor(
        bytes32 dataId,
        bytes32 data,
        address asserter
    ) external returns (bytes32 assertionId) {
        return UMALib.assertDataFor(dataId, data, asserter);
    }

    function getAssertionID(uint256 index) external view returns (bytes32) {
        return UMALib.getAssertionID(index);
    }

    // OptimisticOracleV3 resolve callback.
    function assertionResolvedCallback(
        bytes32 assertionId,
        bool assertedTruthfully
    ) external {
        return
            UMALib.assertionResolvedCallback(assertionId, assertedTruthfully);
    }

    function settleAndGetAssertionResult(
        bytes32 assertionID
    ) external returns (bool) {
        return UMALib.settleAndGetAssertionResult(assertionID);
    }

    // If assertion is disputed, do nothing and wait for resolution.
    // This OptimisticOracleV3 callback function needs to be defined so the OOv3 doesn't revert when it tries to call it.
    function assertionDisputedCallback(bytes32 assertionId) external {}
}
