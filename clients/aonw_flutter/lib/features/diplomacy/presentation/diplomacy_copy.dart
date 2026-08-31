import 'package:flutter/widgets.dart';

import '../../../l10n/l10n.dart';
import '../application/diplomacy_state.dart';
import '../read_model/diplomacy_view.dart';

final class DiplomacyCopy {
  const DiplomacyCopy._(this._l10n);

  factory DiplomacyCopy.of(BuildContext context) =>
      DiplomacyCopy._(context.aonwL10n);

  final AonwLocalizations _l10n;

  String get title => _l10n.diplomacyText('title');
  String get open => _l10n.diplomacyText('open');
  String get close => _l10n.diplomacyText('close');
  String get noContacts => _l10n.diplomacyText('noContacts');
  String get compose => _l10n.diplomacyText('compose');
  String get target => _l10n.diplomacyText('target');
  String get action => _l10n.diplomacyText('action');
  String get send => _l10n.diplomacyText('send');
  String get invalid => _l10n.diplomacyText('invalid');
  String get pending => _l10n.diplomacyText('pending');
  String get relations => _l10n.diplomacyText('relations');
  String get proposals => _l10n.diplomacyText('proposals');
  String get messages => _l10n.diplomacyText('messages');
  String get agreements => _l10n.diplomacyText('agreements');
  String get accept => _l10n.diplomacyText('accept');
  String get reject => _l10n.diplomacyText('reject');
  String get amount => _l10n.diplomacyText('amount');
  String get goldPerTurn => _l10n.diplomacyText('goldPerTurn');
  String get duration => _l10n.diplomacyText('duration');
  String get resource => _l10n.diplomacyText('resource');
  String get offered => _l10n.diplomacyText('offered');
  String get requested => _l10n.diplomacyText('requested');
  String get topic => _l10n.diplomacyText('topic');

  String name(Enum value) => switch (value) {
    DiplomaticProposalKindView() => _l10n.diplomaticProposalName(value.name),
    _ => _l10n.presentationName(value.name),
  };

  String failure(DiplomacyFailureView failure) {
    final key = failure.rejectionCode?.name ?? failure.code.name;
    return _l10n.diplomacyFailure(key);
  }
}
