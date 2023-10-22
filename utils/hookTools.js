async function getSalt(hookFactory, diamondCutArgs, regularArgs, prefix) {
  let salt;
  let predictedAddy;

  for (let i = 845; i < 3000; i++) {
    //Convert our integer in decimal to hex
    salt = ethers.toBeHex(i);

    //Padd our hex with 32 bytes so the total length is 64 digits
    salt = ethers.zeroPadValue(salt, 32);

    predictedAddy = await hookFactory.getPrecomputedHookAddress(
      diamondCutArgs,
      regularArgs,
      salt
    );
    console.log(predictedAddy);
    if (_doesAddressStartWith(predictedAddy, prefix)) {
      console.log("BIG W!!!", salt);
      break;
    }
  }
  return salt;
}

function _doesAddressStartWith(_address, _prefix) {
  //Take the first 4 characters of the address as a string and compare to what we want
  return _address.substring(0, 4) == ethers.toBeHex(_prefix).toString();
}
exports.getSalt = getSalt;
