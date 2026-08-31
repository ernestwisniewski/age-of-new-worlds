import 'dart:io';

import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_store.dart';
import 'package:aonw_flutter/features/save_game/infrastructure/atomic_local_save_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late AtomicLocalSaveStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('aonw-save-test-');
    store = AtomicLocalSaveStore(rootDirectory: () async => root);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'installs raw engine documents atomically and retains one backup',
    () async {
      const first = '{"state":"first"}';
      const second = '{"state":"second"}';

      expect(await store.contains(LocalGameScenarioView.starterDuel), isFalse);
      await store.write(LocalGameScenarioView.starterDuel, first);
      expect(
        await store.read(
          LocalGameScenarioView.starterDuel,
          LocalSaveCopyView.primary,
        ),
        first,
      );
      expect(
        await store.read(
          LocalGameScenarioView.starterDuel,
          LocalSaveCopyView.backup,
        ),
        isNull,
      );

      await store.write(LocalGameScenarioView.starterDuel, second);

      expect(await store.contains(LocalGameScenarioView.starterDuel), isTrue);
      expect(
        await store.read(
          LocalGameScenarioView.starterDuel,
          LocalSaveCopyView.primary,
        ),
        second,
      );
      expect(
        await store.read(
          LocalGameScenarioView.starterDuel,
          LocalSaveCopyView.backup,
        ),
        first,
      );
    },
  );

  test('rejects an oversized document before replacing the primary', () async {
    const current = '{"state":"current"}';
    await store.write(LocalGameScenarioView.starterDuel, current);

    await expectLater(
      store.write(
        LocalGameScenarioView.starterDuel,
        'x' * (maxLocalSaveDocumentBytes + 1),
      ),
      throwsA(
        isA<LocalSaveStoreException>().having(
          (error) => error.code,
          'code',
          'save_size_invalid',
        ),
      ),
    );

    expect(
      await store.read(
        LocalGameScenarioView.starterDuel,
        LocalSaveCopyView.primary,
      ),
      current,
    );
  });
}
