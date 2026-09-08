import 'dart:async';

import 'package:aonw_flutter/features/audio/application/game_audio_port.dart';
import 'package:aonw_flutter/features/cities/application/city_session_port.dart';
import 'package:aonw_flutter/features/cities/read_model/city_view.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  for (final completion in ['success', 'typed failure', 'unexpected failure']) {
    test(
      'an abandoned founding $completion cannot replace a newer draft',
      () async {
        final session = _DelayedFoundingSession();
        final controller = MapPresentationController(
          capabilities: testGameSessionCapabilities(
            FakeGameSession.success(
              testMapScene(units: [testVisibleUnit()]),
              reachableResult: testReachableView(),
            ),
            cities: session,
          ),
        );
        addTearDown(controller.dispose);
        final sounds = <GameSoundCue>[];
        controller.bindInteractionSounds(sounds.add);
        await controller.load();
        controller.selectUnit('preview-commander');
        await pumpEventQueue();
        controller.openCityFounding();
        controller.cancelInteraction();
        controller.openCityFounding();
        final current = controller.state as GameSessionReady;
        final correlation = current.interaction.city!.correlationId;
        if (completion == 'success') {
          session.requests.first.complete(testCityFoundingOptionsView());
        } else {
          session.requests.first.completeError(
            completion == 'typed failure'
                ? const CitySessionException(
                    code: 'session_not_open',
                    message: 'Abandoned request',
                  )
                : StateError('Abandoned request'),
          );
        }
        await pumpEventQueue();
        final loading =
            (controller.state as GameSessionReady).interaction.city!;
        expect(loading.loading, isTrue);
        expect(loading.correlationId, correlation);
        expect(loading.failure, isNull);
        expect(loading.foundingOptions, isNull);
        expect(sounds, isEmpty);
        session.requests.last.complete(testCityFoundingOptionsView());
        await pumpEventQueue();
        final ready = (controller.state as GameSessionReady).interaction.city!;
        expect(ready.loading, isFalse);
        expect(ready.foundingOptions, isNotNull);
        expect(ready.correlationId, correlation);
        expect(sounds, [GameSoundCue.uiPanelOpen]);
      },
    );
  }
}

final class _DelayedFoundingSession implements CitySessionPort {
  final requests = <Completer<CityFoundingOptionsView>>[];

  @override
  Future<CityFoundingOptionsView> cityFoundingOptions({
    required int expectedRevision,
    required String founderUnitId,
  }) {
    final request = Completer<CityFoundingOptionsView>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<CityInspectionView> inspectCity({
    required int expectedRevision,
    required String cityId,
  }) => throw UnsupportedError('Inspection is outside this test.');

  @override
  Future<CityCommandResultView> executeCityAction({
    required int expectedRevision,
    required CityActionView action,
  }) => throw UnsupportedError('Commands are outside this test.');
}
