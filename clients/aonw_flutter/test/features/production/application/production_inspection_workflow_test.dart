import 'dart:async';

import 'package:aonw_flutter/features/cities/application/city_state.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/production/application/production_session_port.dart';
import 'package:aonw_flutter/features/production/application/production_state.dart';
import 'package:aonw_flutter/features/production/application/production_workflow.dart';
import 'package:aonw_flutter/features/production/read_model/production_details_view.dart';
import 'package:aonw_flutter/features/production/read_model/production_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';
import '../presentation/production_catalog_fixture.dart';

void main() {
  test(
    'a newer target owns the result even when an older request finishes last',
    () async {
      final h = _Harness();
      h.inspect('granary');
      h.inspect('port');
      h.session.complete(1);
      await pumpEventQueue();
      final shown = h.state.interaction.production!.inspection!;
      expect(shown.loading, isFalse);
      expect(
        (shown.details!.option.target as BuildingProductionTargetView).building,
        'port',
      );
      h.session.complete(0);
      await pumpEventQueue();
      expect(h.state.interaction.production!.inspection, same(shown));
    },
  );

  test(
    'closing and reopening the same target ignores the first request',
    () async {
      final h = _Harness();
      h.inspect('granary');
      h.inspect(null);
      expect(h.state.interaction.production!.inspection, isNull);
      h.inspect('granary');
      h.session.complete(0);
      await pumpEventQueue();
      expect(h.state.interaction.production!.inspection!.loading, isTrue);
      h.session.complete(1);
      await pumpEventQueue();
      expect(h.state.interaction.production!.inspection!.loading, isFalse);
    },
  );

  test(
    'recipient revision catalog closure and disposal invalidate pending results',
    () async {
      for (final change in ['recipient', 'revision', 'catalog', 'disposed']) {
        final h = _Harness();
        h.inspect('granary');
        if (change == 'recipient' || change == 'revision') {
          h.state = h.state.withRecipient(
            PlayerMapView.preview(
              actorPlayerId: change == 'recipient'
                  ? 'another-player'
                  : 'preview-player',
              stamp: testSessionStamp(revision: change == 'revision' ? 1 : 0),
              turn: 1,
              pendingAction: null,
              units: [],
              cities: [testCityView()],
            ),
          );
        } else if (change == 'catalog') {
          h.state = h.state.withInteraction(
            h.state.interaction.copyWith(
              production: h.state.interaction.production!.copyWith(
                catalogOpen: false,
              ),
            ),
          );
        } else {
          h.disposed = true;
        }
        final state = h.state;
        h.session.complete(0);
        await pumpEventQueue();
        expect(h.state, same(state), reason: change);
      }
    },
  );

  test(
    'obsolete failures cannot replace a successful newer inspection',
    () async {
      final h = _Harness();
      h.inspect('granary');
      h.inspect('port');
      h.session.complete(1);
      await pumpEventQueue();
      final shown = h.state;
      h.session.requests.first.$2.completeError(
        const ProductionSessionException(
          code: 'invalid_session_protocol',
          message: 'obsolete failure',
        ),
      );
      await pumpEventQueue();
      expect(h.state, same(shown));
      expect(h.diagnostics, isEmpty);
    },
  );

  test('published details clear immediately when identity changes', () async {
    final h = _Harness();
    h.inspect('granary');
    h.session.complete(0);
    await pumpEventQueue();
    final loaded = h.state;
    final inspection = loaded.interaction.production!.inspection!;
    expect(inspection.details, isNotNull);
    PlayerMapView player(String actor, int revision) => PlayerMapView.preview(
      actorPlayerId: actor,
      stamp: testSessionStamp(revision: revision),
      turn: 1,
      pendingAction: null,
      units: [],
      cities: [testCityView()],
    );
    final unchanged = loaded.withRecipient(player('preview-player', 0));
    expect(unchanged.interaction.production!.inspection, same(inspection));
    final changed = loaded.withRecipient(player('preview-player', 1));
    expect(changed.interaction.production!.inspection!.details, isNull);
    expect(changed.interaction.production!.inspection!.loading, isTrue);
    expect(
      changed.interaction.production!.inspection!.target,
      inspection.target,
    );
    final foreign = loaded.withRecipient(player('another-player', 0));
    expect(foreign.interaction.production!.inspection, isNull);
  });

  test(
    'overview failure at an old revision does not replace refreshed options',
    () async {
      final h = _Harness();
      h.workflow.load(
        cityId: 'preview-city',
        readState: () => h.state,
        publish: (value) => h.state = value,
        isDisposed: () => false,
      );
      h.state = h.state.withRecipient(
        PlayerMapView.preview(
          actorPlayerId: 'preview-player',
          stamp: testSessionStamp(revision: 1),
          turn: 1,
          pendingAction: null,
          units: [],
          cities: [testCityView()],
        ),
      );
      final state = h.state;
      h.session.overview.completeError(
        const ProductionSessionException(
          code: 'stale_revision',
          message: 'old',
        ),
      );
      await pumpEventQueue();
      expect(h.state, same(state));
    },
  );
}

final class _Harness {
  _Harness() {
    final ready = GameSessionReady.initial(
      testMapScene(cities: [testCityView()]),
    );
    state = ready.withInteraction(
      ready.interaction.copyWith(
        city: const CityState(cityId: 'preview-city'),
        production: ProductionState(
          cityId: 'preview-city',
          catalogOpen: true,
          options: catalogOptions(),
        ),
      ),
    );
    workflow = ProductionWorkflow(
      session: session,
      diagnosticReporter: (code, error, stack) => diagnostics.add(code),
    );
  }
  final session = _Session();
  final diagnostics = <String>[];
  late final ProductionWorkflow workflow;
  late GameSessionReady state;
  bool disposed = false;

  void inspect(String? building) => workflow.inspect(
    target: building == null ? null : BuildingProductionTargetView(building),
    readState: () => state,
    publish: (value) => state = value,
    isDisposed: () => disposed,
  );
}

final class _Session implements ProductionSessionPort {
  final requests = <(ProductionTargetView, Completer<ProductionDetailsView>)>[];
  final overview = Completer<ProductionOverviewFixture>();

  @override
  Future<ProductionDetailsView> productionDetails({
    required int expectedRevision,
    required String cityId,
    required ProductionTargetView target,
  }) {
    expect(expectedRevision, 0);
    expect(cityId, 'preview-city');
    final response = Completer<ProductionDetailsView>();
    requests.add((target, response));
    return response.future;
  }

  void complete(int index) {
    final (target, response) = requests[index];
    const output = ProductionCityOutputView(
      grossYield: _zero,
      foodDeposit: 0,
      production: 0,
      gold: 0,
      science: 0,
      maxControlledHexes: 4,
    );
    response.complete(
      ProductionDetailsView(
        stamp: testSessionStamp(),
        cityId: 'preview-city',
        option: catalogOptions().optionFor(target)!,
        effects: BuildingProductionDetailsView(
          requirements: [],
          flatYield: _zero,
          riverYieldPerHex: _zero,
          maxRiverApplications: 0,
          riverApplications: 0,
          sciencePerTurn: 0,
          maxControlledHexesDelta: 0,
          foodDepositBasisPoints: 10000,
          current: output,
          completed: output,
        ),
      ),
    );
  }

  @override
  Future<ProductionOverviewFixture> productionOverview({
    required int expectedRevision,
    required String cityId,
  }) => overview.future;

  @override
  Future<ProductionCommandResultView> executeProductionAction({
    required int expectedRevision,
    required ProductionActionView action,
  }) => throw UnimplementedError();
}

const _zero = YieldValueView(food: 0, production: 0, gold: 0, defense: 0);
