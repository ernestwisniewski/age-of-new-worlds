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

  String target(ProductionTargetView value) => switch (value) {
    BuildingProductionTargetView(:final building) => cityContent(building),
    UnitProductionTargetView(:final unit) => _l10n.presentationName(unit.name),
    ProjectProductionTargetView(:final project) => cityContent(project),
    WonderProductionTargetView(:final wonder) => cityContent(wonder),
  };
}
