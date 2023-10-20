// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IPoolManager, BalanceDelta} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {PoolKey, PoolId} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import "hardhat/console.sol";

library LeverageLib {
    using CurrencyLibrary for Currency;
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.leverage.storage");

    struct LeverageState {
        IPoolManager poolManager;
    }

    function diamondStorage() internal pure returns (LeverageState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setPoolManager(address managerAddy) internal {
        LeverageState storage leverageState = diamondStorage();
        leverageState.poolManager = IPoolManager(managerAddy);
    }

    function startSwap(
        PoolKey calldata poolKey,
        IPoolManager.SwapParams calldata swapParams
    ) internal returns (int256, int256) {}

    function completeSwap(
        PoolKey calldata poolKey,
        IPoolManager.SwapParams calldata swapParams
    ) internal returns (int256, int256) {}

    function startLiquidtyAdd(
        PoolKey calldata poolKey,
        IPoolManager.SwapParams calldata swapParams
    ) internal returns (int256, int256) {}

    function completeLiquidtyAdd(
        PoolKey calldata poolKey,
        IPoolManager.SwapParams calldata swapParams
    ) internal returns (int256, int256) {}
}

contract UniswapFacet {}
