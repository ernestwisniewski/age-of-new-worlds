void validateRouteRoadIndices(List<int> indices, int stepCount) {
  var previous = 0;
  for (final index in indices) {
    if (index <= previous || index >= stepCount) {
      throw const FormatException('Route road indices are inconsistent.');
    }
    previous = index;
  }
}

void validateStoredRouteTurns(List<int> turns, int stepCount, int current) {
  if (turns.length != stepCount || current < 0 || turns[current] != 1) {
    throw const FormatException('Stored route turns are inconsistent.');
  }
  for (var index = 0; index < current; index++) {
    if (turns[index] != 0) {
      throw const FormatException('Traversed route steps must have turn zero.');
    }
  }
  for (var index = current + 1; index < turns.length; index++) {
    if (turns[index] < turns[index - 1] ||
        turns[index] > turns[index - 1] + 1) {
      throw const FormatException('Stored route turns must be consecutive.');
    }
  }
}
