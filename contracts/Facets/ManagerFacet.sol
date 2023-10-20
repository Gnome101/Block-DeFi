// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Example library to show a simple example of diamond storage

library ManagerLib {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.manager.storage");

    struct ManagerState {
        uint256 huh;
    }
    uint256 public constant INSTRUCTION_LENGTH = 0x20; //bytes5 type

    function diamondStorage() internal pure returns (ManagerState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function convertBytes5ArrayToBytes(
        bytes5[] memory data
    ) internal pure returns (bytes memory res) {
        for (uint i = 0; i < data.length; i++) {
            res = abi.encodePacked(res, data[i]);
        }
    }

    function convertAddyToNum(address a) internal pure returns (uint256) {
        return uint256(uint160(a));
    }

    function convertNumToAddy(uint256 a) internal pure returns (address) {
        return address(uint160(a));
    }

    function testDecodePacked(
        bytes memory packed
    ) internal pure returns (bytes5 info, bytes memory) {
        assembly {
            info := mload(add(packed, INSTRUCTION_LENGTH))
        }
        bytes memory newArray;
        for (uint256 i = 0; i < packed.length - 5; i++) {
            newArray = abi.encodePacked(newArray, packed[i + 5]);
        }
        // Trim the array by reducing its length
        return (info, newArray);
    }

    function addDataToFront(
        uint256[] memory data,
        bytes memory packedInfo
    ) internal pure returns (bytes memory packedResult) {
        packedResult = packedInfo;
        packedResult = abi.encode(data, packedInfo);
    }

    function readData(
        bytes memory data
    ) internal pure returns (uint256[] memory, bytes memory) {
        return abi.decode(data, (uint256[], bytes));
    }

    function executeInstruction(
        uint256[] memory inputs,
        bytes5 instruction
    ) internal returns (uint256[] memory outPuts) {
        (
            bytes4 selector,
            uint8 inputCount,
            uint8 outputCount
        ) = parseInstruction(instruction);
        bytes memory data;
        bool success;
        if (inputCount == 0) {
            (success, data) = address(this).call(
                abi.encodeWithSelector(selector)
            );
        } else {
            (success, data) = address(this).call(
                abi.encodeWithSelector(selector, inputs)
            );
        }

        if (outputCount == 0) {
            uint256[] memory newArray = new uint256[](1);
            newArray[0] = 0;

            return newArray;
        }
        if (outputCount == 1) {
            uint256 outPut1 = abi.decode(data, (uint256));
            uint256[] memory newArray = new uint256[](outputCount);

            newArray[0] = outPut1;

            return newArray;
        }
        if (outputCount == 2) {
            (uint256 outPut1, uint256 outPut2) = abi.decode(
                data,
                (uint256, uint256)
            );
            uint256[] memory newArray = new uint256[](outputCount);
            newArray[0] = outPut1;
            newArray[1] = outPut2;
            return newArray;
        }
        if (outputCount == 3) {
            (uint256 outPut1, uint256 outPut2, uint256 outPut3) = abi.decode(
                data,
                (uint256, uint256, uint256)
            );
            uint256[] memory newArray = new uint256[](outputCount);
            newArray[0] = outPut1;
            newArray[1] = outPut2;
            newArray[2] = outPut3;
            return newArray;
        }
    }

    function parseInstruction(
        bytes5 data
    ) internal pure returns (bytes4 selector, uint8 inp, uint8 out) {
        // Extract the first 4 bytes (selector)
        selector = (bytes4(data));

        bytes1 describer = data[4];
        inp = uint8(describer >> 4); // Shift 4 bits to the right to isolate the first 4 bits (1)
        out = uint8(describer & 0x0F);
    }

    function startWorking(
        bytes memory dataFlow
    ) internal returns (uint256[] memory finalOutputs) {
        (uint256[] memory inputs, bytes memory packedInstructions) = readData(
            dataFlow
        );
        bytes5 instruction;
        (instruction, dataFlow) = testDecodePacked(packedInstructions);
        finalOutputs = executeInstruction(inputs, instruction);
        if (dataFlow.length < 3) {
            return finalOutputs;
        }
        dataFlow = addDataToFront(finalOutputs, dataFlow);
        startWorking(dataFlow);
    }
}

contract ManagerFacet {
    function convertBytes5ArrayToBytes(
        bytes5[] memory data
    ) external pure returns (bytes memory res) {
        return ManagerLib.convertBytes5ArrayToBytes(data);
    }

    function convertAddyToNum(address a) external pure returns (uint256) {
        return ManagerLib.convertAddyToNum(a);
    }

    function convertNumToAddy(uint256 a) external pure returns (address) {
        return ManagerLib.convertNumToAddy(a);
    }

    function testDecodePacked(
        bytes memory packed
    ) external pure returns (bytes5 info, bytes memory) {
        return ManagerLib.testDecodePacked(packed);
    }

    function addDataToFront(
        uint256[] memory data,
        bytes memory packedInfo
    ) external pure returns (bytes memory packedResult) {
        return ManagerLib.addDataToFront(data, packedInfo);
    }

    function readData(
        bytes memory data
    ) external pure returns (uint256[] memory, bytes memory) {
        return ManagerLib.readData(data);
    }

    function executeInstruction(
        uint256[] memory inputs,
        bytes5 instruction
    ) external returns (uint256[] memory outPuts) {
        return ManagerLib.executeInstruction(inputs, instruction);
    }

    function parseInstruction(
        bytes5 data
    ) external pure returns (bytes4 selector, uint8 inp, uint8 out) {
        return ManagerLib.parseInstruction(data);
    }

    function startWorking(
        bytes memory dataFlow
    ) external returns (uint256[] memory finalOutputs) {
        return ManagerLib.startWorking(dataFlow);
    }
}
