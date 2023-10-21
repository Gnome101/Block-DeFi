// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "./UniswapFacet.sol";
import "../Hooks/BaseHook.sol";

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

    function getHooksCalls() internal pure returns (Hooks.Calls memory) {}

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

    function afterSwap(bytes4 selector) internal returns (bytes4) {
        HookState storage hookState = diamondStorage();
        hookState.counter++;
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
        HookLib.notImplemented();
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
        address,
        PoolKey calldata,
        IPoolManager.SwapParams calldata,
        BalanceDelta,
        bytes calldata
    ) external returns (bytes4) {
        HookLib.notImplemented();
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
