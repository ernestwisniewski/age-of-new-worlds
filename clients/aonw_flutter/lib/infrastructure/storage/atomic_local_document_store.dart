import 'dart:convert';
import 'dart:io';

typedef LocalDocumentDirectoryProvider = Future<Directory> Function();

enum LocalDocumentCopy { primary, backup }

final class AtomicLocalDocumentStore {
  AtomicLocalDocumentStore({
    required LocalDocumentDirectoryProvider rootDirectory,
    required String directoryName,
    required int maximumBytes,
  }) : _rootDirectory = rootDirectory,
       _directoryName = directoryName,
       _maximumBytes = maximumBytes;

  final LocalDocumentDirectoryProvider _rootDirectory;
  final String _directoryName;
  final int _maximumBytes;
  Future<void> _writeTail = Future<void>.value();

  Future<bool> contains(String name) async {
    final paths = await _paths(name, createDirectory: false);
    return await paths.primary.exists() || await paths.backup.exists();
  }

  Future<String?> read(String name, LocalDocumentCopy copy) async {
    final paths = await _paths(name, createDirectory: false);
    final file = switch (copy) {
      LocalDocumentCopy.primary => paths.primary,
      LocalDocumentCopy.backup => paths.backup,
    };
    if (!await file.exists()) return null;
    final length = await file.length();
    if (length <= 0 || length > _maximumBytes) {
      throw AtomicLocalDocumentException(
        code: 'document_size_invalid',
        cause: StateError('Document byte length: $length'),
        stackTrace: StackTrace.current,
      );
    }
    return file.readAsString();
  }

  Future<void> write(String name, String document) {
    final operation = _writeTail.then((_) => _write(name, document));
    _writeTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> _write(String name, String document) async {
    final bytes = utf8.encode(document);
    if (bytes.isEmpty || bytes.length > _maximumBytes) {
      throw AtomicLocalDocumentException(
        code: 'document_size_invalid',
        cause: StateError('Document byte length: ${bytes.length}'),
        stackTrace: StackTrace.current,
      );
    }
    final paths = await _paths(name, createDirectory: true);
    final temp = File(
      '${paths.primary.path}.tmp.${DateTime.now().microsecondsSinceEpoch}',
    );
    try {
      await temp.writeAsBytes(bytes, flush: true);
      if (await paths.primary.exists()) {
        if (await paths.backup.exists()) await paths.backup.delete();
        await paths.primary.rename(paths.backup.path);
      }
      try {
        await temp.rename(paths.primary.path);
      } on Object {
        if (!await paths.primary.exists() && await paths.backup.exists()) {
          await paths.backup.rename(paths.primary.path);
        }
        rethrow;
      }
    } finally {
      if (await temp.exists()) await temp.delete();
    }
  }

  Future<({File primary, File backup})> _paths(
    String name, {
    required bool createDirectory,
  }) async {
    final root = await _rootDirectory();
    final directory = Directory.fromUri(root.uri.resolve('$_directoryName/'));
    if (createDirectory) await directory.create(recursive: true);
    final primary = File.fromUri(directory.uri.resolve('$name.json'));
    return (primary: primary, backup: File('${primary.path}.backup'));
  }
}

final class AtomicLocalDocumentException implements Exception {
  const AtomicLocalDocumentException({
    required this.code,
    required this.cause,
    required this.stackTrace,
  });

  final String code;
  final Object cause;
  final StackTrace stackTrace;
}
