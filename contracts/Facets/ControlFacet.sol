// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LeverageFacet.sol";
import "./Hyperlane/HyperFacet.sol";
import "./ManagerFacet.sol";
import "./UniswapFacet.sol";
import "./SparkFacet.sol";
import "./Diamond/Test1Facet.sol";

library ControlLib {
    function ifTrueContinue(uint256 posNeg) internal returns (uint256) {
        if (posNeg == 0) {
            ManagerLib.stopExecution();
            return 0;
        } else {
            return 1;
        }
    }

    function ifTrueContinueWResult(
        uint256 posNeg,
        uint256 result
    ) internal returns (uint256) {
        if (posNeg == 0) {
            ManagerLib.stopExecution();
            return 0;
        } else {
            return result;
        }
    }
}

contract ControlFacet {
    function ifTrueContinue(uint256[] memory nums) external returns (uint256) {
        return ControlLib.ifTrueContinue(nums[0]);
    }

    function ifTrueContinueWResult(
        uint256[] memory nums
    ) external returns (uint256) {
        return ControlLib.ifTrueContinueWResult(nums[0], nums[1]);
    }
}
