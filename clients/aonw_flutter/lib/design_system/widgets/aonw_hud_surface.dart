import 'package:flutter/material.dart';

import '../aonw_tokens.dart';

enum AonwHudElevation { flat, raised, floating, modal }

abstract final class AonwHudSideMenuLayout {
  static const extent = 44.0;
  static const itemGap = 4.0;
  static const separatorHeight = 10.0;

  static double left(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 700;
    return MediaQuery.paddingOf(context).left + (compact ? 8 : 10);
  }

  static double top(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compactPortrait = size.width < 620 && size.height >= size.width;
    return MediaQuery.paddingOf(context).top + (compactPortrait ? 86 : 70);
  }

  static double actionTop(BuildContext context, int index) =>
      top(context) +
      extent +
      itemGap +
      separatorHeight +
      itemGap +
      index * (extent + itemGap);

  static double panelLeft(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return left(context) + extent + (compact ? 8 : 10);
  }
}

final class AonwHudSurface extends StatelessWidget {
  const AonwHudSurface({
    required this.child,
    this.elevation = AonwHudElevation.raised,
    this.accent = AonwColorTokens.brand,
    this.background,
    this.semanticLabel,
    this.liveRegion = false,
    this.maxWidth,
    this.padding = const EdgeInsets.all(AonwSpacing.md),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(AonwRadii.panel),
    ),
    super.key,
  });

  final Widget child;
  final AonwHudElevation elevation;
  final Color accent;
  final Color? background;
  final String? semanticLabel;
  final bool liveRegion;
  final double? maxWidth;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final spec = _HudSurfaceSpec.forElevation(elevation);
    Widget content = Padding(padding: padding, child: child);
    if (maxWidth case final width?) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: content,
      );
    }
    return Semantics(
      container: true,
      label: semanticLabel,
      liveRegion: liveRegion,
      child: Semantics(
        container: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: (background ?? spec.background).withAlpha(
              spec.backgroundAlpha,
            ),
            borderRadius: borderRadius,
            border: Border.all(
              color: spec.borderColor(accent).withAlpha(spec.borderAlpha),
              width: spec.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(spec.shadowAlpha),
                blurRadius: spec.blurRadius,
                offset: spec.shadowOffset,
              ),
              if (elevation == AonwHudElevation.modal)
                BoxShadow(
                  color: accent.withAlpha(spec.glowAlpha),
                  blurRadius: spec.blurRadius,
                ),
            ],
          ),
          child: Material(type: MaterialType.transparency, child: content),
        ),
      ),
    );
  }
}

final class AonwHudIconButton extends StatelessWidget {
  const AonwHudIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.active = false,
    this.onLongPress,
    this.badgeLabel,
    super.key,
  });

  final String tooltip;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool active;
  final VoidCallback? onLongPress;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final foreground = active
        ? AonwColorTokens.brandLight
        : AonwColorTokens.brand;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: active,
        enabled: onPressed != null,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: AonwColorTokens.background.withAlpha(205),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AonwRadii.panel),
            side: BorderSide(
              color: AonwColorTokens.brand.withAlpha(active ? 255 : 92),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox.square(
                dimension: 44,
                child: InkWell(
                  onTap: onPressed,
                  onLongPress: onLongPress,
                  borderRadius: BorderRadius.circular(AonwRadii.panel),
                  child: IconTheme(
                    data: IconThemeData(
                      color: onPressed == null
                          ? AonwColorTokens.textTertiary
                          : foreground,
                      size: 18,
                    ),
                    child: Center(child: icon),
                  ),
                ),
              ),
              if (badgeLabel case final label?)
                Positioned(right: -3, top: -3, child: _HudBadge(label: label)),
            ],
          ),
        ),
      ),
    );
  }
}

final class AonwHudSideMenuSeparator extends StatelessWidget {
  const AonwHudSideMenuSeparator({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: AonwHudSideMenuLayout.extent,
    height: AonwHudSideMenuLayout.separatorHeight,
    child: Center(
      child: ColoredBox(
        color: AonwColorTokens.brand.withAlpha(92),
        child: const SizedBox(width: 22, height: 1),
      ),
    ),
  );
}

final class AonwHudTopFade extends StatelessWidget {
  const AonwHudTopFade({this.height = 96, super.key});

  final double height;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AonwColorTokens.background.withAlpha(232),
              AonwColorTokens.background.withAlpha(126),
              AonwColorTokens.background.withAlpha(0),
            ],
          ),
        ),
      ),
    ),
  );
}

final class AonwHudMapVignette extends StatelessWidget {
  const AonwHudMapVignette({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          radius: 0.92,
          colors: [
            Colors.transparent,
            AonwColorTokens.background.withAlpha(120),
          ],
          stops: const [0.68, 1],
        ),
      ),
    ),
  );
}

final class _HudBadge extends StatelessWidget {
  const _HudBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AonwColorTokens.brand,
      borderRadius: BorderRadius.circular(AonwRadii.pill),
      border: Border.all(color: AonwColorTokens.background, width: 1.2),
    ),
    child: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AonwColorTokens.background,
              fontFamily: AonwTypography.headingFamily,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}

final class _HudSurfaceSpec {
  const _HudSurfaceSpec({
    required this.background,
    required this.backgroundAlpha,
    required this.borderAlpha,
    required this.borderWidth,
    required this.blurRadius,
    required this.shadowAlpha,
    required this.shadowOffset,
    this.glowAlpha = 0,
    this.useLightBorder = false,
  });

  factory _HudSurfaceSpec.forElevation(AonwHudElevation elevation) =>
      switch (elevation) {
        AonwHudElevation.flat => const _HudSurfaceSpec(
          background: AonwColorTokens.surface,
          backgroundAlpha: 210,
          borderAlpha: 60,
          borderWidth: 1,
          blurRadius: 12,
          shadowAlpha: 80,
          shadowOffset: Offset(0, 4),
        ),
        AonwHudElevation.raised => const _HudSurfaceSpec(
          background: AonwColorTokens.surface,
          backgroundAlpha: 230,
          borderAlpha: 160,
          borderWidth: 1,
          blurRadius: 18,
          shadowAlpha: 115,
          shadowOffset: Offset(0, 7),
        ),
        AonwHudElevation.floating => const _HudSurfaceSpec(
          background: AonwColorTokens.background,
          backgroundAlpha: 215,
          borderAlpha: 110,
          borderWidth: 1,
          blurRadius: 10,
          shadowAlpha: 92,
          shadowOffset: Offset(0, 4),
        ),
        AonwHudElevation.modal => const _HudSurfaceSpec(
          background: AonwColorTokens.brand,
          backgroundAlpha: 235,
          borderAlpha: 220,
          borderWidth: 1,
          blurRadius: 20,
          shadowAlpha: 115,
          shadowOffset: Offset(0, 6),
          glowAlpha: 90,
          useLightBorder: true,
        ),
      };

  final Color background;
  final int backgroundAlpha;
  final int borderAlpha;
  final double borderWidth;
  final double blurRadius;
  final int shadowAlpha;
  final Offset shadowOffset;
  final int glowAlpha;
  final bool useLightBorder;

  Color borderColor(Color accent) =>
      useLightBorder ? AonwColorTokens.brandLight : accent;
}
