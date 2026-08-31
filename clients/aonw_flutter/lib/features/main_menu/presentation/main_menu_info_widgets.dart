part of 'main_menu_screen.dart';

final class _WideInfoColumn extends StatelessWidget {
  const _WideInfoColumn({
    required this.serverUpdateRequired,
    required this.onOpenInstructions,
    required this.onOpenCredits,
    required this.onOpenFeedback,
  });

  final bool serverUpdateRequired;
  final VoidCallback onOpenInstructions;
  final VoidCallback onOpenCredits;
  final VoidCallback onOpenFeedback;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      key: const ValueKey('wide-menu-info'),
      constraints: const BoxConstraints(maxWidth: 250),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WhatsNewPanel(serverUpdateRequired: serverUpdateRequired),
          const SizedBox(height: 10),
          _BottomLinks(
            onOpenInstructions: onOpenInstructions,
            onOpenCredits: onOpenCredits,
            onOpenFeedback: onOpenFeedback,
          ),
        ],
      ),
    );
  }
}

final class _WhatsNewPanel extends StatelessWidget {
  const _WhatsNewPanel({required this.serverUpdateRequired});

  final bool serverUpdateRequired;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AonwColorTokens.background.withAlpha(176),
        borderRadius: BorderRadius.circular(AonwRadii.panel),
        border: Border.all(color: AonwColorTokens.brand.withAlpha(70)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WhatsNewHeader(label: l10n.mainMenuWhatsNew),
            const SizedBox(height: 8),
            const AonwGoldDivider(),
            if (serverUpdateRequired)
              _UpdateNoticeSection(message: l10n.serverUpdateSoon),
            const SizedBox(height: 8),
            Text(
              l10n.mainMenuWelcome,
              style: AonwTextStyles.body.copyWith(
                color: AonwColorTokens.brandLight,
                fontSize: 11.5,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _WhatsNewHeader extends StatelessWidget {
  const _WhatsNewHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Transform.rotate(
        angle: 0.785398,
        child: Container(width: 4, height: 4, color: AonwColorTokens.brand),
      ),
      const SizedBox(width: 7),
      Text(label.toUpperCase(), style: AonwTextStyles.sectionHeader),
    ],
  );
}

final class _UpdateNoticeSection extends StatelessWidget {
  const _UpdateNoticeSection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const SizedBox(height: 8),
      _UpdateNotice(message: message),
      const SizedBox(height: 10),
      const AonwGoldDivider(),
    ],
  );
}

final class _UpdateNotice extends StatelessWidget {
  const _UpdateNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.system_update_alt_rounded,
          color: AonwColorTokens.brandLight,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: AonwTextStyles.body.copyWith(
              color: AonwColorTokens.brandLight,
              fontSize: 11.5,
              height: 1.38,
            ),
          ),
        ),
      ],
    ),
  );
}
