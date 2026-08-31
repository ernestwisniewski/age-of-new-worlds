import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';

final class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onFinished, super.key});

  final VoidCallback onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

final class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _stepCount = 4;

  var _step = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final steps = [
      _OnboardingStep(
        icon: Icons.explore_outlined,
        title: l10n.onboardingExploreTitle,
        body: l10n.onboardingExploreBody,
      ),
      _OnboardingStep(
        icon: Icons.shield_outlined,
        title: l10n.onboardingCommandTitle,
        body: l10n.onboardingCommandBody,
      ),
      _OnboardingStep(
        icon: Icons.location_city_outlined,
        title: l10n.onboardingDevelopTitle,
        body: l10n.onboardingDevelopBody,
      ),
      _OnboardingStep(
        icon: Icons.replay_outlined,
        title: l10n.onboardingContinueTitle,
        body: l10n.onboardingContinueBody,
      ),
    ];
    final current = steps[_step];
    final isLast = _step == _stepCount - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.onboardingTitle),
        actions: [
          TextButton(
            key: const ValueKey('skip-onboarding'),
            onPressed: widget.onFinished,
            child: Text(l10n.skipOnboarding),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AonwSpacing.md),
            child: AonwPanel(
              semanticLabel: l10n.onboardingProgress(_step + 1, _stepCount),
              liveRegion: true,
              maxWidth: 600,
              padding: const EdgeInsets.all(AonwSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    label: l10n.onboardingProgress(_step + 1, _stepCount),
                    child: LinearProgressIndicator(
                      value: (_step + 1) / _stepCount,
                    ),
                  ),
                  const SizedBox(height: AonwSpacing.xl),
                  Icon(current.icon, size: 56, semanticLabel: current.title),
                  const SizedBox(height: AonwSpacing.lg),
                  Text(
                    current.title,
                    key: const ValueKey('onboarding-step-title'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AonwSpacing.sm),
                  Text(
                    current.body,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AonwSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey('previous-onboarding-step'),
                          onPressed: _step == 0
                              ? null
                              : () => setState(() => _step -= 1),
                          child: Text(l10n.previousOnboardingStep),
                        ),
                      ),
                      const SizedBox(width: AonwSpacing.sm),
                      Expanded(
                        child: FilledButton(
                          key: ValueKey(
                            isLast
                                ? 'finish-onboarding'
                                : 'next-onboarding-step',
                          ),
                          onPressed: isLast
                              ? widget.onFinished
                              : () => setState(() => _step += 1),
                          child: Text(
                            isLast
                                ? l10n.finishOnboarding
                                : l10n.nextOnboardingStep,
                          ),
                        ),
                      ),
                    ],
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

final class _OnboardingStep {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
