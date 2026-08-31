import 'package:aonw_flutter/features/turns/application/turn_presentation_queue.dart';
import 'package:aonw_flutter/features/turns/read_model/turn_activity_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('presents each observed turn once and in order', () {
    final initial = TurnPresentationQueue.start(7);

    expect(initial.active?.turn, 7);
    expect(initial.observe(7), same(initial));
    expect(initial.observe(6), same(initial));

    final queued = initial.observe(8).observe(9);
    expect(queued.active?.turn, 7);
    expect(queued.pending.map((item) => item.turn), [8, 9]);

    final second = queued.completeActive();
    expect(second.active?.turn, 8);
    expect(second.pending.single.turn, 9);
    final third = second.completeActive();
    expect(third.active?.turn, 9);
    expect(third.completeActive().active, isNull);
  });

  test('rejects non-positive turn numbers', () {
    expect(() => TurnPresentationQueue.start(0), throwsArgumentError);
  });

  test('deduplicates ordered activity and bounds its backlog', () {
    var queue = TurnPresentationQueue.start(1);
    for (var revision = 1; revision <= 70; revision++) {
      queue = queue.observeActivities([
        _activity(revision: revision, index: 0),
      ]);
    }
    expect(
      queue.activities,
      hasLength(TurnPresentationQueue.maximumActivityBacklog),
    );
    expect(queue.activities.first.identity.revision, 7);
    expect(queue.latestActivity?.identity.revision, 70);

    final duplicate = queue.observeActivities([
      _activity(revision: 70, index: 0),
    ]);
    expect(duplicate.activities, queue.activities);
  });

  test('fails closed for non-authoritative activity order', () {
    final queue = TurnPresentationQueue.start(
      1,
    ).observeActivities([_activity(revision: 4, index: 1)]);
    expect(
      () => queue.observeActivities([_activity(revision: 4, index: 0)]),
      throwsFormatException,
    );
  });
}

TurnActivityView _activity({required int revision, required int index}) =>
    TurnActivityView(
      identity: TurnActivityIdentityView(revision: revision, eventIndex: index),
      kind: TurnActivityKindView.turnEnded,
    );
