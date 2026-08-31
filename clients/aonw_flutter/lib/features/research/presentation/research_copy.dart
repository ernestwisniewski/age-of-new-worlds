import 'package:flutter/widgets.dart';

import '../../../l10n/l10n.dart';
import '../application/research_state.dart';
import '../read_model/research_view.dart';

enum ResearchText {
  title,
  open,
  close,
  loading,
  retry,
  selecting,
  selectionRequired,
  sciencePerTurn,
  overflow,
  active,
  none,
  cost,
  progress,
  boost,
  prerequisites,
  blockedBy,
  unlocks,
  choose,
}

final class ResearchCopy {
  const ResearchCopy._(this._l10n);

  factory ResearchCopy.of(BuildContext context) =>
      ResearchCopy._(context.aonwL10n);

  final AonwLocalizations _l10n;

  String text(ResearchText key) => _l10n.researchText(key.name);

  String technology(TechnologyIdView value) => _l10n.technologyName(value.name);

  String availability(TechnologyAvailabilityView value) =>
      _l10n.researchAvailability(value.name);

  String unlock(TechnologyUnlockView value) => _l10n.researchUnlock(
    _l10n.presentationName(value.kind.name),
    switch (value.kind) {
      TechnologyUnlockKindView.building ||
      TechnologyUnlockKindView.wonder => _l10n.cityContentName(value.target),
      TechnologyUnlockKindView.improvement ||
      TechnologyUnlockKindView.resourceVisibility ||
      TechnologyUnlockKindView.unit => _l10n.presentationName(value.target),
    },
  );

  String failure(ResearchFailureView failure) {
    final key = failure.rejectionCode?.name ?? failure.code.name;
    return _l10n.researchFailure(key);
  }
}
