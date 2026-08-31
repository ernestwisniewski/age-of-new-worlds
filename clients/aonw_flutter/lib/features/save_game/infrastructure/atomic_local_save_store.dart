import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../infrastructure/storage/atomic_local_document_store.dart';
import '../../local_game/application/local_game_catalog.dart';
import '../application/local_save_store.dart';

typedef LocalSaveDirectoryProvider = Future<Directory> Function();

final class AtomicLocalSaveStore implements LocalSaveStore {
  AtomicLocalSaveStore({required LocalSaveDirectoryProvider rootDirectory})
    : _documents = AtomicLocalDocumentStore(
        rootDirectory: rootDirectory,
        directoryName: 'saves',
        maximumBytes: maxLocalSaveDocumentBytes,
      );

  factory AtomicLocalSaveStore.production() =>
      AtomicLocalSaveStore(rootDirectory: getApplicationSupportDirectory);

  final AtomicLocalDocumentStore _documents;

  @override
  Future<bool> contains(LocalGameScenarioView scenario) =>
      _translate(() => _documents.contains(scenario.name));

  @override
  Future<String?> read(
    LocalGameScenarioView scenario,
    LocalSaveCopyView copy,
  ) => _translate(
    () => _documents.read(scenario.name, switch (copy) {
      LocalSaveCopyView.primary => LocalDocumentCopy.primary,
      LocalSaveCopyView.backup => LocalDocumentCopy.backup,
    }),
  );

  @override
  Future<void> write(LocalGameScenarioView scenario, String document) =>
      _translate(() => _documents.write(scenario.name, document));

  static Future<T> _translate<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on AtomicLocalDocumentException catch (error) {
      throw LocalSaveStoreException(
        code: error.code.replaceFirst('document_', 'save_'),
        message: 'The save document could not be stored or read.',
        diagnosticCause: error.cause,
        diagnosticStackTrace: error.stackTrace,
      );
    } on Object catch (error, stackTrace) {
      throw LocalSaveStoreException(
        code: 'save_storage_failed',
        message: 'The save storage operation failed.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }
}
