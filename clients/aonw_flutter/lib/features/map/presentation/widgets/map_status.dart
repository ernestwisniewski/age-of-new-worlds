import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../design_system/widgets/aonw_panel.dart';
import '../../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../../../l10n/l10n.dart';
import '../../application/game_session_state.dart';
import 'map_failure_messages.dart';

final class LoadingMap extends StatelessWidget {
  const LoadingMap({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: AonwProgressIndicator(semanticLabel: context.aonwL10n.loadingMap),
  );
}

final class MapFailure extends StatelessWidget {
  const MapFailure({required this.code, required this.retry, super.key});

  final MapLoadFailureViewCode code;
  final AsyncCallback retry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Center(
      child: AonwMessagePanel(
        semanticLabel: l10n.mapLoadingFailed,
        title: l10n.mapUnavailable,
        message: mapFailureMessage(l10n, code),
        actionLabel: l10n.retry,
        onAction: retry,
      ),
    );
  }
}
