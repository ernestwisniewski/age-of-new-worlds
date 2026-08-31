import 'dart:io';

import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/replay/application/local_replay_store.dart';
import 'package:aonw_flutter/features/replay/infrastructure/atomic_local_replay_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late AtomicLocalReplayStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('aonw-replay-test-');
    store = AtomicLocalReplayStore(rootDirectory: () async => root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('stores raw engine replay and retains one current backup', () async {
    const first = '{"segments":["first"]}';
    const second = '{"segments":["second"]}';

    await store.write(LocalGameScenarioView.starterDuel, first);
    await store.write(LocalGameScenarioView.starterDuel, second);

    expect(await store.contains(LocalGameScenarioView.starterDuel), isTrue);
    expect(
      await store.read(
        LocalGameScenarioView.starterDuel,
        LocalReplayCopyView.primary,
      ),
      second,
    );
    expect(
      await store.read(
        LocalGameScenarioView.starterDuel,
        LocalReplayCopyView.backup,
      ),
      first,
    );
  });

  test('rejects oversized replay before replacing primary', () async {
    const current = '{"segments":[]}';
    await store.write(LocalGameScenarioView.starterDuel, current);

    await expectLater(
      store.write(
        LocalGameScenarioView.starterDuel,
        'x' * (maxLocalReplayDocumentBytes + 1),
      ),
      throwsA(
        isA<LocalReplayStoreException>().having(
          (error) => error.code,
          'code',
          'replay_size_invalid',
        ),
      ),
    );
    expect(
      await store.read(
        LocalGameScenarioView.starterDuel,
        LocalReplayCopyView.primary,
      ),
      current,
    );
  });
}
