import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';

final class HelpScreen extends StatelessWidget {
  const HelpScreen({required this.onStartOnboarding, super.key});

  final VoidCallback onStartOnboarding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AonwSpacing.md),
          child: Center(
            child: AonwPanel(
              semanticLabel: l10n.helpTitle,
              maxWidth: 720,
              padding: const EdgeInsets.all(AonwSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.helpIntroduction,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AonwSpacing.xl),
                  _HelpSection(
                    icon: Icons.flag_outlined,
                    title: l10n.helpObjectiveTitle,
                    body: l10n.helpObjectiveBody,
                  ),
                  _HelpSection(
                    icon: Icons.map_outlined,
                    title: l10n.helpMapTitle,
                    body: l10n.helpMapBody,
                  ),
                  _HelpSection(
                    icon: Icons.account_tree_outlined,
                    title: l10n.helpDevelopmentTitle,
                    body: l10n.helpDevelopmentBody,
                  ),
                  _HelpSection(
                    icon: Icons.smart_toy_outlined,
                    title: l10n.helpTurnTitle,
                    body: l10n.helpTurnBody,
                  ),
                  _HelpSection(
                    icon: Icons.save_outlined,
                    title: l10n.helpSaveReplayTitle,
                    body: l10n.helpSaveReplayBody,
                  ),
                  const SizedBox(height: AonwSpacing.sm),
                  FilledButton.icon(
                    key: const ValueKey('start-onboarding'),
                    onPressed: onStartOnboarding,
                    icon: const Icon(Icons.school_outlined),
                    label: Text(l10n.startOnboarding),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AonwSpacing.lg),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, semanticLabel: title),
        const SizedBox(width: AonwSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AonwSpacing.xs),
              Text(body),
            ],
          ),
        ),
      ],
    ),
  );
}
