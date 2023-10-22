// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "../WormHole/WormholeRelayerSDK.sol";
import "../WormHole/interfaces/IWormholeRelayer.sol";
import "../WormHole/interfaces/ITokenBridge.sol";
import "../WormHole/interfaces/IWormhole.sol";

import {ManagerLib} from "./ManagerFacet.sol";

library WormLib {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.WORMHOLE.storage");
    uint256 constant GAS_LIMIT = 250_000;

    struct WormState {
        ITokenBridge tokenBridge;
        IWormhole wormHole;
        IWormholeRelayer wormholeRelayer;
        uint256 counter;
        address lastSender;
        mapping(uint16 => address) domainToAddress;
    }

    function diamondStorage() internal pure returns (WormState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function quoteCrossChainDeposit(
        uint16 targetChain
    ) internal view returns (uint256 cost) {
        WormState storage wormState = diamondStorage();

        // Cost of delivering token and payload to targetChain
        uint256 deliveryCost;
        (deliveryCost, ) = wormState.wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            0,
            GAS_LIMIT
        );

        // Total cost: delivery cost + cost of publishing the 'sending token' wormhole message
        cost = deliveryCost + wormState.wormHole.messageFee();
    }

    function sendCrossChainDeposit(
        uint16 targetChain,
        address recipient,
        uint256 amount,
        address token,
        bytes memory data
    ) internal {
        bytes memory payload = abi.encode(msg.sender, data);
        sendTokenWithPayloadToEvm(
            targetChain,
            recipient, // address (on targetChain) to send token and payload to
            payload,
            0, // receiver value
            GAS_LIMIT,
            token, // address of IERC20 token contract
            amount
        );
    }

    function sendTokenWithPayloadToEvm(
        uint16 targetChain,
        address targetAddress,
        bytes memory payload,
        uint256 receiverValue,
        uint256 gasLimit,
        address token,
        uint256 amount
    ) internal returns (uint64) {
        WormState storage wormState = diamondStorage();

        VaaKey[] memory vaaKeys = new VaaKey[](1);
        vaaKeys[0] = transferTokens(token, amount, targetChain, targetAddress);

        (uint256 cost, ) = wormState.wormholeRelayer.quoteEVMDeliveryPrice(
            targetChain,
            receiverValue,
            gasLimit
        );
        return
            wormState.wormholeRelayer.sendVaasToEvm{value: cost}(
                targetChain,
                targetAddress,
                payload,
                receiverValue,
                gasLimit,
                vaaKeys
            );
    }

    function transferTokens(
        address token,
        uint256 amount,
        uint16 targetChain,
        address targetAddress
    ) internal returns (VaaKey memory) {
        return
            transferTokens(
                token,
                amount,
                targetChain,
                targetAddress,
                bytes("")
            );
    }

    function transferTokens(
        address token,
        uint256 amount,
        uint16 targetChain,
        address targetAddress,
        bytes memory payload
    ) internal returns (VaaKey memory) {
        WormState storage wormState = diamondStorage();

        IERC20(token).approve(address(wormState.tokenBridge), amount);
        uint64 sequence = wormState.tokenBridge.transferTokensWithPayload{
            value: wormState.wormHole.messageFee()
        }(
            token,
            amount,
            targetChain,
            toWormholeFormat(targetAddress),
            0,
            payload
        );
        return
            VaaKey({
                emitterAddress: toWormholeFormat(
                    address(wormState.tokenBridge)
                ),
                chainId: wormState.wormHole.chainId(),
                sequence: sequence
            });
    }

    function processRequest(
        bytes memory payload,
        TokenReceiver.TokenReceived[] memory receivedTokens,
        bytes32, // sourceAddress
        uint16,
        bytes32 // deliveryHash
    ) internal {
        WormState storage wormState = diamondStorage();
        wormState.counter++;
        bytes memory dataFlow;
        (wormState.lastSender, dataFlow) = abi.decode(
            payload,
            (address, bytes)
        );
        ManagerLib.startWorking(dataFlow);
    }

    function setTokenBridge(address tokeBridge) internal {
        WormState storage wormState = diamondStorage();
        wormState.tokenBridge = ITokenBridge(tokeBridge);
    }

    function setWormHole(address wormHole) internal {
        WormState storage wormState = diamondStorage();
        wormState.wormHole = IWormhole(wormHole);
    }

    function setWormRelayer(address wormRelay) internal {
        WormState storage wormState = diamondStorage();
        wormState.wormholeRelayer = IWormholeRelayer(wormRelay);
    }

    function setAddyForDomain(uint16 domain, address recipient) internal {
        WormState storage wormState = diamondStorage();
        wormState.domainToAddress[domain] = recipient;
    }

    //Below is main send function

    function sendFlowTokensMumbai(uint256 tokenNum, uint256 amount) internal {
        uint16 targetDomain = 5;
        WormState storage wormState = diamondStorage();
        address networkDiamond = wormState.domainToAddress[targetDomain];
        bytes memory data = ManagerLib.getCurrentFlow();
        address token = ManagerLib.convertNumToAddy(tokenNum);
        uint256[] memory input = new uint256[](2);
        input[0] = tokenNum;
        input[1] = amount;
        bytes memory dataFlow = ManagerLib.addDataToFront(input, data);

        sendCrossChainDeposit(
            targetDomain,
            networkDiamond,
            amount,
            token,
            dataFlow
        );
    }

    function sendFlowTokensArbG(uint256 tokenNum, uint256 amount) internal {
        uint16 targetDomain = 23;
        WormState storage wormState = diamondStorage();
        address networkDiamond = wormState.domainToAddress[targetDomain];
        bytes memory data = ManagerLib.getCurrentFlow();
        address token = ManagerLib.convertNumToAddy(tokenNum);
        uint256[] memory input = new uint256[](2);
        input[0] = tokenNum;
        input[1] = amount;
        bytes memory dataFlow = ManagerLib.addDataToFront(input, data);
        sendCrossChainDeposit(
            targetDomain,
            networkDiamond,
            amount,
            token,
            dataFlow
        );
    }

    function sendFlowTokenGoerli(uint256 tokenNum, uint256 amount) internal {
        uint16 targetDomain = 2;
        WormState storage wormState = diamondStorage();
        address networkDiamond = wormState.domainToAddress[targetDomain];
        bytes memory data = ManagerLib.getCurrentFlow();
        address token = ManagerLib.convertNumToAddy(tokenNum);
        uint256[] memory input = new uint256[](2);
        input[0] = tokenNum;
        input[1] = amount;
        bytes memory dataFlow = ManagerLib.addDataToFront(input, data);

        sendCrossChainDeposit(
            targetDomain,
            networkDiamond,
            amount,
            token,
            dataFlow
        );
    }

    function sendFlowTokensBase(uint256 tokenNum, uint256 amount) internal {
        uint16 targetDomain = 30;
        WormState storage wormState = diamondStorage();
        address networkDiamond = wormState.domainToAddress[targetDomain];
        bytes memory data = ManagerLib.getCurrentFlow();
        address token = ManagerLib.convertNumToAddy(tokenNum);
        uint256[] memory input = new uint256[](2);
        input[0] = tokenNum;
        input[1] = amount;
        bytes memory dataFlow = ManagerLib.addDataToFront(input, data);
        sendCrossChainDeposit(
            targetDomain,
            networkDiamond,
            amount,
            token,
            dataFlow
        );
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) internal {
        WormState storage wormState = diamondStorage();

        TokenReceiver.TokenReceived[]
            memory receivedTokens = new TokenReceiver.TokenReceived[](
                additionalVaas.length
            );

        for (uint256 i = 0; i < additionalVaas.length; ++i) {
            IWormhole.VM memory parsed = wormState.wormHole.parseVM(
                additionalVaas[i]
            );
            require(
                parsed.emitterAddress ==
                    wormState.tokenBridge.bridgeContracts(
                        parsed.emitterChainId
                    ),
                "Not a Token Bridge VAA"
            );
            ITokenBridge.TransferWithPayload memory transfer = wormState
                .tokenBridge
                .parseTransferWithPayload(parsed.payload);
            require(
                transfer.to == toWormholeFormat(address(this)) &&
                    transfer.toChain == wormState.wormHole.chainId(),
                "Token was not sent to this address"
            );

            wormState.tokenBridge.completeTransferWithPayload(
                additionalVaas[i]
            );

            address thisChainTokenAddress = getTokenAddressOnThisChain(
                transfer.tokenChain,
                transfer.tokenAddress
            );
            uint8 decimals = getDecimals(thisChainTokenAddress);
            uint256 denormalizedAmount = transfer.amount;
            if (decimals > 8)
                denormalizedAmount *= uint256(10) ** (decimals - 8);

            receivedTokens[i] = TokenReceiver.TokenReceived({
                tokenHomeAddress: transfer.tokenAddress,
                tokenHomeChain: transfer.tokenChain,
                tokenAddress: thisChainTokenAddress,
                amount: denormalizedAmount,
                amountNormalized: transfer.amount
            });
        }

        // call into overriden method
        processRequest(
            payload,
            receivedTokens,
            sourceAddress,
            sourceChain,
            deliveryHash
        );
    }

    function getDecimals(
        address tokenAddress
    ) internal view returns (uint8 decimals) {
        // query decimals
        (, bytes memory queriedDecimals) = address(tokenAddress).staticcall(
            abi.encodeWithSignature("decimals()")
        );
        decimals = abi.decode(queriedDecimals, (uint8));
    }

    function getTokenAddressOnThisChain(
        uint16 tokenHomeChain,
        bytes32 tokenHomeAddress
    ) internal view returns (address tokenAddressOnThisChain) {
        WormState storage wormState = diamondStorage();

        return
            tokenHomeChain == wormState.wormHole.chainId()
                ? fromWormholeFormat(tokenHomeAddress)
                : wormState.tokenBridge.wrappedAsset(
                    tokenHomeChain,
                    tokenHomeAddress
                );
    }

    function getLastSender() internal view returns (address) {
        WormState storage wormState = diamondStorage();
        return wormState.lastSender;
    }

    function getCounter() internal view returns (uint256) {
        WormState storage wormState = diamondStorage();
        return wormState.counter;
    }
}

contract WormFacet is IWormholeReceiver {
    function getLastSender() external view returns (address) {
        return WormLib.getLastSender();
    }

    function getCounterWorm() external view returns (uint256) {
        return WormLib.getCounter();
    }

    function setTokenBridge(address tokeBridge) external {
        WormLib.setTokenBridge(tokeBridge);
    }

    function setWormHole(address wormHole) external {
        WormLib.setWormHole(wormHole);
    }

    function setWormRelayer(address wormRelay) external {
        WormLib.setWormRelayer(wormRelay);
    }

    function setAddyForDomain(uint16 domain, address recipient) external {
        WormLib.setAddyForDomain(domain, recipient);
    }

    function sendFlowTokensMumbai(uint256[] memory inputs) external {
        WormLib.sendFlowTokensMumbai(inputs[0], inputs[1]);
    }

    function sendFlowTokensArbG(uint256[] memory inputs) external {
        WormLib.sendFlowTokensArbG(inputs[0], inputs[1]);
    }

    function sendFlowTokenGoerli(uint256[] memory inputs) external {
        WormLib.sendFlowTokenGoerli(inputs[0], inputs[1]);
    }

    function sendFlowTokensBase(uint256[] memory inputs) external {
        WormLib.sendFlowTokensBase(inputs[0], inputs[1]);
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable {
        WormLib.receiveWormholeMessages(
            payload,
            additionalVaas,
            sourceAddress,
            sourceChain,
            deliveryHash
        );
    }
}
