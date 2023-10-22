function getData(domain) {
  switch (domain) {
    case 421613:
      return {
        Network: "arbogerli",
        MailBox: "0xCC737a94FecaeC165AbCf12dED095BB13F037685",
        GasPayMaster: "0x8f9C3888bFC8a5B25AED115A82eCbb788b196d2a",
        Diamond: "0xDbD0a46Bc529570Ab594b79A8f4467A6A6F289eA",
        cometUSDC: "0x1d573274E19174260c5aCE3f2251598959d24456",
        USDC: "0x8FB1E3fC51F3b789dED7557E680551d93Ea9d892",
        WETH: "0xe39Ab88f8A4777030A534146A9Ca3B52bd5D43A3",
        PoolManager: "0x4B8c70cF3e595D963cD4A33627d4Ba2718fD706F",
      };
    case 5:
      return {
        Network: "goerli",
        MailBox: "0xCC737a94FecaeC165AbCf12dED095BB13F037685",
        GasPayMaster: "0x0cD26594ea6c6526927C0F5225AC09F6288e7140",
        OOV3: "0x9923D42eF695B5dd9911D05Ac944d4cAca3c4EAB",
        SparkLend: "0x26ca51Af4506DE7a6f0785D20CD776081a05fF6d",
        cometUSDC: "0x3EE77595A8459e93C2888b13aDB354017B198188",
        USDC: "0x07865c6E87B9F70255377e024ace6630C1Eaa37F",
        WETH: "0x42a71137C09AE83D8d05974960fd607d40033499",
        PoolManager: "0x862Fa52D0c8Bca8fBCB5213C9FEbC49c87A52912",
      };
    case 84531:
      return {
        Network: "basegoerli",
        MailBox: "0x58483b754Abb1E8947BE63d6b95DF75b8249543A",
        GasPayMaster: "0x28B02B97a850872C4D33C3E024fab6499ad96564",
        OOV3: "0x1F4dC6D69E3b4dAC139E149E213a7e863a813466",
        cometUSDC: "0xe78Fc55c884704F9485EDa042fb91BfE16fD55c1",
        USDC: "0x31D3A7711a74b4Ec970F50c3eaf1ee47ba803A95",
        WETH: "0x4200000000000000000000000000000000000006",
        PoolManager: "0x693B1C9fBb10bA64F0d97AE042Ee32aE9Eb5610D",
      };
    case 80001:
      return {
        Network: "mumbai",
        MailBox: "0xCC737a94FecaeC165AbCf12dED095BB13F037685",
        GasPayMaster: "0x8f9C3888bFC8a5B25AED115A82eCbb788b196d2a",
        Diamond: "0x837024764826ec6fdEF5c8a05F36F6cdb62B4759",
        OOV3: "0x263351499f82C107e540B01F0Ca959843e22464a",
        cometUSDC: "0xF09F0369aB0a875254fB565E52226c88f10Bc839",
        USDC: "0xDB3cB4f2688daAB3BFf59C24cC42D4B6285828e9",
        DAI: "0x4DAFE12E1293D889221B1980672FE260Ac9dDd28",
        WETH: "0xE1e67212B1A4BF629Bdf828e08A3745307537ccE",
        PoolManager: "0x5ff8780e4d20e75b8599a9c4528d8ac9682e5c89",
      };
    case 100:
      return {
        Network: "gnosis",
        MailBox: "0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70",
        GasPayMaster: "0x6cA0B6D22da47f091B7613223cD4BB03a2d77918",
        SparkLend: "0x2Dae5307c5E3FD1CF5A72Cb6F698f915860607e0",
        OOV3: "0x22A9AaAC9c3184f68C7B7C95b1300C4B1D2fB95C",
        PoolManager: "",
      };
    case 31337:
      return {
        Network: "forkedMainNet",
        MailBox: "0x35231d4c2D8B8ADcB5617A638A0c4548684c7C70",
        GasPayMaster: "0x6cA0B6D22da47f091B7613223cD4BB03a2d77918",
      };
    default:
      console.log(domain, "is not in database");
    // Code to execute if expression doesn't match any case
  }
}
exports.getData = getData;
