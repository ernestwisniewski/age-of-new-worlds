import '../read_model/turn_activity_view.dart';

final class TurnPresentation {
  const TurnPresentation({required this.turn});

  final int turn;
}

final class TurnPresentationQueue {
  TurnPresentationQueue._({
    required this.latestTurn,
    required this.active,
    required List<TurnPresentation> pending,
    required List<TurnActivityView> activities,
  }) : pending = List.unmodifiable(pending),
       activities = List.unmodifiable(activities);

  factory TurnPresentationQueue.start(int turn) {
    _validateTurn(turn);
    return TurnPresentationQueue._(
      latestTurn: turn,
      active: TurnPresentation(turn: turn),
      pending: const [],
      activities: const [],
    );
  }

  final int latestTurn;
  final TurnPresentation? active;
  final List<TurnPresentation> pending;
  final List<TurnActivityView> activities;

  TurnActivityView? get latestActivity =>
      activities.isEmpty ? null : activities.last;

  TurnPresentationQueue observe(int turn) {
    _validateTurn(turn);
    if (turn <= latestTurn) return this;
    final presentation = TurnPresentation(turn: turn);
    if (active == null) {
      return TurnPresentationQueue._(
        latestTurn: turn,
        active: presentation,
        pending: pending,
        activities: activities,
      );
    }
    return TurnPresentationQueue._(
      latestTurn: turn,
      active: active,
      pending: [...pending, presentation],
      activities: activities,
    );
  }

  TurnPresentationQueue observeActivities(List<TurnActivityView> values) {
    if (values.isEmpty) return this;
    return TurnPresentationQueue._(
      latestTurn: latestTurn,
      active: active,
      pending: pending,
      activities: _mergeActivities(activities, values),
    );
  }

  TurnPresentationQueue completeActive() {
    if (active == null) return this;
    if (pending.isEmpty) {
      return TurnPresentationQueue._(
        latestTurn: latestTurn,
        active: null,
        pending: const [],
        activities: activities,
      );
    }
    return TurnPresentationQueue._(
      latestTurn: latestTurn,
      active: pending.first,
      pending: pending.skip(1).toList(growable: false),
      activities: activities,
    );
  }

  static void _validateTurn(int turn) {
    if (turn < 1) {
      throw ArgumentError.value(turn, 'turn', 'must be positive');
    }
  }

  static void _validateActivityIdentity(TurnActivityIdentityView identity) {
    if (identity.revision < 1 || identity.eventIndex < 0) {
      throw const FormatException('Invalid turn activity identity.');
    }
  }

  static const maximumActivityBacklog = 64;
}

List<TurnActivityView> _mergeActivities(
  List<TurnActivityView> current,
  List<TurnActivityView> incoming,
) {
  final next = [...current];
  final identities = {for (final item in current) item.identity};
  TurnActivityIdentityView? previous = current.lastOrNull?.identity;
  for (final item in incoming) {
    TurnPresentationQueue._validateActivityIdentity(item.identity);
    if (!identities.add(item.identity)) continue;
    if (previous case final last? when !_isAfter(item.identity, last)) {
      throw const FormatException(
        'Turn activity events are not in authoritative order.',
      );
    }
    next.add(item);
    previous = item.identity;
  }
  return next.length <= TurnPresentationQueue.maximumActivityBacklog
      ? next
      : next.sublist(
          next.length - TurnPresentationQueue.maximumActivityBacklog,
        );
}

bool _isAfter(
  TurnActivityIdentityView candidate,
  TurnActivityIdentityView previous,
) =>
    candidate.revision > previous.revision ||
    (candidate.revision == previous.revision &&
        candidate.eventIndex > previous.eventIndex);
