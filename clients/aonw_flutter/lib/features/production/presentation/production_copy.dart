import 'package:flutter/widgets.dart';

import '../../../l10n/l10n.dart';
import '../../map/read_model/map_view.dart';
import '../application/production_state.dart';
import '../read_model/production_view.dart';

enum ProductionText {
  title,
  loading,
  executing,
  current,
  invested,
  overflow,
  resources,
  buildings,
  units,
  projects,
  wonders,
  specializations,
  rush,
  cost,
  requires,
  empty,
  choose,
  ready,
  spawnBlocked,
  noEstimate,
  continuous,
}

final class ProductionCopy {
  const ProductionCopy._(this._l10n);

  factory ProductionCopy.of(BuildContext context) =>
      ProductionCopy._(context.aonwL10n);

  final AonwLocalizations _l10n;

  String text(ProductionText key) => _l10n.productionText(key.name);

  String failure(ProductionFailureView failure) =>
      rejection(failure.rejectionCode) ??
      _l10n.productionFailure(failure.code.name);

  String? rejection(ProductionRejectionCodeView? value) =>
      value == null ? null : _l10n.productionFailure(value.name);

  String resource(MapResource value) => _l10n.presentationName(value.name);

  String cityContent(String value) => _l10n.cityContentName(value);

  String progress(int invested, int cost) =>
      _l10n.productionProgress(invested, cost);

  String rate(int amount) => _l10n.productionRate(amount);

  String rush(int production, int gold) =>
      _l10n.productionRushPrice(production, gold);

  String treasury(int gold) => _l10n.productionTreasury(gold);

  String estimate(ProductionForecastView value) {
    if (value.spawnBlocked) return text(ProductionText.spawnBlocked);
    if (value.projectOutput != null) return text(ProductionText.continuous);
    return switch (value.estimatedTurns) {
      null => text(ProductionText.noEstimate),
      0 => text(ProductionText.ready),
      final turns => _l10n.productionTurns(turns),
    };
  }

  String output(ProjectProductionTargetView target, int amount) =>
      target.project == 'wealth'
      ? _l10n.productionGoldOutput(amount)
      : _l10n.productionScienceOutput(amount);

  String target(ProductionTargetView value) => switch (value) {
    BuildingProductionTargetView(:final building) => cityContent(building),
    UnitProductionTargetView(:final unit) => _l10n.presentationName(unit.name),
    ProjectProductionTargetView(:final project) => cityContent(project),
    WonderProductionTargetView(:final wonder) => cityContent(wonder),
  };
}
