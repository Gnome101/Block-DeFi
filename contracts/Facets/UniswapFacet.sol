// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {IPoolManager, BalanceDelta} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {PoolKey, PoolId} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";
import "@uniswap/v3-periphery/contracts/interfaces/external/IWETH9.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import "@uniswap/v4-core/contracts/types/PoolId.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import "./SparkFacet.sol";
import "./LeverageFacet.sol";
struct userPosition {
    int24 lowerBound;
    int24 upperBound;
    PoolId poolID;
}
enum ActionType {
    Swap,
    LiquidityChange,
    CompLeverage,
    SparkLeverage
}

library UniswapLib {
    using CurrencyLibrary for Currency;
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.uniswap.storage");

    struct UniswapState {
        IPoolManager poolManager;
        mapping(uint256 => IPoolManager.SwapParams) swaps;
        mapping(uint256 => IPoolManager.ModifyPositionParams) modLiqs;
        mapping(uint256 => FlashLeverage) leveragePos;
        uint256 swapCounter;
        uint256 liqCounter;
        mapping(address => userPosition[]) userPositions;
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

    function determineZeroForOne(
        address tokenFrom,
        address tokenTo
    ) internal pure returns (bool, address, address) {
        if (tokenFrom < tokenTo) {
            //TokenFrom is token 0
            //TokenTo is token 1
            //Therefore  zeroForOne is true
            return (true, tokenFrom, tokenTo);
        } else {
            return (false, tokenTo, tokenFrom);
        }
    }

    function swap(
        address tokenFrom,
        address tokenTo,
        int256 amount
    ) internal returns (int256, int256, bool) {
        UniswapState storage uniswapState = diamondStorage();
        (bool zeroForOne, address token0, address token1) = determineZeroForOne(
            tokenFrom,
            tokenTo
        );
        PoolKey memory poolKey = uniswapState.tokensToPool[token0][token1];
        IPoolManager.SwapParams memory swapParams = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: amount,
            sqrtPriceLimitX96: zeroForOne
                ? TickMath.MIN_SQRT_RATIO + 1
                : TickMath.MAX_SQRT_RATIO - 1
        });
        //Want to avoid sqrtPriceLimit

        uniswapState.swaps[uniswapState.swapCounter] = swapParams;
        bytes memory result = uniswapState.poolManager.lock(
            abi.encode(
                msg.sender,
                poolKey,
                ActionType.Swap,
                uniswapState.swapCounter
            )
        );
        (int128 t0, int128 t1) = abi.decode(result, (int128, int128));

        return (t0, t1, zeroForOne);
    }

    struct FlashLeverage {
        address collateral;
        address providedToken;
        uint256 userAmount;
        uint256 swapAmount;
    }

    function flashSwapTokens(
        address tokenFrom,
        address tokenTo,
        int256 amount,
        ActionType action,
        FlashLeverage memory leverageInfo
    ) internal returns (bytes memory) {
        UniswapState storage uniswapState = diamondStorage();
        (bool zeroForOne, address token0, address token1) = determineZeroForOne(
            tokenFrom,
            tokenTo
        );
        PoolKey memory poolKey = uniswapState.tokensToPool[token0][token1];
        IPoolManager.SwapParams memory swapParams = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: amount,
            sqrtPriceLimitX96: zeroForOne
                ? TickMath.MIN_SQRT_RATIO + 1
                : TickMath.MAX_SQRT_RATIO - 1
        });
        //Want to avoid sqrtPriceLimit

        uniswapState.swaps[uniswapState.swapCounter] = swapParams;
        uniswapState.leveragePos[uniswapState.swapCounter] = leverageInfo;
        bytes memory result = uniswapState.poolManager.lock(
            abi.encode(msg.sender, poolKey, action, uniswapState.swapCounter)
        );
        uniswapState.swapCounter++;

        return result;
    }

    function closePosition(
        address token0,
        address token1,
        int24 lowerBound,
        int24 upperBound
    ) internal returns (int128, int128) {
        UniswapState storage uniswapState = diamondStorage();
        (token0, token1) = getTokens(token0, token1);
        PoolKey memory poolKey = uniswapState.tokensToPool[token0][token1];

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

        return (t0, t1);
    }

    function modifyPosition(
        address token0,
        address token1,
        int24 lowerBound,
        int24 upperBound
    ) internal {}

    function getTokens(
        address token0Maybe,
        address token1Maybe,
        uint256 t0Amount,
        uint256 t1Amount
    ) internal pure returns (address, address, uint256, uint256) {
        if (token0Maybe < token1Maybe) {
            return (token0Maybe, token1Maybe, t0Amount, t1Amount);
        } else {
            return (token1Maybe, token0Maybe, t1Amount, t0Amount);
        }
    }

    function getTokens(
        address token0Maybe,
        address token1Maybe
    ) internal pure returns (address, address) {
        if (token0Maybe < token1Maybe) {
            return (token0Maybe, token1Maybe);
        } else {
            return (token1Maybe, token0Maybe);
        }
    }

    function addLiquidty(
        address token0, //Order does not matter
        address token1,
        int24 tickLower,
        int24 tickUpper,
        uint256 token0Amount,
        uint256 token1Amount
    ) internal returns (int256, int256) {
        UniswapState storage uniswapState = diamondStorage();

        (token0, token1, token0Amount, token1Amount) = getTokens(
            token0,
            token1,
            token0Amount,
            token1Amount
        );

        // SafeERC20.safeTransferFrom(
        //     token0,
        //     msg.sender,
        //     address(this),
        //     token0Amount
        // );
        // SafeERC20.safeTransferFrom(token0, token0Amount, address(this));

        PoolKey memory poolKey = uniswapState.tokensToPool[token0][token1];

        PoolId id = PoolIdLibrary.toId(poolKey);

        uniswapState.userPositions[msg.sender].push(
            userPosition({
                lowerBound: tickLower,
                upperBound: tickUpper,
                poolID: id
            })
        );
        //Need to get ID from pool key
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
        (int128 t0, int128 t1) = abi.decode(res, (int128, int128));
        return (t0, t1);
    }

    function initializePool(
        address token0,
        address token1,
        uint160 poolStartPrice,
        address hook,
        bytes calldata hookData
    ) internal {
        UniswapState storage uniswapState = diamondStorage();
        // address token0 = Currency.unwrap(poolkey.currency0);
        // address token1 = Currency.unwrap(poolkey.currency1);
        PoolKey memory newKey = PoolKey(
            Currency.wrap(token0),
            Currency.wrap(token1),
            3000,
            60,
            IHooks(hook)
        );
        uniswapState.tokensToPool[token0][token1] = newKey;
        uniswapState.poolManager.initialize(newKey, poolStartPrice, hookData);
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
    ) internal returns (bytes memory info) {
        //The Pool Manager will call this after I call lock on the pool
        (
            address user,
            PoolKey memory poolKey,
            ActionType action,
            uint256 counter
        ) = abi.decode(data, (address, PoolKey, ActionType, uint256));
        //Need to decode the data that was just sent from the Pool Manager after we called swap or liquidtyAdd
        int128 t0Amount;
        int128 t1Amount;

        if (action == ActionType.Swap) {
            (t0Amount, t1Amount) = completeSwap(poolKey, counter);
        } else if (action == ActionType.LiquidityChange) {
            (t0Amount, t1Amount) = completeLiquidtyAdd(poolKey, counter);
        } else if (action == ActionType.CompLeverage) {
            console.log("Whats going");
            LeverageLib.completeLeverage(poolKey, counter, user);
        } else {
            console.log("Sparks flying!");
            SparkLib.completeLeverage(poolKey, counter, user);
        }
        info = abi.encode(t0Amount, t1Amount);

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
    ) internal pure returns (uint128 liq) {
        liq = LiquidityAmounts.getLiquidityForAmounts(
            lowerPrice,
            upperPrice,
            currentPrice,
            token0Amount,
            token1Amount
        );
    }

    function getPoolLiquidity(
        address token0,
        address token1
    ) internal view returns (uint128) {
        UniswapState storage uniswapState = diamondStorage();
        (token0, token1) = getTokens(token0, token1);
        PoolKey memory poolKey = uniswapState.tokensToPool[token0][token1];
        PoolId id = PoolIdLibrary.toId(poolKey);
        uint128 liq = uniswapState.poolManager.getLiquidity(id);
        return liq;
    }

    function getSqrtAtTick(int24 tick) internal pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(tick);
    }

    function returnBounds(address token0, address token1) internal returns(int24 lower,int24 upper){
        UniswapState storage uniswapState = diamondStorage();
        
    }
}

contract UniswapFacet {
    function lockAcquired(bytes calldata data) external returns (bytes memory) {
        return UniswapLib.processCallBack(data);
    }

    function setPoolManager(address managerAddy) external {
        UniswapLib.setPoolManager(managerAddy);
    }

    function swap(
        address tokenFrom,
        address tokenTo,
        int256 amount
    )
        external
        returns (int256 token0Amount, int256 token1Amount, bool zeroForOne)
    {
        return UniswapLib.swap(tokenFrom, tokenTo, amount);
    }

    function closePosition(
        address token0,
        address token1,
        int24 lowerBound,
        int24 upperBound
    ) external returns (int256 token0Amount, int256 token1Amount) {
        return UniswapLib.closePosition(token0, token1, lowerBound, upperBound);
    }

    function addLiquidty(
        address token0, //Order does not matter, they are sorted
        address token1,
        int24 tickLower,
        int24 tickUpper,
        uint256 token0Amount,
        uint256 token1Amount
    ) external returns (int256 token0Used, int256 token1Used) {
        return
            UniswapLib.addLiquidty(
                token0,
                token1,
                tickLower,
                tickUpper,
                token0Amount,
                token1Amount
            );
    }

    function initializePool(
        address token0,
        address token1,
        uint160 poolStartPrice,
        address hook,
        bytes calldata hookData
    ) external {
        UniswapLib.initializePool(
            token0,
            token1,
            poolStartPrice,
            hook,
            hookData
        );
    }

    function getPoolLiquidity(
        address token0,
        address token1
    ) external view returns (uint128) {
        return UniswapLib.getPoolLiquidity(token0, token1);
    }

    function getSqrtAtTick(int24 tick) external pure returns (uint160) {
        return UniswapLib.getSqrtAtTick(tick);
    }
}
