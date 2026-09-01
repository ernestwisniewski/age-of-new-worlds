import 'package:aonw_engine_client/aonw_engine_client.dart';
import 'package:aonw_flutter/features/map/infrastructure/recipient_projection_cache.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

part 'recipient_projection_cache_fixture.dart';

void main() {
  test('applies current values, replacements and clears atomically', () {
    final initial = _snapshot(
      pendingAction: const AonwPendingResearchSelection(),
      cityFoundingDraft: const AonwCityFoundingDraft(
        founderUnitId: 'unit-1',
        center: AonwCoordinate(col: 1, row: 1),
        controlledHexes: [AonwCoordinate(col: 1, row: 1)],
      ),
    );
    final lifecycle = const AonwPlayerTurnLifecycle(
      ownState: AonwPlayerTurnState.finished,
      ownSubmitted: true,
      requiredSubmissionCount: 2,
      submittedCount: 2,
    );
    final outcome = AonwGameOutcome(
      condition: AonwGameOutcomeCondition.score,
      winnerPlayerId: 'player-1',
      scoreByPlayerId: const {'player-1': 20},
    );
    final diplomacy = _diplomacy();
    final economy = AonwPlayerEconomyView(
      gold: 25,
      warWeariness: 2,
      stabilityNet: -1,
      strategicResourceStockpile: const [],
      strategicResourceOutput: const [],
      strategicResourceSources: const [],
    );
    final research = _research(progress: 7);
    final victory = _victory(turn: 2, score: 8);
    final cache = _cache(initial);

    final after = cache.apply(
      _command(
        stamp: _stamp(revision: 1, stateDigest: 'd' * 64),
        patch: _patch(
          fromRevision: 0,
          toRevision: 1,
          turn: 2,
          turnLifecycle: lifecycle,
          outcome: outcome,
          economy: economy,
          research: research,
          victory: victory,
          diplomacy: diplomacy,
          upsertedUnits: [_unit(col: 1, row: 0)],
        ),
      ),
    );

    expect(after.stamp.revision, 1);
    expect(after.turn, 2);
    expect(after.turnMode, AonwTurnMode.sequential);
    expect(after.turnLifecycle, same(lifecycle));
    expect(after.outcome, same(outcome));
    expect(after.diplomacy, same(diplomacy));
    expect(after.economy, same(economy));
    expect(after.research, same(research));
    expect(after.victory, same(victory));
    expect(after.pendingAction, isNull);
    expect(after.cityFoundingDraft, isNull);
    expect(after.units.single.coordinate.col, 1);
    expect(() => after.units.add(_unit()), throwsUnsupportedError);
  });

  test('rejects an economy replacement on an unchanged command', () {
    final initial = _snapshot();
    final cache = _cache(initial);

    expect(
      () => cache.apply(
        _command(
          accepted: false,
          stamp: initial.stamp,
          patch: _patch(
            fromRevision: 0,
            toRevision: 0,
            turn: 1,
            economy: AonwPlayerEconomyView(
              gold: 1,
              warWeariness: 0,
              stabilityNet: 0,
              strategicResourceStockpile: const [],
              strategicResourceOutput: const [],
              strategicResourceSources: const [],
            ),
          ),
        ),
      ),
      throwsFormatException,
    );
    expect(cache.snapshot, same(initial));
  });

  test('rejects a research replacement on an unchanged command', () {
    final initial = _snapshot();
    final cache = _cache(initial);

    expect(
      () => cache.apply(
        _command(
          accepted: false,
          stamp: initial.stamp,
          patch: _patch(
            fromRevision: 0,
            toRevision: 0,
            turn: 1,
            research: _research(),
          ),
        ),
      ),
      throwsFormatException,
    );
    expect(cache.snapshot, same(initial));
  });

  test('rejects a victory replacement on an unchanged command', () {
    final initial = _snapshot(victory: _victory(turn: 1, score: 3));
    final cache = _cache(initial);

    expect(
      () => cache.apply(
        _command(
          accepted: false,
          stamp: initial.stamp,
          patch: _patch(
            fromRevision: 0,
            toRevision: 0,
            turn: 1,
            victory: _victory(turn: 1, score: 4),
          ),
        ),
      ),
      throwsFormatException,
    );
    expect(cache.snapshot, same(initial));
  });

  test('keeps conditional fields for an unchanged rejected command', () {
    final initial = _snapshot(
      pendingAction: const AonwPendingWorkerActionSelection(
        unitId: 'unit-1',
        improvement: AonwFieldImprovementKind.farm,
      ),
      cityFoundingDraft: _draft(),
    );
    final cache = _cache(initial);

    final after = cache.apply(
      _command(
        accepted: false,
        stamp: initial.stamp,
        patch: _patch(
          fromRevision: 0,
          toRevision: 0,
          turn: 1,
          pendingAction: const AonwPendingWorkerActionSelection(
            unitId: 'unit-1',
            improvement: AonwFieldImprovementKind.farm,
          ),
          cityFoundingDraft: _draft(),
        ),
      ),
    );

    expect(after, same(initial));
    expect(after.stamp.revision, 0);
    expect(after.turnLifecycle, same(initial.turnLifecycle));
    expect(after.outcome, same(initial.outcome));
    expect(after.diplomacy, same(initial.diplomacy));
    expect(after.units.single.coordinate.col, 0);
  });

  test('replaces fog atomically and rejects invalid visibility', () {
    final initial = _snapshot();
    final cache = _cache(initial);
    const fog = AonwPlayerFogView(
      enabled: true,
      discoveredHexes: [
        AonwCoordinate(col: 0, row: 0),
        AonwCoordinate(col: 1, row: 0),
      ],
      visibleHexes: [AonwCoordinate(col: 1, row: 0)],
    );

    final after = cache.apply(
      _command(
        stamp: _stamp(revision: 1, stateDigest: 'd' * 64),
        patch: _patch(fromRevision: 0, toRevision: 1, turn: 1, fog: fog),
      ),
    );

    expect(after.fog, same(fog));
    expect(
      () => cache.replaceAfterResync(
        _snapshot(
          revision: 2,
          fog: const AonwPlayerFogView(
            enabled: true,
            discoveredHexes: [AonwCoordinate(col: 0, row: 0)],
            visibleHexes: [AonwCoordinate(col: 1, row: 0)],
          ),
        ),
      ),
      throwsFormatException,
    );
    expect(cache.snapshot, same(after));
  });

  test('rejects every conditional-field mutation on a rejected command', () {
    final cases =
        <
          ({
            AonwPlayerViewSnapshot before,
            AonwPendingActionView? pendingAction,
            AonwCityFoundingDraft? cityFoundingDraft,
          })
        >[
          (
            before: _snapshot(
              pendingAction: const AonwPendingResearchSelection(),
            ),
            pendingAction: null,
            cityFoundingDraft: null,
          ),
          (
            before: _snapshot(),
            pendingAction: const AonwPendingResearchSelection(),
            cityFoundingDraft: null,
          ),
          (
            before: _snapshot(
              pendingAction: const AonwPendingResearchSelection(),
            ),
            pendingAction: const AonwPendingCityWorkedHexSelection(
              cityId: 'city-1',
            ),
            cityFoundingDraft: null,
          ),
          (
            before: _snapshot(
              pendingAction: const AonwPendingWorkerActionSelection(
                unitId: 'unit-1',
                improvement: AonwFieldImprovementKind.farm,
              ),
            ),
            pendingAction: const AonwPendingWorkerActionSelection(
              unitId: 'unit-1',
              improvement: AonwFieldImprovementKind.mine,
            ),
            cityFoundingDraft: null,
          ),
          (
            before: _snapshot(cityFoundingDraft: _draft()),
            pendingAction: null,
            cityFoundingDraft: null,
          ),
          (
            before: _snapshot(),
            pendingAction: null,
            cityFoundingDraft: _draft(),
          ),
          (
            before: _snapshot(cityFoundingDraft: _draft()),
            pendingAction: null,
            cityFoundingDraft: _draft(founderUnitId: 'unit-2'),
          ),
        ];

    for (final value in cases) {
      final cache = _cache(value.before);
      expect(
        () => cache.apply(
          _command(
            accepted: false,
            stamp: value.before.stamp,
            patch: _patch(
              fromRevision: 0,
              toRevision: 0,
              turn: 1,
              pendingAction: value.pendingAction,
              cityFoundingDraft: value.cityFoundingDraft,
            ),
          ),
        ),
        throwsFormatException,
      );
      expect(cache.snapshot, same(value.before));
    }
  });

  test('retains the cached snapshot for an accepted identity patch', () {
    final initial = _snapshot(
      revision: 1,
      pendingAction: const AonwPendingResearchSelection(),
    );
    final cache = _cache(initial);

    final after = cache.apply(
      _command(
        stamp: initial.stamp,
        patch: _patch(
          fromRevision: 1,
          toRevision: 1,
          turn: 1,
          pendingAction: const AonwPendingResearchSelection(),
        ),
      ),
    );

    expect(after, same(initial));
    expect(after.pendingAction, same(initial.pendingAction));
  });

  test('rejects a mutating accepted identity patch', () {
    final initial = _snapshot(
      revision: 1,
      pendingAction: const AonwPendingResearchSelection(),
    );
    final cache = _cache(initial);

    expect(
      () => cache.apply(
        _command(
          stamp: initial.stamp,
          patch: _patch(fromRevision: 1, toRevision: 1, turn: 1),
        ),
      ),
      throwsFormatException,
    );
    expect(cache.snapshot, same(initial));
  });

  test('rejects stale, unknown-removal and out-of-bounds patches', () {
    final stale = _cache(_snapshot());
    expect(
      () => stale.apply(
        _command(
          stamp: _stamp(revision: 2, stateDigest: 'e' * 64),
          patch: _patch(fromRevision: 1, toRevision: 2, turn: 1),
        ),
      ),
      throwsFormatException,
    );
    expect(stale.snapshot.stamp.revision, 0);

    final unknownRemoval = _cache(_snapshot());
    expect(
      () => unknownRemoval.apply(
        _command(
          stamp: _stamp(revision: 1, stateDigest: 'd' * 64),
          patch: _patch(
            fromRevision: 0,
            toRevision: 1,
            turn: 1,
            removedUnitIds: const ['missing-unit'],
          ),
        ),
      ),
      throwsFormatException,
    );
    expect(unknownRemoval.snapshot.stamp.revision, 0);

    final outOfBounds = _cache(_snapshot());
    expect(
      () => outOfBounds.apply(
        _command(
          stamp: _stamp(revision: 1, stateDigest: 'd' * 64),
          patch: _patch(
            fromRevision: 0,
            toRevision: 1,
            turn: 1,
            upsertedUnits: [_unit(col: 99, row: 99)],
          ),
        ),
      ),
      throwsFormatException,
    );
    expect(outOfBounds.snapshot.stamp.revision, 0);
  });

  test('resync accepts only the same session without moving backwards', () {
    final cache = _cache(_snapshot(revision: 1));
    final newer = _snapshot(revision: 3);

    cache.replaceAfterResync(newer);
    expect(cache.snapshot.stamp.revision, 3);
    expect(
      () => cache.replaceAfterResync(_snapshot(revision: 2)),
      throwsFormatException,
    );
    expect(
      () => cache.replaceAfterResync(
        _snapshot(revision: 4, rulesetHash: 'f' * 64),
      ),
      throwsFormatException,
    );
  });

  test('rejects turn mode drift in patches and resync snapshots', () {
    final initial = _snapshot(turnMode: AonwTurnMode.simultaneous);
    final cache = _cache(initial);

    expect(
      () => cache.apply(
        _command(
          stamp: _stamp(revision: 1, stateDigest: 'd' * 64),
          patch: _patch(fromRevision: 0, toRevision: 1, turn: 1),
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => cache.replaceAfterResync(_snapshot(revision: 1)),
      throwsFormatException,
    );
    expect(cache.snapshot, same(initial));
  });

  test('rejects invalid or changing participant rosters', () {
    expect(
      () => _cache(_snapshot(participants: const [])),
      throwsFormatException,
    );
    expect(
      () => _cache(
        _snapshot(
          participants: const [
            AonwPlayerParticipantView(
              id: 'player-2',
              name: 'Player Two',
              colorValue: 0xff000000,
              country: AonwPlayerCountry.germany,
              kind: AonwPlayerKind.human,
            ),
          ],
        ),
      ),
      throwsFormatException,
    );

    final initial = _snapshot();
    final cache = _cache(initial);
    expect(
      () => cache.replaceAfterResync(
        _snapshot(
          revision: 1,
          participants: const [
            AonwPlayerParticipantView(
              id: 'player-1',
              name: 'Renamed Player',
              colorValue: 0xff000000,
              country: AonwPlayerCountry.poland,
              kind: AonwPlayerKind.human,
            ),
          ],
        ),
      ),
      throwsFormatException,
    );
    expect(cache.snapshot, same(initial));
  });
}
