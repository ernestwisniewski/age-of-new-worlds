import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../infrastructure/storage/atomic_local_document_store.dart';
import '../../local_game/application/local_game_catalog.dart';
import '../application/local_replay_store.dart';

typedef LocalReplayDirectoryProvider = Future<Directory> Function();

final class AtomicLocalReplayStore implements LocalReplayStore {
  AtomicLocalReplayStore({required LocalReplayDirectoryProvider rootDirectory})
    : _documents = AtomicLocalDocumentStore(
        rootDirectory: rootDirectory,
        directoryName: 'replays',
        maximumBytes: maxLocalReplayDocumentBytes,
      );

  factory AtomicLocalReplayStore.production() =>
      AtomicLocalReplayStore(rootDirectory: getApplicationSupportDirectory);

  final AtomicLocalDocumentStore _documents;

  @override
  Future<bool> contains(LocalGameScenarioView scenario) =>
      _translate(() => _documents.contains(scenario.name));

  @override
  Future<String?> read(
    LocalGameScenarioView scenario,
    LocalReplayCopyView copy,
  ) => _translate(
    () => _documents.read(scenario.name, switch (copy) {
      LocalReplayCopyView.primary => LocalDocumentCopy.primary,
      LocalReplayCopyView.backup => LocalDocumentCopy.backup,
    }),
  );

  @override
  Future<void> write(LocalGameScenarioView scenario, String document) =>
      _translate(() => _documents.write(scenario.name, document));

  static Future<T> _translate<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AtomicLocalDocumentException catch (error) {
      throw LocalReplayStoreException(
        code: error.code.replaceFirst('document_', 'replay_'),
        message: 'The replay document could not be stored or read.',
        diagnosticCause: error.cause,
        diagnosticStackTrace: error.stackTrace,
      );
    } on Object catch (error, stackTrace) {
      throw LocalReplayStoreException(
        code: 'replay_storage_failed',
        message: 'The replay storage operation failed.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }
}
