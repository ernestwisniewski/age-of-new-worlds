import 'dart:io';

import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/save_game/application/local_save_store.dart';
import 'package:aonw_flutter/features/save_game/infrastructure/atomic_local_save_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late DateTime now;
  late Iterator<String> ids;
  late AtomicLocalSaveStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('aonw-save-test-');
    now = DateTime.utc(2026, 9, 1, 10);
    ids = ['1111111111111111', '2222222222222222'].iterator;
    store = AtomicLocalSaveStore(
      rootDirectory: () async => root,
      clock: () => now,
      idGenerator: () {
        if (!ids.moveNext()) throw StateError('No test identifier.');
        return ids.current;
      },
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'keeps multiple named slots for one scenario and one backup each',
    () async {
      const first = '{"state":"first"}';
      const second = '{"state":"second"}';
      const updated = '{"state":"updated"}';

      final firstSlot = await store.create(
        scenario: LocalGameScenarioView.starterDuel,
        name: 'Northern campaign',
        document: first,
      );
      now = DateTime.utc(2026, 9, 1, 11);
      final secondSlot = await store.create(
        scenario: LocalGameScenarioView.starterDuel,
        name: 'Southern campaign',
        document: second,
      );
      now = DateTime.utc(2026, 9, 1, 12);
      final updatedFirst = await store.write(firstSlot, updated);

      expect(
        await store.read(updatedFirst, LocalSaveCopyView.primary),
        updated,
      );
      expect(await store.read(updatedFirst, LocalSaveCopyView.backup), first);
      expect(await store.read(secondSlot, LocalSaveCopyView.primary), second);
      final slots = await store.list();
      expect(slots, hasLength(2));
      expect(slots.map((slot) => slot.id), [firstSlot.id, secondSlot.id]);
      expect(slots.first.name, 'Northern campaign');
      expect(slots.first.savedAt, DateTime.utc(2026, 9, 1, 12));
    },
  );

  test('lists and reads a pre-slot scenario document', () async {
    final directory = Directory.fromUri(root.uri.resolve('saves/'));
    await directory.create(recursive: true);
    final legacy = File.fromUri(directory.uri.resolve('starterDuel.json'));
    await legacy.writeAsString('{"state":"legacy"}', flush: true);

    final slots = await store.list();

    expect(slots, hasLength(1));
    expect(slots.single.id, 'legacy-starterDuel');
    expect(slots.single.scenario, LocalGameScenarioView.starterDuel);
    expect(
      await store.read(slots.single, LocalSaveCopyView.primary),
      '{"state":"legacy"}',
    );
  });

  test('keeps a slot discoverable when only its backup remains', () async {
    final slot = await store.create(
      scenario: LocalGameScenarioView.dravonia,
      name: 'Recovery campaign',
      document: '{"state":"first"}',
    );
    now = DateTime.utc(2026, 9, 1, 11);
    await store.write(slot, '{"state":"second"}');
    final primary = File.fromUri(root.uri.resolve('saves/${slot.id}.json'));
    await primary.delete();

    final slots = await store.list();

    expect(slots, hasLength(1));
    expect(slots.single.id, slot.id);
    expect(await store.read(slots.single, LocalSaveCopyView.primary), isNull);
    expect(
      await store.read(slots.single, LocalSaveCopyView.backup),
      '{"state":"first"}',
    );
  });

  test('rejects an oversized document before replacing the primary', () async {
    const current = '{"state":"current"}';
    final slot = await store.create(
      scenario: LocalGameScenarioView.starterDuel,
      name: null,
      document: current,
    );

    await expectLater(
      store.write(slot, 'x' * (maxLocalSaveDocumentBytes + 1)),
      throwsA(
        isA<LocalSaveStoreException>().having(
          (error) => error.code,
          'code',
          'save_size_invalid',
        ),
      ),
    );

    expect(await store.read(slot, LocalSaveCopyView.primary), current);
  });
}
