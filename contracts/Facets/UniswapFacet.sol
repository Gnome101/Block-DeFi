// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IPoolManager, BalanceDelta} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {PoolKey, PoolId} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";
import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";

library UniswapLib {
    using CurrencyLibrary for Currency;
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.leverage.storage");

    struct UniswapState {
        IPoolManager poolManager;
        mapping(uint256 => IPoolManager.SwapParams) swaps;
        mapping(uint256 => IPoolManager.ModifyPositionParams) modLiqs;
        uint256 swapCounter;
        uint256 liqCounter;
    }

    function diamondStorage() internal pure returns (UniswapState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setPoolManager(address managerAddy) internal {
        UniswapState storage uniswapState = diamondStorage();
        uniswapState.poolManager = IPoolManager(managerAddy);
    }

    function startSwap(
        PoolKey calldata poolKey,
        IPoolManager.SwapParams calldata swapParams
    ) internal returns (int256, int256) {
        UniswapState storage uniswapState = diamondStorage();
        uniswapState.swaps[uniswapState.swapCounter] = swapParams;

        bytes memory res = uniswapState.poolManager.lock(
            abi.encode(msg.sender, poolKey, 1, uniswapState.swapCounter)
        );

        return abi.decode(res, (int256, int256));
    }

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

    function processCallBack(
        bytes calldata data
    ) internal returns (int128, int128) {
        UniswapState storage uniswapState = diamondStorage();

        //The Pool Manager will call this after
        (
            address user,
            PoolKey memory poolKey,
            uint256 action,
            uint256 counter
        ) = abi.decode(data, (address, PoolKey, uint256, uint256));
        //Need to decode the data that was just sent from the Pool Manager after we called swap or liquidtyAdd

        BalanceDelta delta;

        delta = uniswapState.poolManager.swap(
            poolKey,
            uniswapState.swaps[counter],
            "0x"
        );

        uniswapState.swapCounter++;

        _settleCurrencyBalance(poolKey.currency0, delta.amount0());
        _settleCurrencyBalance(poolKey.currency1, delta.amount1());
        return (delta.amount0(), delta.amount1());
    }

    function _settleCurrencyBalance(
        Currency currency,
        int128 deltaAmount
    ) internal {
        UniswapState storage uniswapState = diamondStorage();
        if (deltaAmount < 0) {
            uniswapState.poolManager.take(
                currency,
                address(this),
                uint128(-deltaAmount)
            );
            return;
        }

        if (currency.isNative()) {
            uniswapState.poolManager.settle{value: uint128(deltaAmount)}(
                currency
            );
            return;
        }

        SafeERC20.safeTransfer(
            IERC20(Currency.unwrap(currency)),
            address(uniswapState.poolManager),
            uint128(deltaAmount)
        );
        uniswapState.poolManager.settle(currency);
    }
}

contract UniswapFacet {
    function lockAcquired(
        bytes calldata data
    ) external returns (int128, int128) {
        return UniswapLib.processCallBack(data);
    }
}
