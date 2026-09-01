import 'dart:async';

import 'package:aonw_flutter/features/multiplayer/application/multiplayer_access_port.dart';
import 'package:aonw_flutter/features/multiplayer/presentation/multiplayer_access_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('publishes current access and checks only once', () async {
    final access = _AccessPort([MultiplayerAccessStatus.current]);
    final controller = MultiplayerAccessController(access: access);

    await Future.wait([controller.initialize(), controller.initialize()]);

    expect(controller.phase, MultiplayerAccessPhase.current);
    expect(controller.allowsConnection, isTrue);
    expect(controller.updateRequired, isFalse);
    expect(access.calls, 1);
    controller.dispose();
  });

  test('publishes the required client update', () async {
    final controller = MultiplayerAccessController(
      access: _AccessPort([MultiplayerAccessStatus.updateRequired]),
    );

    await controller.initialize();

    expect(controller.phase, MultiplayerAccessPhase.updateRequired);
    expect(controller.allowsConnection, isFalse);
    expect(controller.updateRequired, isTrue);
    controller.dispose();
  });

  test('fails closed after an error or timeout and can retry', () async {
    final never = Completer<MultiplayerAccessStatus>();
    final access = _AccessPort([
      StateError('offline'),
      never.future,
      MultiplayerAccessStatus.current,
    ]);
    final controller = MultiplayerAccessController(
      access: access,
      timeout: const Duration(milliseconds: 1),
    );

    await controller.initialize();
    expect(controller.phase, MultiplayerAccessPhase.unavailable);
    expect(controller.allowsConnection, isFalse);

    await controller.retry();
    expect(controller.phase, MultiplayerAccessPhase.unavailable);

    await controller.retry();
    expect(controller.phase, MultiplayerAccessPhase.current);
    expect(access.calls, 3);
    controller.dispose();
  });
}

final class _AccessPort implements MultiplayerAccessPort {
  _AccessPort(this.outcomes);

  final List<Object> outcomes;
  var calls = 0;

  @override
  Future<MultiplayerAccessStatus> check() {
    final outcome = outcomes[calls++];
    if (outcome is Future<MultiplayerAccessStatus>) return outcome;
    if (outcome is MultiplayerAccessStatus) return Future.value(outcome);
    return Future.error(outcome);
  }
}
