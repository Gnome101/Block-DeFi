// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IPoolManager, BalanceDelta} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {PoolKey, PoolId} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";
import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import "@uniswap/v4-core/contracts/types/PoolId.sol";

struct position {
    int24 lowerBound;
    int24 upperBound;
    PoolId poolID;
}
enum ActionType {
    Swap,
    LiquidityChange
}

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
        mapping(address => position[]) userPositions;
        mapping(address => mapping(address => PoolKey)) tokensToPool;
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

    function swap(
        PoolKey calldata poolKey,
        IPoolManager.SwapParams calldata swapParams
    ) internal returns (int256, int256) {
        UniswapState storage uniswapState = diamondStorage();
        uniswapState.swaps[uniswapState.swapCounter] = swapParams;

        bytes memory res = uniswapState.poolManager.lock(
            abi.encode(
                msg.sender,
                poolKey,
                ActionType.Swap,
                uniswapState.swapCounter
            )
        );

        return abi.decode(res, (int256, int256));
    }

    function completeSwap(
        PoolKey memory poolKey,
        uint256 counter
    ) internal returns (int128, int128) {
        BalanceDelta delta;
        UniswapState storage uniswapState = diamondStorage();
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

    function closePosition(
        PoolKey calldata poolKey,
        int24 lowerBound,
        int24 upperBound
    ) internal returns (int128, int128) {
        UniswapState storage uniswapState = diamondStorage();

        int128 liquidtyAmount = int128(
            uniswapState.poolManager.getLiquidity(
                PoolIdLibrary.toId(poolKey),
                address(this),
                lowerBound,
                upperBound
            )
        );
        uniswapState.modLiqs[uniswapState.liqCounter] = IPoolManager
            .ModifyPositionParams(lowerBound, upperBound, -liquidtyAmount);
        //Negative so that we remove that amount of liqudity
        uniswapState.liqCounter++;
        bytes memory res = uniswapState.poolManager.lock(
            abi.encode(
                msg.sender,
                poolKey,
                ActionType.LiquidityChange,
                uniswapState.liqCounter
            )
        );
        uniswapState.liqCounter++;
        (int128 t0, int128 t1) = abi.decode(res, (int128, int128));
        //console.log(t0, t1);
        return (t0, t1);
    }

    function addLiquidty(
        PoolKey calldata poolKey,
        int24 tickLower,
        int24 tickUpper,
        uint256 token0Amount,
        uint256 token1Amount
    ) internal returns (int256, int256) {
        UniswapState storage uniswapState = diamondStorage();

        //Need to get ID from pool key
        PoolId id = PoolIdLibrary.toId(poolKey);
        (uint160 startPrice, , , ) = uniswapState.poolManager.getSlot0(id);

        int256 liquidtyDelta = int256(
            int128(
                getLiquidtyAmount(
                    TickMath.getSqrtRatioAtTick(tickLower),
                    TickMath.getSqrtRatioAtTick(tickUpper),
                    startPrice,
                    token0Amount,
                    token1Amount
                )
            )
        );
        IPoolManager.ModifyPositionParams
            memory modifyLiquidtyParams = IPoolManager.ModifyPositionParams({
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: liquidtyDelta
            });
        uniswapState.modLiqs[uniswapState.liqCounter] = modifyLiquidtyParams;

        bytes memory res = uniswapState.poolManager.lock(
            abi.encode(
                msg.sender,
                poolKey,
                ActionType.LiquidityChange,
                uniswapState.liqCounter
            )
        );

        return abi.decode(res, (int256, int256));
    }

    function completeLiquidtyAdd(
        PoolKey memory poolKey,
        uint256 counter
    ) internal returns (int128, int128) {
        BalanceDelta delta;
        UniswapState storage uniswapState = diamondStorage();
        delta = uniswapState.poolManager.modifyPosition(
            poolKey,
            uniswapState.modLiqs[counter],
            "0x"
        );

        uniswapState.liqCounter++;

        _settleCurrencyBalance(poolKey.currency0, delta.amount0());
        _settleCurrencyBalance(poolKey.currency1, delta.amount1());
        return (delta.amount0(), delta.amount1());
    }

    function processCallBack(
        bytes calldata data
    ) internal returns (int128 t0Amount, int128 t1Amount) {
        //The Pool Manager will call this after I call lock on the pool
        (
            address user,
            PoolKey memory poolKey,
            ActionType action,
            uint256 counter
        ) = abi.decode(data, (address, PoolKey, ActionType, uint256));
        //Need to decode the data that was just sent from the Pool Manager after we called swap or liquidtyAdd
        if (action == ActionType.Swap) {
            (t0Amount, t1Amount) = completeSwap(poolKey, counter);
        } else {
            completeLiquidtyAdd(poolKey, counter);
        }
        SafeERC20.safeTransfer(
            IERC20(Currency.unwrap(poolKey.currency0)),
            user,
            IERC20(Currency.unwrap(poolKey.currency0)).balanceOf(
                (address(this))
            )
        );
        SafeERC20.safeTransfer(
            IERC20(Currency.unwrap(poolKey.currency1)),
            user,
            IERC20(Currency.unwrap(poolKey.currency1)).balanceOf(
                (address(this))
            )
        );
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

    function getLiquidtyAmount(
        uint160 lowerPrice,
        uint160 upperPrice,
        uint160 currentPrice,
        uint256 token0Amount,
        uint256 token1Amount
    ) internal view returns (uint128 liq) {
        liq = LiquidityAmounts.getLiquidityForAmounts(
            lowerPrice,
            upperPrice,
            currentPrice,
            token0Amount,
            token1Amount
        );
    }
}

contract UniswapFacet {
    function lockAcquired(
        bytes calldata data
    ) external returns (int128, int128) {
        return UniswapLib.processCallBack(data);
    }

    function setPoolManager(address managerAddy) external {
        UniswapLib.setPoolManager(managerAddy);
    }

    function swap(
        PoolKey calldata poolKey,
        IPoolManager.SwapParams calldata swapParams
    ) external returns (int256, int256) {
        return UniswapLib.swap(poolKey, swapParams);
    }

    function closePosition(
        PoolKey calldata poolKey,
        int24 lowerBound,
        int24 upperBound
    ) external returns (int128, int128) {
        return UniswapLib.closePosition(poolKey, lowerBound, upperBound);
    }

    function addLiquidty(
        PoolKey calldata poolKey,
        int24 tickLower,
        int24 tickUpper,
        uint256 token0Amount,
        uint256 token1Amount
    ) external returns (int256, int256) {
        return
            UniswapLib.addLiquidty(
                poolKey,
                tickLower,
                tickUpper,
                token0Amount,
                token1Amount
            );
    }
}
