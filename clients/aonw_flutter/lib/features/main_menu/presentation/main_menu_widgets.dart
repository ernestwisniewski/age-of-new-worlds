part of 'main_menu_screen.dart';

final class _MenuBackgroundOverlay extends StatelessWidget {
  const _MenuBackgroundOverlay();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AonwColorTokens.background,
              Color(0xA80A0E14),
              Color(0x1F0A0E14),
              Color(0x000A0E14),
            ],
            stops: [0, 0.28, 0.48, 1],
          ),
        ),
      ),
      DecoratedBox(
        decoration: BoxDecoration(
          color: AonwColorTokens.background.withAlpha(34),
        ),
      ),
    ],
  );
}

final class _MenuLogo extends StatelessWidget {
  const _MenuLogo();

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Image.asset(
      key: const ValueKey('main-menu-logo'),
      aonwLogoAsset,
      width: 192,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    ),
  );
}

final class _MenuSynopsis extends StatelessWidget {
  const _MenuSynopsis({
    required this.compact,
    required this.serverUpdateRequired,
    required this.visible,
  });

  final bool compact;
  final bool serverUpdateRequired;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    final l10n = context.aonwL10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AonwColorTokens.background.withAlpha(118),
        borderRadius: BorderRadius.circular(AonwRadii.panel),
        border: Border.all(color: AonwColorTokens.brand.withAlpha(82)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.mainMenuSynopsisTitle.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AonwTextStyles.toolbarLabel.copyWith(
                color: serverUpdateRequired
                    ? AonwColorTokens.brand
                    : AonwColorTokens.brandLight,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              serverUpdateRequired
                  ? l10n.serverUpdateSoon
                  : l10n.mainMenuWelcome,
              maxLines: compact && !serverUpdateRequired ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: AonwTextStyles.bodySmall.copyWith(
                color: AonwColorTokens.textPrimary,
                height: 1.32,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _MenuButton extends StatefulWidget {
  const _MenuButton({required this.item});

  final _MenuItem item;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

final class _MenuButtonState extends State<_MenuButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final enabled = item.onPressed != null;
    final highlighted = enabled && (_focused || _hovered || item.primary);
    final button = _MenuButtonFrame(
      item: item,
      enabled: enabled,
      highlighted: highlighted,
      stronglyHighlighted: _hovered || _focused,
      onHover: _setHovered,
      onFocusChange: _setFocused,
    );
    if (!enabled && item.disabledMessage != null) {
      return Tooltip(message: item.disabledMessage!, child: button);
    }
    return button;
  }

  void _setHovered(bool value) => setState(() => _hovered = value);

  void _setFocused(bool value) => setState(() => _focused = value);
}

final class _MenuButtonFrame extends StatelessWidget {
  const _MenuButtonFrame({
    required this.item,
    required this.enabled,
    required this.highlighted,
    required this.stronglyHighlighted,
    required this.onHover,
    required this.onFocusChange,
  });

  final _MenuItem item;
  final bool enabled;
  final bool highlighted;
  final bool stronglyHighlighted;
  final ValueChanged<bool> onHover;
  final ValueChanged<bool> onFocusChange;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: enabled,
    label: item.label,
    child: AnimatedContainer(
      key: item.key,
      duration: const Duration(milliseconds: 140),
      height: _buttonHeight(context),
      decoration: _decoration(),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: item.onPressed,
          onHover: onHover,
          onFocusChange: onFocusChange,
          canRequestFocus: enabled,
          borderRadius: BorderRadius.circular(AonwRadii.panel),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _MenuButtonContent(
              item: item,
              highlighted: highlighted,
              enabled: enabled,
            ),
          ),
        ),
      ),
    ),
  );

  double _buttonHeight(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.3);
    return 50 + ((textScale - 1) * 18);
  }

  BoxDecoration _decoration() => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        highlighted
            ? AonwColorTokens.chipSurfaceDim
            : AonwColorTokens.chipSurface,
        AonwColorTokens.surface.withAlpha(226),
      ],
    ),
    borderRadius: BorderRadius.circular(AonwRadii.panel),
    border: Border.all(
      color: highlighted
          ? AonwColorTokens.brand
          : AonwColorTokens.brand.withAlpha(110),
      width: highlighted ? 1.3 : 1,
    ),
    boxShadow: [
      if (highlighted)
        BoxShadow(
          color: AonwColorTokens.brand.withAlpha(stronglyHighlighted ? 70 : 42),
          blurRadius: stronglyHighlighted ? 16 : 9,
          offset: const Offset(0, 2),
        ),
    ],
  );
}

final class _MenuButtonContent extends StatelessWidget {
  const _MenuButtonContent({
    required this.item,
    required this.highlighted,
    required this.enabled,
  });

  final _MenuItem item;
  final bool highlighted;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final emphasis = enabled ? 1.0 : 0.46;
    return Opacity(
      opacity: emphasis,
      child: Row(
        children: [
          _MenuButtonIcon(icon: item.icon, highlighted: highlighted),
          const SizedBox(width: 13),
          Expanded(
            child: _MenuButtonLabels(item: item, highlighted: highlighted),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AonwColorTokens.brand.withAlpha(highlighted ? 220 : 110),
          ),
        ],
      ),
    );
  }
}

final class _MenuButtonIcon extends StatelessWidget {
  const _MenuButtonIcon({required this.icon, required this.highlighted});

  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 140),
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      color: AonwColorTokens.background.withAlpha(highlighted ? 132 : 88),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: AonwColorTokens.brand.withAlpha(highlighted ? 138 : 74),
      ),
    ),
    child: Icon(
      icon,
      size: 20,
      color: highlighted ? AonwColorTokens.brand : AonwColorTokens.brandDark,
    ),
  );
}

final class _MenuButtonLabels extends StatelessWidget {
  const _MenuButtonLabels({required this.item, required this.highlighted});

  final _MenuItem item;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        item.label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AonwTextStyles.menuButton.copyWith(
          color: highlighted
              ? AonwColorTokens.brandLight
              : AonwColorTokens.textPrimary,
        ),
      ),
      if (item.sublabel case final sublabel?)
        Text(
          sublabel.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AonwTextStyles.chipLabel.copyWith(
            color: AonwColorTokens.textTertiary,
            fontSize: 9,
          ),
        ),
    ],
  );
}

final class _BottomLinks extends StatelessWidget {
  const _BottomLinks({
    required this.onOpenInstructions,
    required this.onOpenCredits,
    required this.onOpenFeedback,
  });

  final VoidCallback onOpenInstructions;
  final VoidCallback onOpenCredits;
  final VoidCallback onOpenFeedback;

  @override
  Widget build(BuildContext context) {
    final links = _linksFor(context);
    return DecoratedBox(
      key: const ValueKey('menu-bottom-links'),
      decoration: BoxDecoration(
        color: AonwColorTokens.background.withAlpha(224),
        borderRadius: BorderRadius.circular(AonwRadii.panel),
        border: Border.all(color: AonwColorTokens.brand.withAlpha(70)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            for (final link in links)
              Expanded(child: _BottomLinkButton(link: link)),
          ],
        ),
      ),
    );
  }

  List<_BottomLink> _linksFor(BuildContext context) {
    final l10n = context.aonwL10n;
    return [
      _BottomLink(
        key: const ValueKey('menu-help'),
        icon: Icons.menu_book_outlined,
        label: l10n.instructions,
        onPressed: onOpenInstructions,
      ),
      _BottomLink(
        key: const ValueKey('menu-credits'),
        icon: Icons.star_border,
        label: l10n.creditsTitle,
        onPressed: onOpenCredits,
      ),
      _BottomLink(
        key: const ValueKey('menu-feedback'),
        icon: Icons.chat_bubble_outline,
        label: l10n.feedbackTitle,
        onPressed: onOpenFeedback,
      ),
    ];
  }
}

final class _BottomLinkButton extends StatelessWidget {
  const _BottomLinkButton({required this.link});

  final _BottomLink link;

  @override
  Widget build(BuildContext context) => TextButton(
    key: link.key,
    onPressed: link.onPressed,
    style: TextButton.styleFrom(
      foregroundColor: AonwColorTokens.textSecondary,
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 42),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AonwRadii.panel),
      ),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(link.icon, size: 18),
        const SizedBox(height: 3),
        Text(
          link.label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AonwTextStyles.toolbarLabel.copyWith(
            color: AonwColorTokens.textTertiary,
          ),
        ),
      ],
    ),
  );
}

final class _BottomLink {
  const _BottomLink({
    required this.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Key key;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}
