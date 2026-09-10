import '../read_model/research_view.dart';

/// Assigns screen columns from projected dependency edges, never availability
/// or research rules. Malformed graphs fall back to the accessible catalog.
final class ResearchTreeLayout {
  ResearchTreeLayout._(List<List<ResearchOptionView>> columns)
    : columns = List.unmodifiable(
        columns.map((column) => List<ResearchOptionView>.unmodifiable(column)),
      );

  final List<List<ResearchOptionView>> columns;

  static ResearchTreeLayout? fromOptions(List<ResearchOptionView> options) {
    final byId = {for (final option in options) option.technology: option};
    if (byId.length != options.length) return null;
    final depths = <TechnologyIdView, int>{};
    final visiting = <TechnologyIdView>{};
    for (final option in options) {
      if (_depth(option.technology, byId, depths, visiting) == null) {
        return null;
      }
    }
    final columns = <List<ResearchOptionView>>[];
    for (final option in options) {
      final depth = depths[option.technology]!;
      while (columns.length <= depth) {
        columns.add([]);
      }
      columns[depth].add(option);
    }
    return ResearchTreeLayout._(columns);
  }
}

int? _depth(
  TechnologyIdView id,
  Map<TechnologyIdView, ResearchOptionView> options,
  Map<TechnologyIdView, int> depths,
  Set<TechnologyIdView> visiting,
) {
  if (depths.containsKey(id)) return depths[id];
  final option = options[id];
  if (option == null || !visiting.add(id)) return null;
  var depth = 0;
  for (final parent in option.prerequisites) {
    final parentDepth = _depth(parent, options, depths, visiting);
    if (parentDepth == null) return null;
    if (depth <= parentDepth) depth = parentDepth + 1;
  }
  visiting.remove(id);
  depths[id] = depth;
  return depth;
}
