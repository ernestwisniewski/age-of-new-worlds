part of 'research_tree.dart';

double _nodeHeight(
  BuildContext context,
  List<ResearchOptionView> options,
  double width,
) {
  final copy = ResearchCopy.of(context);
  final theme = Theme.of(context).textTheme;
  final scaler = MediaQuery.textScalerOf(context);
  var height = 120.0;
  for (final option in options) {
    var measured = 40.0;
    for (final (text, style) in [
      (copy.technology(option.technology), theme.titleMedium),
      (copy.availability(option.availability), theme.bodySmall),
      (
        '${copy.text(ResearchText.progress)}: '
            '${option.progress} / ${option.effectiveCost}',
        theme.bodySmall,
      ),
    ]) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: scaler,
      )..layout(maxWidth: width - 28);
      measured += painter.height;
      painter.dispose();
    }
    height = math.max(height, measured);
  }
  return height.ceilToDouble();
}
