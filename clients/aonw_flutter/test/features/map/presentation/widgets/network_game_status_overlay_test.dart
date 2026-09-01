import 'dart:async';

import 'package:aonw_flutter/features/map/application/game_session_capabilities.dart';
import 'package:aonw_flutter/features/map/application/game_session_state.dart';
import 'package:aonw_flutter/features/map/application/network_game_session_port.dart';
import 'package:aonw_flutter/features/map/presentation/map_presentation_controller.dart';
import 'package:aonw_flutter/features/map/presentation/widgets/map_screen.dart';
import 'package:aonw_flutter/features/map/read_model/map_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';
import '../../../../support/map_test_fixture.dart';

void main() {
  testWidgets('blocks a failed network map until full reconnect', (
    tester,
  ) async {
    final scene = testMapScene();
    final network = _ControllableNetworkGameSession(scene);
    final gameplay = FakeGameSession.success(scene);
    final controller = MapPresentationController(
      capabilities: testGameSessionCapabilities(
        gameplay,
      ).withNetworkGame(network),
    );
    addTearDown(controller.dispose);
    addTearDown(network.close);

    await tester.pumpWidget(
      LocalizedTestApp(home: MapScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    network.publish(
      const NetworkGameConnectionView(NetworkGameConnectionPhase.reconnecting),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('network-game-progress')), findsOneWidget);

    network.publish(
      const NetworkGameConnectionView(
        NetworkGameConnectionPhase.failed,
        failureCode: 'connection_interrupted',
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('network-game-failure')), findsOneWidget);
    expect(controller.networkConnection.blocksGameplay, isTrue);

    await tester.tap(find.text('Reconnect'));
    await tester.pumpAndSettle();

    expect(network.reconnectCalls, 1);
    expect(find.byKey(const ValueKey('network-game-failure')), findsNothing);
    expect(
      controller.networkConnection.phase,
      NetworkGameConnectionPhase.ready,
    );
    expect((controller.state as GameSessionReady).scene, same(scene));
  });
}

final class _ControllableNetworkGameSession implements NetworkGameSessionPort {
  _ControllableNetworkGameSession(this.scene);

  final MapScene scene;
  final StreamController<NetworkGameConnectionView> _changes =
      StreamController<NetworkGameConnectionView>.broadcast(sync: true);
  NetworkGameConnectionView _connection = NetworkGameConnectionView.inactive;
  var reconnectCalls = 0;

  @override
  NetworkGameConnectionView get connection => _connection;

  @override
  Stream<NetworkGameConnectionView> get connectionChanges => _changes.stream;

  void publish(NetworkGameConnectionView value) {
    _connection = value;
    _changes.add(value);
  }

  @override
  Future<MapScene> reconnectNetworkMatch() async {
    reconnectCalls += 1;
    publish(
      const NetworkGameConnectionView(NetworkGameConnectionPhase.resyncing),
    );
    publish(const NetworkGameConnectionView(NetworkGameConnectionPhase.ready));
    return scene;
  }

  @override
  Future<MapScene> startNetworkMatch(NetworkMatchSetupView setup) async =>
      scene;

  Future<void> close() => _changes.close();
}
