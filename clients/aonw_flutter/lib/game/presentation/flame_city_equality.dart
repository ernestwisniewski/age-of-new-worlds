import '../../features/cities/read_model/city_view.dart';

bool sameFlameCity(CityView? left, CityView right) {
  if (left == null) return false;
  return left.id == right.id &&
      left.ownerPlayerId == right.ownerPlayerId &&
      left.name == right.name &&
      left.center == right.center &&
      left.hitPoints == right.hitPoints &&
      _sameList(left.visibleControlledHexes, right.visibleControlledHexes) &&
      _sameOwnedDetails(left.ownedDetails, right.ownedDetails);
}

bool _sameOwnedDetails(
  OwnedCityDetailsView? left,
  OwnedCityDetailsView? right,
) {
  if (left == null || right == null) return left == right;
  return _sameOwnedScalars(left, right) && _sameOwnedCollections(left, right);
}

bool _sameOwnedScalars(OwnedCityDetailsView left, OwnedCityDetailsView right) =>
    left.population == right.population &&
    left.storedFood == right.storedFood &&
    left.maxHexes == right.maxHexes &&
    left.territoryRadius == right.territoryRadius &&
    left.preferredExpansionHex == right.preferredExpansionHex &&
    left.productionOverflow == right.productionOverflow &&
    left.specialization == right.specialization;

bool _sameOwnedCollections(
  OwnedCityDetailsView left,
  OwnedCityDetailsView right,
) =>
    _sameList(left.workedHexes, right.workedHexes) &&
    _sameList(left.buildings, right.buildings) &&
    _sameList(left.wonders, right.wonders) &&
    _sameProductionQueue(left.productionQueue, right.productionQueue);

bool _sameProductionQueue(
  CityProductionQueueView? left,
  CityProductionQueueView? right,
) {
  if (left == null || right == null) return left == right;
  return left.targetKind == right.targetKind &&
      left.target == right.target &&
      left.investedProduction == right.investedProduction &&
      _sameEntries(left.resourceAllocation, right.resourceAllocation);
}

bool _sameList<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _sameEntries<K, V>(Map<K, V> left, Map<K, V> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
