import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../map/presentation/input/map_gamepad_navigation.dart';
import '../../map/presentation/widgets/map_gamepad_region.dart';
import '../read_model/research_view.dart';
import 'research_copy.dart';
import 'research_tree.dart';

/// Navigation inside a recipient's research projection. Selecting a graph node
/// only opens details; the supplied detail widget owns the command callback.
final class ResearchBrowser extends StatefulWidget {
  const ResearchBrowser({
    required this.options,
    required this.catalog,
    required this.details,
    super.key,
  });

  final List<ResearchOptionView> options;
  final Widget catalog;
  final Widget Function(ResearchOptionView) details;

  @override
  State<ResearchBrowser> createState() => _ResearchBrowserState();
}

final class _ResearchBrowserState extends State<ResearchBrowser> {
  var _tree = false;
  TechnologyIdView? _selected;

  void _back() => setState(() {
    if (_selected != null) {
      _selected = null;
    } else {
      _tree = false;
    }
  });

  @override
  Widget build(BuildContext context) {
    final copy = ResearchCopy.of(context);
    final selected = widget.options
        .where((option) => option.technology == _selected)
        .firstOrNull;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            key: const ValueKey('research-view-mode'),
            onPressed: _tree ? _back : () => setState(() => _tree = true),
            icon: Icon(_tree ? Icons.arrow_back : Icons.account_tree_outlined),
            label: Text(copy.text(_modeLabel(selected))),
          ),
        ),
        Expanded(child: _body(copy, selected)),
      ],
    );
    if (!_tree) return content;
    return MapGamepadRegion(
      section: MapHudSection.globalActions,
      priority: MapGamepadPriority.popup,
      onCancel: _back,
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): _back},
        child: Focus(autofocus: true, skipTraversal: true, child: content),
      ),
    );
  }

  ResearchText _modeLabel(ResearchOptionView? selected) {
    if (selected != null) return ResearchText.backToTree;
    return _tree ? ResearchText.catalog : ResearchText.tree;
  }

  Widget _body(ResearchCopy copy, ResearchOptionView? selected) {
    if (!_tree) return widget.catalog;
    final tree = ResearchTree(
      options: widget.options,
      fallback: Column(
        children: [
          Text(copy.text(ResearchText.treeUnavailable)),
          Expanded(child: widget.catalog),
        ],
      ),
      onInspect: (technology) => setState(() => _selected = technology),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        Visibility(visible: selected == null, maintainState: true, child: tree),
        if (selected != null)
          SingleChildScrollView(
            key: ValueKey(('research-tree-details', selected.technology)),
            child: widget.details(selected),
          ),
      ],
    );
  }
}
