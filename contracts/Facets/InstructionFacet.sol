// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LeverageFacet.sol";
import "./Hyperlane/HyperFacet.sol";
import "./ManagerFacet.sol";
import "./UniswapFacet.sol";
import "./SparkFacet.sol";
import "./Diamond/Test1Facet.sol";

library InstructionLib {
    function instrucLeverageUp(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x41));
        return bytes5(instruction);
    }

    function instrucClosePosition(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x10));
        return bytes5(instruction);
    }

    function instrucIsLiquidatable(bytes4 selc) internal pure returns (bytes5) {
        bytes memory instruction = abi.encodePacked(selc, bytes1(0x10));
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
}

contract InstructionFacet {
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
}
