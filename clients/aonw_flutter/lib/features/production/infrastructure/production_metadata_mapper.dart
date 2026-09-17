part of 'production_view_mapper.dart';

void _validateProductionMetadata(AonwProductionOptionsResult wire) {
  if (wire.investedProduction < 0 || wire.productionOverflow < 0) {
    throw const FormatException('Production progress is invalid.');
  }
  final current = _validateProductionCatalog(wire);
  _validateActiveProduction(wire, current);
  _validateRushQuote(wire.rushQuote, current);
}

AonwProductionOption? _validateProductionCatalog(
  AonwProductionOptionsResult wire,
) {
  final targets = <String>{};
  AonwProductionOption? current;
  for (final option in [
    ...wire.buildings,
    for (final unit in wire.units) unit.option,
    ...wire.projects,
    ...wire.wonders,
  ]) {
    final key = _productionTargetKey(option.target);
    if (!targets.add(key)) {
      throw const FormatException('Production target is repeated.');
    }
    final isCurrent =
        wire.currentTarget != null &&
        key == _productionTargetKey(wire.currentTarget!);
    if (isCurrent) current = option;
    _validateAvailability(option);
    _validateForecastValues(option.forecast);
    _validateForecastKind(option);
    _validateSpawnStatus(option, isCurrent: isCurrent);
  }
  return current;
}

void _validateActiveProduction(
  AonwProductionOptionsResult wire,
  AonwProductionOption? current,
) {
  if ((wire.currentTarget != null && current == null) ||
      (current != null &&
          current.forecast.investedProduction != wire.investedProduction) ||
      (wire.currentTarget == null && wire.investedProduction != 0)) {
    throw const FormatException('Active production mismatches its forecast.');
  }
}

String _productionTargetKey(AonwCityProductionTarget target) =>
    '${target.kind.name}:${target.buildingType?.name ?? target.unitType?.name ?? target.projectType?.name ?? target.wonderType?.name}';

void _validateForecastValues(AonwProductionForecast value) {
  if (value.investedProduction < 0 ||
      value.productionPerTurn < 0 ||
      (value.estimatedTurns != null && value.estimatedTurns! < 0) ||
      (value.projectOutput != null && value.projectOutput! < 0)) {
    throw const FormatException('Production forecast has negative values.');
  }
}

void _validateForecastKind(AonwProductionOption option) {
  final value = option.forecast;
  final project = option.target.kind == AonwCityProductionTargetKind.project;
  if (project != (value.projectOutput != null) ||
      (project && (option.cost != 0 || value.estimatedTurns != null)) ||
      (!project && option.cost <= 0)) {
    throw const FormatException('Production forecast mismatches target kind.');
  }
}

void _validateSpawnStatus(
  AonwProductionOption option, {
  required bool isCurrent,
}) {
  final value = option.forecast;
  if (value.spawnBlocked &&
      (!isCurrent ||
          option.target.kind != AonwCityProductionTargetKind.unit ||
          value.investedProduction < option.cost ||
          value.estimatedTurns != null)) {
    throw const FormatException(
      'Blocked production is not a completed active unit.',
    );
  }
}

void _validateRushQuote(
  AonwProductionRushQuote quote,
  AonwProductionOption? current,
) {
  _validateRushAmounts(quote);
  final expected = current == null
      ? AonwCommandRejectionCode.productionQueueEmpty
      : current.target.kind == AonwCityProductionTargetKind.project
      ? AonwCommandRejectionCode.projectCannotBeRushed
      : null;
  _validateRushBlocker(quote, expected);
}

void _validateRushAmounts(AonwProductionRushQuote quote) {
  final blocker = quote.rejection;
  if (quote.production < 0 ||
      quote.goldCost < 0 ||
      (quote.production == 0) != (quote.goldCost == 0) ||
      (blocker == null && quote.production == 0) ||
      !const {
        null,
        AonwCommandRejectionCode.productionQueueEmpty,
        AonwCommandRejectionCode.projectCannotBeRushed,
        AonwCommandRejectionCode.rushProductionUnavailable,
      }.contains(blocker)) {
    throw const FormatException('Production rush quote is invalid.');
  }
}

void _validateRushBlocker(
  AonwProductionRushQuote quote,
  AonwCommandRejectionCode? expected,
) {
  final blocker = quote.rejection;
  if (expected != null && (blocker != expected || quote.production != 0)) {
    throw const FormatException('Production rush quote mismatches its queue.');
  }
  if (expected == null &&
      blocker != null &&
      blocker != AonwCommandRejectionCode.rushProductionUnavailable) {
    throw const FormatException(
      'Finite production has a mismatched rush blocker.',
    );
  }
}

void _validateAvailability(AonwProductionOption option) {
  final value = option.availability;
  final kind = option.target.kind;
  if (option.rejection == null &&
      (!value.technologyUnlocked || value.completedInCity)) {
    throw const FormatException(
      'Production availability contradicts its blocker.',
    );
  }
  if (value.completedInCity &&
      kind != AonwCityProductionTargetKind.building &&
      kind != AonwCityProductionTargetKind.wonder) {
    throw const FormatException(
      'Only buildings and wonders can be completed in a city.',
    );
  }
  if (kind == AonwCityProductionTargetKind.project &&
      (value.requiredTechnology != null || !value.technologyUnlocked)) {
    throw const FormatException('Continuous projects cannot require research.');
  }
}
