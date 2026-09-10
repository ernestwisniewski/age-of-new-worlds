part of 'research_tree.dart';

final class _ResearchTreeEdges extends CustomPainter {
  const _ResearchTreeEdges({
    required this.options,
    required this.bounds,
    required this.color,
  });

  final List<ResearchOptionView> options;
  final Map<TechnologyIdView, Rect> bounds;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final option in options) {
      final end = bounds[option.technology]!.centerLeft;
      for (final parent in option.prerequisites) {
        final start = bounds[parent]!.centerRight;
        final middle = (start.dx + end.dx) / 2;
        final path = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(middle, start.dy, middle, end.dy, end.dx, end.dy)
          ..moveTo(end.dx - 7, end.dy - 5)
          ..lineTo(end.dx, end.dy)
          ..lineTo(end.dx - 7, end.dy + 5);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ResearchTreeEdges oldDelegate) =>
      oldDelegate.color != color ||
      !identical(oldDelegate.options, options) ||
      !_sameBounds(oldDelegate.bounds, bounds);
}

bool _sameBounds(
  Map<TechnologyIdView, Rect> left,
  Map<TechnologyIdView, Rect> right,
) =>
    left.length == right.length &&
    left.entries.every((entry) => right[entry.key] == entry.value);
