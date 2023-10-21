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
        uint256 lowerBound,
        uint256 upperBound
    ) internal returns (uint256, uint256) {
        UniswapLib.UniswapState storage uniswapState = UniswapLib
            .diamondStorage();
        uint256 token0 = ManagerLib.convertAddyToNum(
            uniswapState.userPositions[address(this)][0].token0
        );
        uint256 token1 = ManagerLib.convertAddyToNum(
            uniswapState.userPositions[address(this)][0].token1
        );

        HookLib.HookState storage hookState = HookLib.diamondStorage();

        if (hookState.currentPrice < lowerBound) {
            console.log("Current price is below lower bound!");
            return (token0, token1);
        } else if (hookState.currentPrice > upperBound) {
            console.log("Current price is above upper bound!");
            return (token0, token1);
        }
        console.log("Current Price is still within bounds");
        ManagerLib.stopExecution();
        return (0, 0);
    }

    function adjustBounds(uint256 token0, uint256 token1) internal {
        // int24 oldLowerTick = TickMath.getTickAtSqrtRatio(oldLower);
        // int24 oldUpperTick = TickMath.getTickAtSqrtRatio(oldUpper);
        (int24 oldLowerTick, int24 oldUpperTick) = UniswapLib
            .returnBoundsTicks();
        HookLib.HookState storage hookState = HookLib.diamondStorage();
        console.log("adjusting?");
        int24 currentTick = TickMath.getTickAtSqrtRatio(
            uint160(hookState.currentPrice)
        );
        console.log("Current", uint256(uint24(-oldLowerTick)));
        int24 newLower;
        int24 newUpper;
        newLower = currentTick - 60 * 5;
        newUpper = currentTick + 60 * 5;

        address t0 = ManagerLib.convertNumToAddy(token0);
        address t1 = ManagerLib.convertNumToAddy(token1);
        console.log("Modifying");
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

    function continueIfOutOfBounds(
        uint256[] memory nums
    ) external returns (uint256, uint256) {
        return ControlLib.continueIfOutOfBounds((nums[0]), (nums[1]));
    }

    function adjustBounds(uint256[] memory nums) external {
        ControlLib.adjustBounds(nums[0], nums[1]);
    }
}
