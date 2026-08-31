import 'package:aonw_engine_client/aonw_engine_client.dart';

final class RecipientResearchValidator {
  const RecipientResearchValidator();

  void validate(
    AonwPlayerResearchView research,
    List<AonwPlayerCityView> cities,
  ) {
    _validateActiveResearch(research);
    final ownedCityIds = _ownedCityIds(cities);
    final byCity = research.scienceYield.byCityId;
    final cityTotal = _validateScienceByCity(byCity, ownedCityIds);
    final sourceByCity = _scienceBySource(research, ownedCityIds);
    if (cityTotal != research.scienceYield.total ||
        !_sameAmounts(byCity, sourceByCity)) {
      throw const FormatException(
        'Recipient science totals do not match their sources.',
      );
    }
  }
}

void _validateActiveResearch(AonwPlayerResearchView research) {
  final activeFields = [
    research.activeTechnology,
    research.activeProgress,
    research.activeEffectiveCost,
  ];
  final activeCount = activeFields.where((value) => value != null).length;
  if (activeCount != 0 && activeCount != activeFields.length) {
    throw const FormatException(
      'Recipient active research fields are inconsistent.',
    );
  }
  if ((research.activeProgress ?? 0) < 0 ||
      (research.activeEffectiveCost ?? 1) <= 0 ||
      research.scienceOverflow < 0 ||
      research.scienceYield.total < 0) {
    throw const FormatException('Recipient research amount is invalid.');
  }
}

Set<String> _ownedCityIds(List<AonwPlayerCityView> cities) => {
  for (final city in cities)
    if (city.ownedDetails != null) city.id,
};

int _validateScienceByCity(Map<String, int> byCity, Set<String> ownedCityIds) {
  String? previousCityId;
  var total = 0;
  for (final entry in byCity.entries) {
    if (entry.key.isEmpty ||
        !ownedCityIds.contains(entry.key) ||
        entry.value <= 0 ||
        (previousCityId != null && previousCityId.compareTo(entry.key) >= 0)) {
      throw const FormatException(
        'Recipient science by-city breakdown is invalid.',
      );
    }
    previousCityId = entry.key;
    total += entry.value;
  }
  return total;
}

Map<String, int> _scienceBySource(
  AonwPlayerResearchView research,
  Set<String> ownedCityIds,
) {
  final byCity = <String, int>{};
  for (final source in research.scienceYield.sources) {
    if (source.cityId.isEmpty ||
        !ownedCityIds.contains(source.cityId) ||
        source.amount <= 0) {
      throw const FormatException('Recipient science source is invalid.');
    }
    byCity.update(
      source.cityId,
      (amount) => amount + source.amount,
      ifAbsent: () => source.amount,
    );
  }
  return byCity;
}

bool _sameAmounts(Map<String, int> left, Map<String, int> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) return false;
  }
  return true;
}
