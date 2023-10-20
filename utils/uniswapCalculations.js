const Big = require("big.js");
Big.RM = 0;
const two = new Big(2);
const power = new Big(192);
const Q192 = two.pow(192);

function calculateSqrtPriceX96(price, decimalT0, decimalsT1) {
  price = new Big(price);
  price = price.times(
    new Big(decimalsT1 - decimalT0 === 0 ? 1 : decimalsT1 - decimalT0)
  );

  ratioX96 = price.times(Q192);
  sqrtPriceX96 = ratioX96.sqrt().round();
  return sqrtPriceX96;
}
exports.calculateSqrtPriceX96 = calculateSqrtPriceX96;
