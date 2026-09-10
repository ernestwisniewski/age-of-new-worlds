import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';
import '../../local_game/application/local_game_catalog.dart';
import '../application/match_history_port.dart';
import 'match_history_controller.dart';

part 'match_history_card.dart';

final class MatchHistorySection extends StatefulWidget {
  const MatchHistorySection({
    required this.port,
    required this.userId,
    this.onReplay,
    this.replayBusy = false,
    this.replayingMatchId,
    super.key,
  });

  final MatchHistoryPort port;
  final String userId;
  final Future<void> Function(MatchHistoryEntryView)? onReplay;
  final bool replayBusy;
  final String? replayingMatchId;

  @override
  State<MatchHistorySection> createState() => _MatchHistorySectionState();
}

final class _MatchHistorySectionState extends State<MatchHistorySection> {
  late MatchHistoryController _controller;
  var _expanded = false;

  @override
  void initState() {
    super.initState();
    _createController();
  }

  void _createController() {
    _controller = MatchHistoryController(widget.port, userId: widget.userId);
  }

  @override
  void didUpdateWidget(MatchHistorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.port != widget.port || oldWidget.userId != widget.userId) {
      _controller.dispose();
      _createController();
      if (_expanded) unawaited(_controller.refresh());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExpansionTile(
    key: const ValueKey('match-history-section'),
    title: Text(context.aonwL10n.historyText('title')),
    onExpansionChanged: (expanded) {
      _expanded = expanded;
      if (expanded && _controller.page == null) {
        unawaited(_controller.refresh());
      }
    },
    children: [
      ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _body(context),
      ),
    ],
  );

  Future<void> _navigate(Future<void> Function() action) async {
    final controller = _controller;
    await action();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && identical(controller, _controller)) {
        unawaited(Scrollable.ensureVisible(context));
      }
    });
  }

  Widget _card(MatchHistoryEntryView entry) => _MatchHistoryCard(
    entry: entry,
    onReplay: widget.onReplay == null || widget.replayBusy || _controller.busy
        ? null
        : () => widget.onReplay!(entry),
    replaying: widget.replayingMatchId == entry.match.matchId,
  );

  Widget _body(BuildContext context) {
    final copy = context.aonwL10n;
    final entries = _controller.page?.entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_controller.busy)
          LinearProgressIndicator(semanticsLabel: copy.historyText('loading')),
        if (entries?.isEmpty == true) Text(copy.historyText('empty')),
        if (_controller.failureCode != null)
          Text(
            copy.historyText('failed'),
            key: const ValueKey('history-error'),
          ),
        for (final entry in entries ?? const <MatchHistoryEntryView>[])
          _card(entry),
        Wrap(
          spacing: 8,
          children: [
            TextButton(
              onPressed: _controller.busy
                  ? null
                  : () => _navigate(_controller.refresh),
              child: Text(copy.historyText('refresh')),
            ),
            TextButton(
              key: const ValueKey('history-previous'),
              onPressed: _controller.busy || !_controller.hasPrevious
                  ? null
                  : () => _navigate(_controller.previous),
              child: Text(copy.historyText('previous')),
            ),
            TextButton(
              key: const ValueKey('history-next'),
              onPressed: _controller.busy || !_controller.hasNext
                  ? null
                  : () => _navigate(_controller.next),
              child: Text(copy.historyText('next')),
            ),
          ],
        ),
      ],
    );
  }
}
