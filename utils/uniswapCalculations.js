const Big = require("big.js");
Big.RM = 0;
const two = new Big(2);
const power = new Big(192);
const Q192 = two.pow(192);

function calculateSqrtPriceX96(price, decimalT0, decimalsT1) {
  price = new Big(price);
  const decimalAdj = new Big(10).pow(
    decimalsT1 - decimalT0 == 0 ? 0 : decimalT0 - decimalsT1
  );
  console.log(decimalAdj.toFixed());
  price = price.times(decimalAdj);

  ratioX96 = price.times(Q192);
  sqrtPriceX96 = ratioX96.sqrt().round();
  return sqrtPriceX96;
}
function getNearestUsableTick(currentTick, space) {
  // 0 is always a valid tick
  if (currentTick == 0) {
    return 0;
  }
  // Determines direction
  direction = currentTick >= 0 ? 1 : -1;
  // Changes direction
  currentTick *= direction;
  // Calculates nearest tick based on how close the current tick remainder is to space / 2
  nearestTick =
    currentTick % space <= space / 2
      ? currentTick - (currentTick % space)
      : currentTick + (space - (currentTick % space));
  // Changes direction back
  nearestTick *= direction;

  return nearestTick;
}
exports.calculateSqrtPriceX96 = calculateSqrtPriceX96;
exports.getNearestUsableTick = getNearestUsableTick;
