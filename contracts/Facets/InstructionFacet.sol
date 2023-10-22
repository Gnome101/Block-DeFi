// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LeverageFacet.sol";
import "./Hyperlane/HyperFacet.sol";
import "./ManagerFacet.sol";
import "./UniswapFacet.sol";
import "./SparkFacet.sol";
import "./Diamond/Test1Facet.sol";
import "./ControlFacet.sol";
import {WormFacet} from "./WormFacet.sol";

library InstructionLib {
    //ManagerFacet
    function instrucStop(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x00));
        return bytes5(instruction);
    }

    //Compound leverage up
    function instrucLeverageUp(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x41));
        return bytes5(instruction);
    }

    function instrucClosePosition(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x10));
        return bytes5(instruction);
    }

    function instrucIsLiquidatable(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x12));
        return bytes5(instruction);
    }

    function instrucGetBorrowRate(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x01));
        return bytes5(instruction);
    }

    function instrucGetSupplyRate(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x01));
        return bytes5(instruction);
    }

    function instrucgetUtilization(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x01));
        return bytes5(instruction);
    }

    function instrucReturnProfit(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x12));
        return bytes5(instruction);
    }

    function instrucWithdraw(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x20));
        return bytes5(instruction);
    }

    function instrucSupply(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x20));
        return bytes5(instruction);
    }

    //Test Facet
    function instrucSetNumber(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x12));
        return bytes5(instruction);
    }

    function instrucGetNumber(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x01));
        return bytes5(instruction);
    }

    function instrucGetSum(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x21));

        return bytes5(instruction);
    }

    //Control Facet

    function instrucIfTrueContinue(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x11));

        return bytes5(instruction);
    }

    function instrucIfTrueContinueWResult(
        bytes4 selc
    ) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x21));

        return bytes5(instruction);
    }

    function instrucContinueIfOutOfBounds(
        bytes4 selc
    ) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x22));

        return bytes5(instruction);
    }

    function instrucAdjustBounds(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x20));

        return bytes5(instruction);
    }

    //UniswapFacet

    function instrucSwap(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x33));

        return bytes5(instruction);
    }

    function instrucCloseLP(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x42));

        return bytes5(instruction);
    }

    function instrucAddLiquidity(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x62));

        return bytes5(instruction);
    }

    function instrucGetPoolLiquidity(
        bytes4 selc
    ) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x21));

        return bytes5(instruction);
    }

    function instrucReturnBounds(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x02));

        return bytes5(instruction);
    }

    function instrucModifyPosition(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x60));
        return bytes5(instruction);
    }

    //Spark Facet
    function instrucSupplySpark(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x21));
        return bytes5(instruction);
    }

    function instrucBorrowSpark(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x21));
        return bytes5(instruction);
    }

    function instrucRepaySpark(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x21));
        return bytes5(instruction);
    }

    function instrucWithdrawSpark(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x21));
        return bytes5(instruction);
    }

    function instrucLeverageUpSpark(
        bytes4 selc
    ) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x41));

        return bytes5(instruction);
    }

    function instrucClosePositionSpark(
        bytes4 selc
    ) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x10));

        return bytes5(instruction);
    }

    function instrucGetHFSpark(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x01));

        return bytes5(instruction);
    }

    //HyperFacet
    function instrucSendDataMumbai(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x10));

        return bytes5(instruction);
    }

    function instrucSendDataArbGoerli(
        bytes4 selc
    ) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x10));

        return bytes5(instruction);
    }

    function instrucSendDataGoerli(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x10));

        return bytes5(instruction);
    }

    function instrucSendDataBase(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x10));
        return bytes5(instruction);
    }

    //WormHole Facet
    function instrucsendFlowTokensMumbai(
        bytes4 selc
    ) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x20));
        return bytes5(instruction);
    }

    function instrucsendFlowTokensArbG(
        bytes4 selc
    ) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x20));
        return bytes5(instruction);
    }

    function instrucsendFlowTokensGoerli(
        bytes4 selc
    ) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x20));
        return bytes5(instruction);
    }

    function instrucsendFlowTokensBase(
        bytes4 selc
    ) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x20));
        return bytes5(instruction);
    }
}

contract InstructionFacet {
    function instrucStop() external pure returns (bytes5) {
        return
            InstructionLib.instrucLeverageUp(
                ManagerFacet.stopExecution.selector
            );
    }

    //Leverage Fact for Compound
    function instrucLeverageUp() external pure returns (bytes5) {
        return
            InstructionLib.instrucLeverageUp(LeverageFacet.leverageUp.selector);
    }

    function instrucClosePosition() external pure returns (bytes5) {
        return
            InstructionLib.instrucClosePosition(
                LeverageFacet.closePosition.selector
            );
    }

    function instrucIsLiquidatable() external pure returns (bytes5) {
        return
            InstructionLib.instrucIsLiquidatable(
                LeverageFacet.isLiquidatable.selector
            );
    }

    function instrucGetBorrowRate() external pure returns (bytes5) {
        return
            InstructionLib.instrucGetBorrowRate(
                LeverageFacet.getBorrowRate.selector
            );
    }

    function instrucGetSupplyRate() external pure returns (bytes5) {
        return
            InstructionLib.instrucGetSupplyRate(
                LeverageFacet.getSupplyRate.selector
            );
    }

    function instrucReturnProfit() external pure returns (bytes5) {
        return
            InstructionLib.instrucReturnProfit(
                LeverageFacet.returnProfit.selector
            );
    }

    function instrucSetNumber() external pure returns (bytes5) {
        return InstructionLib.instrucSetNumber(Test1Facet.setNumber.selector);
    }

    function instrucGetNumber() external pure returns (bytes5) {
        return InstructionLib.instrucGetNumber(Test1Facet.getNumber.selector);
    }

    function instrucGetSum() external pure returns (bytes5) {
        return InstructionLib.instrucGetSum(Test1Facet.getSum.selector);
    }

    //ControlFacet

    function instrucIfTrueContinue() external pure returns (bytes5) {
        return
            InstructionLib.instrucIfTrueContinue(
                ControlFacet.ifTrueContinue.selector
            );
    }

    function instrucIfTrueContinueWResult() external pure returns (bytes5) {
        return
            InstructionLib.instrucIfTrueContinueWResult(
                ControlFacet.ifTrueContinueWResult.selector
            );
    }

    function instrucContinueIfOutOfBounds() external pure returns (bytes5) {
        return
            InstructionLib.instrucContinueIfOutOfBounds(
                ControlFacet.continueIfOutOfBounds.selector
            );
    }

    function instrucAdjustBounds() external pure returns (bytes5) {
        return
            InstructionLib.instrucAdjustBounds(
                ControlFacet.adjustBounds.selector
            );
    }

    //Uniswap Facet
    function instrucSwap() external pure returns (bytes5) {
        return InstructionLib.instrucSwap(UniswapFacet.swap.selector);
    }

    function instrucCloseLP() external pure returns (bytes5) {
        return
            InstructionLib.instrucCloseLP(UniswapFacet.closePosition.selector);
    }

    function instrucGetPoolLiquidity() external pure returns (bytes5) {
        return
            InstructionLib.instrucGetPoolLiquidity(
                UniswapFacet.getPoolLiquidity.selector
            );
    }

    function instrucReturnBounds() external pure returns (bytes5) {
        return
            InstructionLib.instrucReturnBounds(
                UniswapFacet.returnBounds.selector
            );
    }

    function instrucModifyPosition() external pure returns (bytes5) {
        return
            InstructionLib.instrucModifyPosition(
                UniswapFacet.modifyPosition.selector
            );
    }

    function instrucAddLiquidty() external pure returns (bytes5) {
        return
            InstructionLib.instrucAddLiquidity(
                UniswapFacet.addLiquidty.selector
            );
    }

    //Spark Facet

    function instrucSupplySpark() external pure returns (bytes5) {
        return
            InstructionLib.instrucSupplySpark(SparkFacet.supplySpark.selector);
    }

    function instrucBorrowSpark() external pure returns (bytes5) {
        return
            InstructionLib.instrucBorrowSpark(SparkFacet.borrowSpark.selector);
    }

    function instrucRepaySpark() external pure returns (bytes5) {
        return InstructionLib.instrucRepaySpark(SparkFacet.repaySpark.selector);
    }

    function instrucWithdrawSpark() external pure returns (bytes5) {
        return
            InstructionLib.instrucWithdrawSpark(
                SparkFacet.withdrawSpark.selector
            );
    }

    function instrucLeverageUpSpark() external pure returns (bytes5) {
        return
            InstructionLib.instrucLeverageUpSpark(
                SparkFacet.leverageUpSpark.selector
            );
    }

    function instrucClosePositionSpark() external pure returns (bytes5) {
        return
            InstructionLib.instrucClosePositionSpark(
                SparkFacet.closePositionSpark.selector
            );
    }

    function instrucGetHFSpark() external pure returns (bytes5) {
        return InstructionLib.instrucGetHFSpark(SparkFacet.getHF.selector);
    }

    //HyperFacet
    function instrucSendDataMumbai() external pure returns (bytes5) {
        return
            InstructionLib.instrucSendDataMumbai(
                HyperFacet.sendDataMumbai.selector
            );
    }

    function instrucSendDataArbGoerli() external pure returns (bytes5) {
        return
            InstructionLib.instrucSendDataArbGoerli(
                HyperFacet.sendDataArbGoerli.selector
            );
    }

    function instrucSendDataGoerli() external pure returns (bytes5) {
        return
            InstructionLib.instrucSendDataGoerli(
                HyperFacet.sendDataGoerli.selector
            );
    }

    function instrucSendDataBase() external pure returns (bytes5) {
        return
            InstructionLib.instrucSendDataBase(
                HyperFacet.sendDataBase.selector
            );
    }

    //WormHole Facet
    function instrucSendFlowTokensMumbai() external pure returns (bytes5) {
        return
            InstructionLib.instrucsendFlowTokensMumbai(
                WormFacet.sendFlowTokensMumbai.selector
            );
    }

    function instrucSendFlowTokensArbG() external pure returns (bytes5) {
        return
            InstructionLib.instrucsendFlowTokensArbG(
                WormFacet.sendFlowTokensArbG.selector
            );
    }

    function instrucSendFlowTokensGoerli() external pure returns (bytes5) {
        return
            InstructionLib.instrucsendFlowTokensGoerli(
                WormFacet.sendFlowTokenGoerli.selector
            );
    }

    function instrucSendFlowTokensBase() external pure returns (bytes5) {
        return
            InstructionLib.instrucsendFlowTokensBase(
                WormFacet.sendFlowTokensBase.selector
            );
    }
}
