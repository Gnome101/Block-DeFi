// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Interfaces/IMailbox.sol";
import "./Interfaces/IInterchainGasPaymaster.sol";
import "hardhat/console.sol";
import "../UMAFacet.sol";
import "../ManagerFacet.sol";

library HyperLib {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.hyperlane.storage");

    struct HyperState {
        address mailBox;
        address igp;
        mapping(uint256 => address) domainToAddress;
        uint256 counter;
    }

    function diamondStorage() internal pure returns (HyperState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setDomainToAddress(
        uint256 domainID,
        address recipentAddy
    ) internal {
        HyperState storage hyperState = diamondStorage();
        hyperState.domainToAddress[domainID] = recipentAddy;
    }

    function getRecipient(uint256 domainID) internal view returns (address) {
        HyperState storage hyperState = diamondStorage();
        return hyperState.domainToAddress[domainID];
    }

    function increaseCounter() internal {
        HyperState storage hyperState = diamondStorage();
        hyperState.counter = hyperState.counter + 1;
    }

    function getCounter() internal view returns (uint256) {
        HyperState storage hyperState = diamondStorage();
        return hyperState.counter;
    }

    function hitEmUp(
        uint32 targetDomain,
        uint256 gasAmount,
        uint256 _value
    ) internal {
        HyperState storage hyperState = diamondStorage();
        IMailbox MailBox = IMailbox(hyperState.mailBox);
        IInterchainGasPaymaster IGP = IInterchainGasPaymaster(hyperState.igp);

        address targetAddress = hyperState.domainToAddress[targetDomain];
        bytes32 messageID = MailBox.dispatch(
            targetDomain,
            addressToBytes32(targetAddress),
            abi.encode(msg.sender)
        );

        IGP.payForGas{value: _value}(
            messageID,
            targetDomain,
            gasAmount,
            msg.sender // refunds are returned to the sender
        );
    }

    function sendMessage(
        uint32 targetDomain,
        uint256 gasAmount,
        uint256 _value,
        bytes memory data
    ) internal {
        HyperState storage hyperState = diamondStorage();
        IMailbox MailBox = IMailbox(hyperState.mailBox);
        IInterchainGasPaymaster IGP = IInterchainGasPaymaster(hyperState.igp);

        address targetAddress = hyperState.domainToAddress[targetDomain];
        bytes32 messageID = MailBox.dispatch(
            targetDomain,
            addressToBytes32(targetAddress),
            abi.encode(msg.sender, data)
        );

        IGP.payForGas{value: _value}(
            messageID,
            targetDomain,
            gasAmount,
            msg.sender // refunds are returned to the sender
        );
    }

    uint256 public constant gasCost = 300000;

    function sendDataMumbai(uint256[] memory input) internal {
        uint32 domainTarget = 80001;
        uint256 gasEstimate = getQuote(domainTarget, gasCost);
        bytes memory data = ManagerLib.getCurrentFlow();

        bytes memory dataFlow = ManagerLib.addDataToFront(input, data);
        sendMessage(domainTarget, gasCost, gasEstimate, dataFlow);
    }

    function sendDataArbGoerli(uint256[] memory input) internal {
        uint32 domainTarget = 421613;
        uint256 gasEstimate = getQuote(domainTarget, gasCost);
        bytes memory data = ManagerLib.getCurrentFlow();
        bytes memory dataFlow = ManagerLib.addDataToFront(input, data);

        sendMessage(domainTarget, gasCost, gasEstimate, dataFlow);
    }

    function sendDataGoerli(uint256[] memory input) internal {
        uint32 domainTarget = 5;
        uint256 gasEstimate = getQuote(domainTarget, gasCost);
        bytes memory data = ManagerLib.getCurrentFlow();
        bytes memory dataFlow = ManagerLib.addDataToFront(input, data);

        sendMessage(domainTarget, gasCost, gasEstimate, dataFlow);
    }

    function sendDataBase(uint256[] memory input) internal {
        uint32 domainTarget = 84531;
        uint256 gasEstimate = getQuote(domainTarget, gasCost);
        bytes memory data = ManagerLib.getCurrentFlow();
        bytes memory dataFlow = ManagerLib.addDataToFront(input, data);

        sendMessage(domainTarget, gasCost, gasEstimate, dataFlow);
    }

    function sendDataGnosis(uint256[] memory input) internal {
        uint32 domainTarget = 100;
        uint256 gasEstimate = getQuote(domainTarget, gasCost);
        bytes memory data = ManagerLib.getCurrentFlow();
        bytes memory dataFlow = ManagerLib.addDataToFront(input, data);

        sendMessage(domainTarget, gasCost, gasEstimate, dataFlow);
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function interchainSecurityModule() internal view returns (address) {
        return address(this);
    }

    function setMailBox(address maiLBox) internal {
        HyperState storage hyperState = diamondStorage();
        hyperState.mailBox = maiLBox;
    }

    function setGasMaster(address localIGP) internal {
        HyperState storage hyperState = diamondStorage();
        hyperState.igp = localIGP;
    }

    function getGasMaster() internal view returns (address) {
        HyperState storage hyperState = diamondStorage();
        return hyperState.igp;
    }

    function getAddressForDomain(
        uint256 domainID
    ) internal view returns (address) {
        HyperState storage hyperState = diamondStorage();
        return hyperState.domainToAddress[domainID];
    }

    function getQuote(
        uint32 domain,
        uint256 amount
    ) internal view returns (uint256) {
        HyperState storage hyperState = diamondStorage();
        IInterchainGasPaymaster IGP = IInterchainGasPaymaster(hyperState.igp);
        return IGP.quoteGasPayment(domain, amount);
    }

    function verify(
        bytes calldata _metadata,
        bytes calldata _message
    ) internal returns (bool) {
        HyperState storage hyperState = diamondStorage();
        UMALib.UMAState storage umaState = UMALib.diamondStorage();

        hyperState.counter += 1;
        if (address(umaState.oov3) != address(0)) {
            bytes32 dataID = bytes32(hyperState.counter);
            bytes32 assertionID = UMALib.assertDataFor(
                dataID,
                bytes32(_message),
                address(this)
            );
            umaState.messageToAssertionID[bytes32(_message)] = assertionID;
        }
        //When the validator calls verify, we lock the state so the relayer pauses
        //Then after a 30s period for UMA review re-allow transactions to go through
        //Then the relayer is able to work. Muahhahhah
        return true;
    }

    function receiveMessage(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _body
    ) internal {
        UMALib.UMAState storage umaState = UMALib.diamondStorage();
        if (address(umaState.oov3) != address(0)) {
            bytes32 assertionID = umaState.messageToAssertionID[bytes32(_body)];
            UMALib.settleAndGetAssertionResult(assertionID);
        }

        HyperLib.increaseCounter();
        //Now we can continue flow
        ManagerLib.startWorking(_body);
    }

    function sendMessageToMumbai() internal {}
}

contract HyperFacet {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _body
    ) external {
        HyperLib.increaseCounter();
    }

    function hitEmUp(
        uint32 domain,
        uint256 gasAmount,
        uint256 _value
    ) external payable {
        HyperLib.hitEmUp(domain, gasAmount, _value);
    }

    function interchainSecurityModule() external view returns (address) {
        return HyperLib.interchainSecurityModule();
    }

    function setMailBox(address maiLBox) external {
        HyperLib.setMailBox(maiLBox);
    }

    function setGasMaster(address localIGP) external {
        HyperLib.setGasMaster(localIGP);
    }

    function getGasMaster() external view returns (address) {
        return HyperLib.getGasMaster();
    }

    function getCounter() external view returns (uint256) {
        return HyperLib.getCounter();
    }

    function setDomainToAddress(
        uint256 domainID,
        address recipentAddy
    ) external {
        HyperLib.setDomainToAddress(domainID, recipentAddy);
    }

    function getAddressForDomain(
        uint256 domainID
    ) external view returns (address) {
        return HyperLib.getAddressForDomain(domainID);
    }

    function getQuote(
        uint32 domain,
        uint256 amount
    ) external view returns (uint256) {
        return HyperLib.getQuote(domain, amount);
    }

    function moduleType() external pure returns (uint8) {
        return 6;
    }

    function verify(
        bytes calldata _metadata,
        bytes calldata _message
    ) external returns (bool) {
        return HyperLib.verify(_metadata, _message);
    }

    function sendDataMumbai(uint256[] memory inputs) external {
        HyperLib.sendDataMumbai(inputs);
    }

    function sendDataArbGoerli(uint256[] memory inputs) external {
        HyperLib.sendDataArbGoerli(inputs);
    }

    function sendDataGoerli(uint256[] memory inputs) external {
        HyperLib.sendDataGoerli(inputs);
    }

    function sendDataBase(uint256[] memory inputs) external {
        HyperLib.sendDataBase(inputs);
    }

    function sendDataGnosis(uint256[] memory inputs) external {
        HyperLib.sendDataGnosis(inputs);
    }
}
