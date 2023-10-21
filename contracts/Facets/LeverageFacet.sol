// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "comet/contracts/CometMainInterface.sol";
import "comet/contracts/CometExtInterface.sol";

import {IPoolManager, BalanceDelta} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {PoolKey, PoolId} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import "hardhat/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./UniswapFacet.sol";

library LeverageLib {
    using CurrencyLibrary for Currency;
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.leverage.storage");

    struct LeverageState {
        CometMainInterface comet;
        CometExtInterface cometData;
    }

    function diamondStorage() internal pure returns (LeverageState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setComet(address cometAddy) internal {
        LeverageState storage leverageState = diamondStorage();
        leverageState.comet = CometMainInterface(cometAddy);
    }

    function setCometData(address cometExtAddy) internal {
        LeverageState storage leverageState = diamondStorage();
        leverageState.cometData = CometExtInterface(cometExtAddy);
    }

    function leverageUp(
        address collateral, //WETH
        address providedToken, //USDC
        uint256 userAmount,
        uint256 swapAmount
    ) internal {
        UniswapLib.UniswapState storage uniswapState = UniswapLib
            .diamondStorage();

        //Swap has been called
        bytes memory data = UniswapLib.flashSwapTokens(
            providedToken,
            collateral,
            -int256(swapAmount)
        );
        (
            address user,
            PoolKey memory poolKey,
            ActionType action,
            uint256 counter
        ) = abi.decode(data, (address, PoolKey, ActionType, uint256));

        BalanceDelta delta;

        delta = uniswapState.poolManager.swap(
            poolKey,
            uniswapState.swaps[counter],
            "0x"
        );
        supply(collateral, swapAmount + userAmount);
        if (providedToken < collateral) {
            //Provided is token0
            withdraw(providedToken, uint128(delta.amount0()));
        } else {
            //Provided is token1
            withdraw(providedToken, uint128(delta.amount1()));
        }

        UniswapLib._settleCurrencyBalance(poolKey.currency0, delta.amount0());
        UniswapLib._settleCurrencyBalance(poolKey.currency1, delta.amount1());

        //Then we need to call supply with the amount we recieved
        //Then we need to call withdraw to take the new tokens out
        //Then we use the tokens withdrawn to pay off the v4 swap
    }

    function supply(address asset, uint256 amount) internal {
        LeverageState storage leverageState = diamondStorage();
        IERC20(asset).approve(address(leverageState.comet), amount);
        leverageState.comet.supply(asset, amount);
    }

    function getCollateralBalance(
        address asset
    ) internal view returns (uint256) {
        LeverageState storage leverageState = diamondStorage();
        return
            leverageState.cometData.collateralBalanceOf(address(this), asset);
    }

    function getBalance() internal view returns (uint256) {
        LeverageState storage leverageState = diamondStorage();
        return leverageState.comet.balanceOf(address(this));
    }

    function getAssetInfo(
        address asset
    ) internal view returns (CometMainInterface.AssetInfo memory) {
        LeverageState storage leverageState = diamondStorage();
        return leverageState.comet.getAssetInfoByAddress(asset);
    }

    function getSupplyRate() internal view returns (uint256) {
        LeverageState storage leverageState = diamondStorage();
        //Supply APR = Supply Rate / (10 ^ 18) * Seconds Per Year * 100
        return leverageState.comet.getSupplyRate(getUtilization());
    }

    function getBorrowRate() internal view returns (uint256) {
        LeverageState storage leverageState = diamondStorage();
        //Borrow APR = Borrow Rate / (10 ^ 18) * Seconds Per Year * 100
        return leverageState.comet.getBorrowRate(getUtilization());
    }

    function getUtilization() internal view returns (uint256) {
        LeverageState storage leverageState = diamondStorage();
        return leverageState.comet.getUtilization();
    }

    function withdraw(address asset, uint256 amount) internal {
        LeverageState storage leverageState = diamondStorage();
        return leverageState.comet.withdraw(asset, amount);
    }

    function isLiquidatable(address account) internal view returns (bool) {
        LeverageState storage leverageState = diamondStorage();
        return leverageState.comet.isLiquidatable(account);
    }
}

contract LeverageFacet {
    function leverageUp(
        address collateral, //WETH
        address providedToken, //USDC
        uint256 userAmount,
        uint256 swapAmount
    ) external {
        LeverageLib.leverageUp(
            collateral, //WETH
            providedToken, //USDC
            userAmount,
            swapAmount
        );
    }

    function supply(address asset, uint256 amount) external {
        LeverageLib.supply(asset, amount);
    }

    function setComet(address cometAddy) external {
        LeverageLib.setComet(cometAddy);
    }

    function setCometData(address cometDataAddy) external {
        LeverageLib.setCometData(cometDataAddy);
    }

    function getCollateralBalance(
        address asset
    ) external view returns (uint256) {
        return LeverageLib.getCollateralBalance(asset);
    }

    function getBalance() external view returns (uint256) {
        return LeverageLib.getBalance();
    }

    function getAssetInfo(
        address asset
    ) external view returns (CometMainInterface.AssetInfo memory) {
        return LeverageLib.getAssetInfo(asset);
    }

    function getSupplyRate() external view returns (uint256) {
        return LeverageLib.getSupplyRate();
    }

    function getBorrowRate() external view returns (uint256) {
        return LeverageLib.getBorrowRate();
    }

    function getUtilization() external view returns (uint256) {
        return LeverageLib.getUtilization();
    }

    function withdraw(address asset, uint256 amount) external {
        return LeverageLib.withdraw(asset, amount);
    }

    function isLiquidatable(address account) external view returns (bool) {
        return LeverageLib.isLiquidatable(account);
    }
}
