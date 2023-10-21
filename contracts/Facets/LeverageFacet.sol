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

import "./ManagerFacet.sol";
import "./UniswapFacet.sol";
struct levPos {
    uint256 userAmount;
    uint256 swapAmount;
    uint256 borrowedAmount;
    address collateral;
    address providedToken;
}

library LeverageLib {
    using CurrencyLibrary for Currency;
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.leverage.storage");

    struct LeverageState {
        CometMainInterface comet;
        CometExtInterface cometData;
        mapping(uint256 => levPos) compPositons;
        uint256 posCounter;
        mapping(address => uint256[]) userPositions;
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
        uint256 collateralNum, //WETH
        uint256 providedTokenNum, //USDC
        uint256 userAmount,
        uint256 swapAmount
    ) internal returns (uint256) {
        LeverageState storage leverageState = diamondStorage();
        address collateral = ManagerLib.convertNumToAddy(collateralNum);
        address providedToken = ManagerLib.convertNumToAddy(providedTokenNum);
        UniswapLib.FlashLeverage memory leverageInfo = UniswapLib
            .FlashLeverage({
                collateral: collateral,
                providedToken: providedToken,
                userAmount: userAmount,
                swapAmount: swapAmount
            });
        //Swap has been called
        bytes memory data = UniswapLib.flashSwapTokens(
            providedToken,
            collateral,
            -int256(swapAmount),
            ActionType.CompLeverage,
            leverageInfo
        );
        leverageState.userPositions[address(this)].push(
            leverageState.posCounter - 1
        );
        return leverageState.posCounter - 1;
    }

    function closePosition(uint256 counter) internal {
        LeverageState storage leverageState = diamondStorage();

        address providedToken = leverageState.compPositons[counter].collateral;
        address collateral = leverageState.compPositons[counter].providedToken;

        UniswapLib.UniswapState storage uniswapState = UniswapLib
            .diamondStorage();

        uint256 collateralBalanceBefore = IERC20(providedToken).balanceOf(
            address(uniswapState.poolManager)
        );
        uint256 amountOwed = leverageState.comet.borrowBalanceOf(address(this));
        UniswapLib.FlashLeverage memory leverageInfo = UniswapLib
            .FlashLeverage({
                collateral: collateral,
                providedToken: providedToken,
                userAmount: 0,
                swapAmount: amountOwed
            });
        //Swap has been called
        bytes memory data = UniswapLib.flashSwapTokens(
            providedToken,
            collateral,
            -int256(amountOwed),
            ActionType.CompLeverage,
            leverageInfo
        );

        uint256 collateralBalanceAfter = IERC20(providedToken).balanceOf(
            address(uniswapState.poolManager)
        );
        console.log(
            leverageState.compPositons[counter].swapAmount,
            collateralBalanceAfter,
            collateralBalanceBefore
        );
        uint256 fee = collateralBalanceAfter -
            collateralBalanceBefore -
            leverageState.compPositons[counter].swapAmount;
        uint256 amountRecieved = leverageState
            .compPositons[counter]
            .userAmount - fee;
        console.log(amountRecieved);
        withdraw(providedToken, amountRecieved);
    }

    function completeLeverage(
        PoolKey memory poolKey,
        uint256 counter,
        address user
    ) internal {
        LeverageState storage leverageState = diamondStorage();

        UniswapLib.UniswapState storage uniswapState = UniswapLib
            .diamondStorage();
        BalanceDelta delta;

        UniswapLib.FlashLeverage memory leverageInfo = uniswapState.leveragePos[
            counter
        ];

        delta = uniswapState.poolManager.swap(
            poolKey,
            uniswapState.swaps[counter],
            "0x"
        );
        uint128 amountNeededToBorrow;
        if (leverageInfo.providedToken < leverageInfo.collateral) {
            //Provided token is t0
            //We receved collateral
            UniswapLib._settleCurrencyBalance(
                poolKey.currency1,
                delta.amount1()
            );
            amountNeededToBorrow = uint128(delta.amount0());
        } else {
            UniswapLib._settleCurrencyBalance(
                poolKey.currency0,
                delta.amount0()
            );
            amountNeededToBorrow = uint128(delta.amount1());
        }

        supply(
            leverageInfo.collateral,
            leverageInfo.swapAmount + leverageInfo.userAmount
        );
        withdraw(leverageInfo.providedToken, amountNeededToBorrow);

        leverageState.compPositons[leverageState.posCounter] = levPos({
            userAmount: leverageInfo.userAmount,
            swapAmount: leverageInfo.swapAmount,
            borrowedAmount: amountNeededToBorrow,
            collateral: leverageInfo.collateral,
            providedToken: leverageInfo.providedToken
        });
        leverageState.userPositions[user].push(leverageState.posCounter);
        leverageState.posCounter++;

        UniswapLib._settleCurrencyBalance(
            Currency.wrap(leverageInfo.providedToken),
            int128(amountNeededToBorrow)
        );
        //withdraw(leverageInfo.collateral,)
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

    function isLiquidatable(
        uint256 numAddy
    ) internal view returns (uint256, uint256) {
        LeverageState storage leverageState = diamondStorage();
        address account = ManagerLib.convertNumToAddy(numAddy);
        console.log(account, address(this));
        uint256 id = leverageState.userPositions[account][0];
        console.log(
            "Is it liquidateable? ",
            leverageState.comet.isLiquidatable(account)
        );
        return (leverageState.comet.isLiquidatable(account) ? 1 : 0, id);
    }

    function returnProfit(
        uint256 positionId
    ) internal returns (uint256, uint256) {
        //This should be called optimistaclly
        LeverageState storage leverageState = diamondStorage();
        //Use price of tokens or build a quoter to determine how much the user
        //collateral would swap for and then compare that to how much they
        //put in originally
        uint256 collateralBalanceBefore = IERC20(
            leverageState.compPositons[positionId].collateral
        ).balanceOf(address(this));
        console.log(
            leverageState.compPositons[positionId].collateral,
            leverageState.compPositons[positionId].providedToken
        );
        closePosition(positionId);

        uint256 collateralBalanceAfter = IERC20(
            leverageState.compPositons[positionId].collateral
        ).balanceOf(address(this));

        uint256 amountRetrieved = collateralBalanceAfter -
            collateralBalanceBefore;
        console.log(
            leverageState.compPositons[positionId].userAmount,
            amountRetrieved
        );
        if (
            amountRetrieved < leverageState.compPositons[positionId].userAmount
        ) {
            return (
                0,
                leverageState.compPositons[positionId].userAmount -
                    amountRetrieved
            );
        } else {
            return (
                1,
                amountRetrieved -
                    leverageState.compPositons[positionId].userAmount
            );
        }
    }
}

contract LeverageFacet {
    function leverageUp(uint256[] memory inputs) external returns (uint256) {
        return
            LeverageLib.leverageUp(
                inputs[0], //WETH
                inputs[1], //USDC
                inputs[2],
                inputs[3]
            );
    }

    function closePosition(uint256[] memory nums) external {
        LeverageLib.closePosition(nums[0]);
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

    function isLiquidatable(
        uint256[] memory nums
    ) external view returns (uint256, uint256) {
        return LeverageLib.isLiquidatable(nums[0]);
    }

    function returnProfit(
        uint256[] memory num
    ) external returns (uint256, uint256) {
        return LeverageLib.returnProfit(num[0]);
    }
}
