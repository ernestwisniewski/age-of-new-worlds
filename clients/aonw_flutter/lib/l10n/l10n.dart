import 'package:flutter/widgets.dart';

import 'generated/aonw_localizations.dart';

export 'generated/aonw_localizations.dart';

extension AonwLocalizationsBuildContext on BuildContext {
  AonwLocalizations get aonwL10n => AonwLocalizations.of(this);
}
