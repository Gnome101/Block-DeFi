function getData(domain) {
  switch (domain) {
    case 421613:
      return {
        Network: "arbogerli",
        MailBox: "0xCC737a94FecaeC165AbCf12dED095BB13F037685",
        GasPayMaster: "0x76189acFA212298d7022624a4633411eE0d2f26F",
      };
    case 5:
      return {
        Network: "goerli",
        MailBox: "0xCC737a94FecaeC165AbCf12dED095BB13F037685",
        GasPayMaster: "0x0cD26594ea6c6526927C0F5225AC09F6288e7140",
      };
    case 534351:
      return {
        Network: "scroll",
        MailBox: "0x3C5154a193D6e2955650f9305c8d80c18C814A68",
        GasPayMaster: "0x86fb9F1c124fB20ff130C41a79a432F770f67AFD",
      };
    case 84531:
      return {
        Network: "basegoerli",
        MailBox: "0x58483b754Abb1E8947BE63d6b95DF75b8249543A",
        GasPayMaster: "0x28B02B97a850872C4D33C3E024fab6499ad96564",
      };
    case 80001:
      return {
        Network: "mumbai",
        MailBox: "0x2d1889fe5B092CD988972261434F7E5f26041115",
        GasPayMaster: "0x8aB67CAF605c6ee83cbFeFb0D8d67FDd3BF7B591",
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
