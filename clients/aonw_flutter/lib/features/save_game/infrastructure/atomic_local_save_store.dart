import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

import '../../../infrastructure/storage/atomic_local_document_store.dart';
import '../../local_game/application/local_game_catalog.dart';
import '../application/local_save_store.dart';

typedef LocalSaveDirectoryProvider = Future<Directory> Function();
typedef LocalSaveClock = DateTime Function();
typedef LocalSaveIdGenerator = String Function();

const _storageFormatVersion = 1;
const _slotPrefix = 'save-';
const _legacyPrefix = 'legacy-';
const _storedDocumentMaximumBytes = maxLocalSaveDocumentBytes * 2 + 64 * 1024;

final class AtomicLocalSaveStore implements LocalSaveStore {
  AtomicLocalSaveStore({
    required LocalSaveDirectoryProvider rootDirectory,
    LocalSaveClock clock = _utcNow,
    LocalSaveIdGenerator idGenerator = _secureId,
  }) : _rootDirectory = rootDirectory,
       _clock = clock,
       _idGenerator = idGenerator,
       _documents = AtomicLocalDocumentStore(
         rootDirectory: rootDirectory,
         directoryName: 'saves',
         maximumBytes: _storedDocumentMaximumBytes,
       );

  factory AtomicLocalSaveStore.production() =>
      AtomicLocalSaveStore(rootDirectory: getApplicationSupportDirectory);

  final LocalSaveDirectoryProvider _rootDirectory;
  final LocalSaveClock _clock;
  final LocalSaveIdGenerator _idGenerator;
  final AtomicLocalDocumentStore _documents;

  @override
  Future<List<LocalSaveSlotView>> list() => _translate(() async {
    final directory = await _saveDirectory();
    if (!await directory.exists()) return const [];
    final slots = <LocalSaveSlotView>[];
    final indexedDocumentNames = <String>{};
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final documentName = _saveDocumentName(entity.uri);
      if (documentName == null || !indexedDocumentNames.add(documentName)) {
        continue;
      }
      final inferred = _slotFromDocumentName(documentName);
      if (inferred == null) continue;
      slots.add(await _metadataOrFallback(inferred, entity));
    }
    for (final scenario in LocalGameScenarioView.values) {
      final documentName = scenario.name;
      if (!await _documents.contains(documentName)) continue;
      final primary = File.fromUri(directory.uri.resolve('$documentName.json'));
      final file = await primary.exists()
          ? primary
          : File('${primary.path}.backup');
      final stat = await file.stat();
      slots.add(
        LocalSaveSlotView(
          id: '$_legacyPrefix${scenario.name}',
          scenario: scenario,
          savedAt: stat.modified.toUtc(),
        ),
      );
    }
    slots.sort((left, right) => right.savedAt.compareTo(left.savedAt));
    return List.unmodifiable(slots);
  });

  @override
  Future<String?> read(LocalSaveSlotView slot, LocalSaveCopyView copy) =>
      _translate(() async {
        final stored = await _documents.read(
          _documentName(slot),
          _documentCopy(copy),
        );
        if (stored == null || _isLegacy(slot)) return stored;
        return _decodeEnvelope(stored, expected: slot).document;
      });

  @override
  Future<LocalSaveSlotView> create({
    required LocalGameScenarioView scenario,
    required String? name,
    required String document,
  }) => _translate(() async {
    _validateSaveDocument(document);
    late String id;
    for (var attempt = 0; attempt < 8; attempt += 1) {
      id = '$_slotPrefix${scenario.name}-${_idGenerator()}';
      if (_slotFromDocumentName(id) != null && !await _documents.contains(id)) {
        break;
      }
      if (attempt == 7) {
        throw StateError('Could not allocate a unique local save slot.');
      }
    }
    final slot = LocalSaveSlotView(
      id: id,
      scenario: scenario,
      name: _normalizedName(name),
      savedAt: _clock().toUtc(),
    );
    await _documents.write(id, _encodeEnvelope(slot, document));
    return slot;
  });

  @override
  Future<LocalSaveSlotView> write(LocalSaveSlotView slot, String document) =>
      _translate(() async {
        _validateSaveDocument(document);
        final updated = LocalSaveSlotView(
          id: slot.id,
          scenario: slot.scenario,
          name: slot.name,
          savedAt: _clock().toUtc(),
        );
        if (_isLegacy(slot)) {
          await _documents.write(_documentName(slot), document);
          return updated;
        }
        _validateSlot(slot);
        await _documents.write(slot.id, _encodeEnvelope(updated, document));
        return updated;
      });

  Future<Directory> _saveDirectory() async {
    final root = await _rootDirectory();
    return Directory.fromUri(root.uri.resolve('saves/'));
  }

  Future<LocalSaveSlotView> _metadataOrFallback(
    LocalSaveSlotView inferred,
    File primary,
  ) async {
    for (final copy in LocalDocumentCopy.values) {
      try {
        final stored = await _documents.read(inferred.id, copy);
        if (stored != null) {
          return _decodeEnvelope(stored, expected: inferred).slot;
        }
      } on Object {
        // Keep malformed slots visible so the application can mark them as
        // incompatible without losing the user's recovery option.
      }
    }
    final stat = await primary.stat();
    return LocalSaveSlotView(
      id: inferred.id,
      scenario: inferred.scenario,
      savedAt: stat.modified.toUtc(),
    );
  }

  String _documentName(LocalSaveSlotView slot) {
    if (_isLegacy(slot)) return slot.scenario.name;
    _validateSlot(slot);
    return slot.id;
  }

  static bool _isLegacy(LocalSaveSlotView slot) =>
      slot.id == '$_legacyPrefix${slot.scenario.name}';

  static void _validateSlot(LocalSaveSlotView slot) {
    final inferred = _slotFromDocumentName(slot.id);
    if (inferred == null || inferred.scenario != slot.scenario) {
      throw ArgumentError.value(slot.id, 'slot.id', 'invalid local save slot');
    }
  }

  static String _encodeEnvelope(LocalSaveSlotView slot, String document) =>
      jsonEncode({
        'storageFormatVersion': _storageFormatVersion,
        'id': slot.id,
        'scenario': slot.scenario.name,
        'name': slot.name,
        'savedAtUtc': slot.savedAt.toUtc().toIso8601String(),
        'saveDocument': document,
      });

  static ({LocalSaveSlotView slot, String document}) _decodeEnvelope(
    String stored, {
    required LocalSaveSlotView expected,
  }) {
    final decoded = jsonDecode(stored);
    if (decoded is! Map<String, Object?> ||
        decoded.keys.toSet().difference(_envelopeKeys).isNotEmpty ||
        _envelopeKeys.difference(decoded.keys.toSet()).isNotEmpty ||
        decoded['storageFormatVersion'] != _storageFormatVersion ||
        decoded['id'] != expected.id ||
        decoded['scenario'] != expected.scenario.name ||
        decoded['name'] is! String? ||
        decoded['savedAtUtc'] is! String ||
        decoded['saveDocument'] is! String) {
      throw const FormatException('Invalid local save storage envelope.');
    }
    final savedAt = DateTime.parse(decoded['savedAtUtc']! as String).toUtc();
    final document = decoded['saveDocument']! as String;
    _validateSaveDocument(document);
    return (
      slot: LocalSaveSlotView(
        id: expected.id,
        scenario: expected.scenario,
        name: _normalizedName(decoded['name'] as String?),
        savedAt: savedAt,
      ),
      document: document,
    );
  }

  static Future<T> _translate<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on LocalSaveStoreException {
      rethrow;
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

const _envelopeKeys = {
  'storageFormatVersion',
  'id',
  'scenario',
  'name',
  'savedAtUtc',
  'saveDocument',
};

LocalSaveSlotView? _slotFromDocumentName(String name) {
  if (!name.startsWith(_slotPrefix)) return null;
  for (final scenario in LocalGameScenarioView.values) {
    final prefix = '$_slotPrefix${scenario.name}-';
    if (!name.startsWith(prefix)) continue;
    final suffix = name.substring(prefix.length);
    if (RegExp(r'^[a-f0-9]{16,64}$').hasMatch(suffix)) {
      return LocalSaveSlotView(
        id: name,
        scenario: scenario,
        savedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
    }
  }
  return null;
}

String? _saveDocumentName(Uri uri) {
  final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
  if (segments.isEmpty) return null;
  final fileName = segments.last;
  if (fileName.endsWith('.json.backup')) {
    return fileName.substring(0, fileName.length - '.json.backup'.length);
  }
  if (!fileName.endsWith('.json')) return null;
  return fileName.substring(0, fileName.length - '.json'.length);
}

LocalDocumentCopy _documentCopy(LocalSaveCopyView copy) => switch (copy) {
  LocalSaveCopyView.primary => LocalDocumentCopy.primary,
  LocalSaveCopyView.backup => LocalDocumentCopy.backup,
};

String? _normalizedName(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized.length <= 80 ? normalized : normalized.substring(0, 80);
}

void _validateSaveDocument(String document) {
  final length = utf8.encode(document).length;
  if (length <= 0 || length > maxLocalSaveDocumentBytes) {
    throw LocalSaveStoreException(
      code: 'save_size_invalid',
      message: 'The save document has an invalid byte length.',
      diagnosticCause: StateError('Save document byte length: $length'),
      diagnosticStackTrace: StackTrace.current,
    );
  }
}

DateTime _utcNow() => DateTime.now().toUtc();

String _secureId() {
  final random = Random.secure();
  return [
    for (var index = 0; index < 16; index += 1)
      random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}
