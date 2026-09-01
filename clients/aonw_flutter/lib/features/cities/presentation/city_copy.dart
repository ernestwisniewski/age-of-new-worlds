import 'package:flutter/widgets.dart';

import '../../../l10n/l10n.dart';
import '../application/city_state.dart';

enum CityText {
  title,
  foundingTitle,
  loading,
  owner,
  health,
  population,
  territory,
  foundingSelection,
  foundingConfirm,
  foundingCancel,
  executing,
  cityYield,
  food,
  production,
  gold,
  defense,
  workedHexes,
  workedHexSelect,
  workedHexHint,
  expansion,
  expansionSelect,
  expansionHint,
  managementCancel,
  foundingOpen,
}

final class CityCopy {
  const CityCopy._(this._l10n);

  factory CityCopy.of(BuildContext context) => CityCopy._(context.aonwL10n);

  final AonwLocalizations _l10n;

  String text(CityText key) => _l10n.cityText(key.name);

  String failure(CityFailureView failure) {
    final key = failure.rejectionCode?.name ?? failure.code.name;
    return _l10n.cityFailure(key);
  }
}
