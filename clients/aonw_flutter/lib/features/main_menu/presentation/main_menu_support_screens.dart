import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/platform/app_platform_actions.dart';
import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_menu_backdrop.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';

final class CreditsScreen extends StatelessWidget {
  const CreditsScreen({required this.openExternalUri, super.key});

  static final _devlogUri = Uri.parse('https://ernest.dev');

  final ExternalUriOpen? openExternalUri;

  @override
  Widget build(BuildContext context) => _SupportScreen(
    title: context.aonwL10n.creditsTitle,
    icon: Icons.star_border,
    body: context.aonwL10n.creditsCreatedBy('Ernest'),
    actionLabel: context.aonwL10n.devlogLinkLabel,
    actionKey: const ValueKey('open-devlog'),
    onAction: openExternalUri == null
        ? null
        : () => unawaited(openExternalUri!(_devlogUri)),
  );
}

final class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({required this.openExternalUri, super.key});

  static final _feedbackUri = Uri.parse('https://www.reddit.com/r/aonw/');

  final ExternalUriOpen? openExternalUri;

  @override
  Widget build(BuildContext context) => _SupportScreen(
    title: context.aonwL10n.feedbackTitle,
    icon: Icons.chat_bubble_outline,
    body: context.aonwL10n.feedbackDescription,
    actionLabel: context.aonwL10n.openFeedback,
    actionKey: const ValueKey('open-feedback-link'),
    onAction: openExternalUri == null
        ? null
        : () => unawaited(openExternalUri!(_feedbackUri)),
  );
}

final class _SupportScreen extends StatelessWidget {
  const _SupportScreen({
    required this.title,
    required this.icon,
    required this.body,
    required this.actionLabel,
    required this.actionKey,
    required this.onAction,
  });

  final String title;
  final IconData icon;
  final String body;
  final String actionLabel;
  final Key actionKey;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: AonwMenuBackdrop(
      child: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AonwSpacing.lg),
            child: AonwPanel(
              semanticLabel: title,
              maxWidth: 520,
              padding: const EdgeInsets.all(AonwSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 42, color: AonwColorTokens.brandLight),
                  const SizedBox(height: AonwSpacing.lg),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AonwSpacing.md),
                  Text(body, textAlign: TextAlign.center),
                  const SizedBox(height: AonwSpacing.xl),
                  Tooltip(
                    message: onAction == null
                        ? context.aonwL10n.externalLinkUnavailable
                        : '',
                    child: FilledButton.icon(
                      key: actionKey,
                      onPressed: onAction,
                      icon: const Icon(Icons.open_in_new),
                      label: Text(actionLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
