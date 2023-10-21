// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import "../Hooks/BaseHook.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";

import "./ManagerFacet.sol";
import "./UniswapFacet.sol";

library HookLib {
    error NotPoolManager();
    error NotSelf();
    error InvalidPool();
    error LockFailure();
    error HookNotImplemented();

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.hook.storage");

    struct HookState {
        IPoolManager poolManager;
        uint256 counter;
        uint256 currentPrice;
    }

    function diamondStorage() internal pure returns (HookState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    modifier poolManagerOnly() {
        HookState storage hookState = diamondStorage();
        if (msg.sender != address(hookState.poolManager))
            revert NotPoolManager();
        _;
    }

    function getHooksCalls() internal pure returns (Hooks.Calls memory) {
        return
            Hooks.Calls({
                beforeInitialize: false,
                afterInitialize: false,
                beforeModifyPosition: true,
                afterModifyPosition: false,
                beforeSwap: false,
                afterSwap: true,
                beforeDonate: false,
                afterDonate: false
            });
    }

    function validateHookAddress(BaseHook _this) internal pure {
        Hooks.validateHookAddress(_this, getHooksCalls());
    }

    function lockAcquired(
        bytes calldata data
    ) internal poolManagerOnly returns (bytes memory) {
        (bool success, bytes memory returnData) = address(this).call(data);
        if (success) return returnData;
        if (returnData.length == 0) revert LockFailure();
        // if the call failed, bubble up the reason
        /// @solidity memory-safe-assembly
        assembly {
            revert(add(returnData, 32), mload(returnData))
        }
    }

    function beforeModifyPosition(bytes4 selector) internal returns (bytes4) {
        HookState storage hookState = diamondStorage();
        hookState.counter++;
        return selector;
    }

    function afterSwap(
        PoolKey memory poolKey,
        bytes4 selector
    ) internal returns (bytes4) {
        HookState storage hookState = diamondStorage();
        ManagerLib.ManagerState storage managerState = ManagerLib
            .diamondStorage();
        UniswapLib.UniswapState storage uniswapState = UniswapLib
            .diamondStorage();

        hookState.counter++;
        console.log(managerState.executionOccuring);
        PoolId poolID = PoolIdLibrary.toId(poolKey);
        (, int24 currentTick, , ) = uniswapState.poolManager.getSlot0(poolID);
        hookState.currentPrice = TickMath.getSqrtRatioAtTick(currentTick);
        if (!managerState.executionOccuring) {
            console.log("length", managerState.afterSwapFlows.length);
            for (uint i = 0; i < managerState.afterSwapFlows.length; i++) {
                ManagerLib.startWorking(managerState.afterSwapFlows[i]);
            }
        }

        return selector;
    }

    function getCounter() internal view returns (uint256) {
        HookState storage hookState = diamondStorage();
        return hookState.counter;
    }

    function notImplemented() internal pure returns (bytes4) {
        revert HookNotImplemented();
    }
}

contract HookFacet is IHooks {
    function getHooksCalls() external pure returns (Hooks.Calls memory) {
        return HookLib.getHooksCalls();
    }

    function beforeInitialize(
        address,
        PoolKey calldata,
        uint160,
        bytes calldata
    ) external returns (bytes4) {
        HookLib.notImplemented();
    }

    function afterInitialize(
        address,
        PoolKey calldata,
        uint160,
        int24,
        bytes calldata
    ) external returns (bytes4) {
        HookLib.notImplemented();
    }

    function beforeModifyPosition(
        address,
        PoolKey calldata,
        IPoolManager.ModifyPositionParams calldata,
        bytes calldata
    ) external returns (bytes4) {
        return HookLib.beforeModifyPosition(this.beforeModifyPosition.selector);
    }

    function afterModifyPosition(
        address,
        PoolKey calldata,
        IPoolManager.ModifyPositionParams calldata,
        BalanceDelta,
        bytes calldata
    ) external returns (bytes4) {
        HookLib.notImplemented();
    }

    function beforeSwap(
        address,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        bytes calldata
    ) external returns (bytes4) {
        HookLib.notImplemented();
    }

    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata hookData
    ) external returns (bytes4) {
        return HookLib.afterSwap(key, this.afterSwap.selector);
    }

    function getFee(
        address,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        bytes calldata
    ) external view returns (uint24) {
        return 3000;
    }

    function beforeDonate(
        address,
        PoolKey calldata,
        uint256,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        HookLib.notImplemented();
    }

    function afterDonate(
        address,
        PoolKey calldata,
        uint256,
        uint256,
        bytes calldata
    ) external returns (bytes4) {
        HookLib.notImplemented();
    }

    function getLeAwesomeCounter() external view returns (uint256) {
        return HookLib.getCounter();
    }
}
