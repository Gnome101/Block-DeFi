// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LeverageFacet.sol";
import "./Hyperlane/HyperFacet.sol";
import "./ManagerFacet.sol";
import "./UniswapFacet.sol";
import "./SparkFacet.sol";
import "./Diamond/Test1Facet.sol";
import "./HookFacet.sol";

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

    function ifCloseContinue(uint256 amount) internal returns (uint256) {
        if (amount - 1000000000000000000 <= 10000000000000000) {
            //Amount is within 0.01;
            return 1;
        } else {
            ManagerLib.stopExecution();
            return 0;
        }
    }

    function continueIfOutOfBounds(
        uint256 token0,
        uint256 token1,
        uint160 lowerBound,
        uint160 upperBound
    ) internal returns (uint256, uint256, uint256, uint256, uint256) {
        HookLib.HookState storage hookState = HookLib.diamondStorage();
        uint160 currentPrice = uint160(hookState.currentPrice);
        if (currentPrice < lowerBound) {
            return (token0, token1, lowerBound, 0, currentPrice);
        } else if (currentPrice > upperBound) {
            return (token0, token1, lowerBound, 1, currentPrice);
        }
        ManagerLib.stopExecution();
        return (0, 0, 0, 0, 0);
    }

    function adjustBounds(
        uint256 token0,
        uint256 token1,
        uint160 oldLower,
        uint160 oldUpper,
        uint160 currentPrice
    ) internal {
        UniswapLib.UniswapState storage uniswapState = UniswapLib
            .diamondStorage();
        int24 oldLowerTick = TickMath.getTickAtSqrtRatio(oldLower);
        int24 oldUpperTick = TickMath.getTickAtSqrtRatio(oldUpper);
        int24 currentTick = TickMath.getTickAtSqrtRatio(currentPrice);

        int24 newLower;
        int24 newUpper;

        newLower = currentTick - 60 * 30;
        newUpper = currentTick + 60 * 30;

        address t0 = ManagerLib.convertNumToAddy(token0);
        address t1 = ManagerLib.convertNumToAddy(token1);

        UniswapLib.modifyPosition(
            t0,
            t1,
            oldLowerTick,
            oldUpperTick,
            newLower,
            newUpper
        );
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
