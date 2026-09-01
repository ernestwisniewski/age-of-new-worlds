import 'package:aonw_flutter/features/map/application/game_session_capabilities.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/map_coordinator.dart';
import 'package:aonw_flutter/features/map/application/network_game_session_port.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/map_test_fixture.dart';

void main() {
  test('opens a network match through the shared map state', () async {
    final scene = testMapScene();
    final network = _NetworkGameSession(scene);
    final gameplay = FakeGameSession.success(scene);
    final coordinator = MapCoordinator(
      capabilities: testGameSessionCapabilities(
        gameplay,
      ).withNetworkGame(network),
    );
    addTearDown(coordinator.dispose);

    final opened = await coordinator.startNetworkMatch(
      const NetworkMatchSetupView(matchId: 'match-7', playerId: 'player-2'),
    );

    expect(opened, isTrue);
    expect(network.setups.single.matchId, 'match-7');
    expect(network.setups.single.playerId, 'player-2');
    expect((coordinator.state as GameSessionReady).scene, same(scene));
  });

  test('fails closed when network gameplay is not composed', () async {
    final gameplay = FakeGameSession.success(testMapScene());
    final coordinator = MapCoordinator(
      capabilities: testGameSessionCapabilities(gameplay),
      diagnosticReporter: (_, _, _) {},
    );
    addTearDown(coordinator.dispose);

    final opened = await coordinator.startNetworkMatch(
      const NetworkMatchSetupView(matchId: 'match-7', playerId: 'player-2'),
    );

    expect(opened, isFalse);
    expect(coordinator.state, isA<GameSessionFailure>());
  });
}

final class _NetworkGameSession implements NetworkGameSessionPort {
  _NetworkGameSession(this.scene);

  final MapScene scene;
  final setups = <NetworkMatchSetupView>[];

  @override
  Future<MapScene> startNetworkMatch(NetworkMatchSetupView setup) async {
    setups.add(setup);
    return scene;
  }
}
