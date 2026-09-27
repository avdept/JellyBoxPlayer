enum PlayerTimeDisplay {
  remaining,
  elapsed,
  elapsedAndTotal;

  PlayerTimeDisplay get next => values[(index + 1) % values.length];
}
