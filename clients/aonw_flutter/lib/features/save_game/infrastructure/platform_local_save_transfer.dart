import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';

import '../application/local_save_store.dart';
import '../application/local_save_transfer.dart';

final class PlatformLocalSaveTransfer implements LocalSaveTransferPort {
  const PlatformLocalSaveTransfer();

  static const _saveTypes = <XTypeGroup>[
    XTypeGroup(
      label: 'AoNW save',
      extensions: ['aonwsave', 'json'],
      mimeTypes: ['application/json'],
      uniformTypeIdentifiers: ['public.json'],
    ),
  ];

  @override
  Future<LocalSavePickedDocumentView?> pickSaveDocument() async {
    try {
      final file = await openFile(acceptedTypeGroups: _saveTypes);
      if (file == null) return null;
      if (await file.length() > maxLocalSaveDocumentBytes) {
        throw const LocalSaveTransferException(
          code: 'save_transfer_size_invalid',
          message: 'The selected save document is too large.',
        );
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > maxLocalSaveDocumentBytes) {
        throw const LocalSaveTransferException(
          code: 'save_transfer_size_invalid',
          message: 'The selected save document is too large.',
        );
      }
      return LocalSavePickedDocumentView(
        document: utf8.decode(bytes, allowMalformed: false),
        name: _saveName(file.name),
      );
    } on LocalSaveTransferException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw LocalSaveTransferException(
        code: 'save_transfer_read_failed',
        message: 'The selected save document could not be read.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }

  @override
  Future<LocalSaveExportDisposition> exportSaveDocument({
    required String suggestedName,
    required String document,
  }) async {
    final bytes = Uint8List.fromList(utf8.encode(document));
    if (bytes.length > maxLocalSaveDocumentBytes) {
      throw const LocalSaveTransferException(
        code: 'save_transfer_size_invalid',
        message: 'The save document is too large to export.',
      );
    }
    try {
      final file = XFile.fromData(
        bytes,
        mimeType: 'application/json',
        name: suggestedName,
      );
      if (_usesSaveDialog) {
        final location = await getSaveLocation(
          acceptedTypeGroups: _saveTypes,
          suggestedName: suggestedName,
        );
        if (location == null) return LocalSaveExportDisposition.cancelled;
        await file.saveTo(location.path);
        return LocalSaveExportDisposition.completed;
      }
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [file],
          fileNameOverrides: [suggestedName],
          title: 'AoNW save',
        ),
      );
      return result.status == ShareResultStatus.dismissed
          ? LocalSaveExportDisposition.cancelled
          : LocalSaveExportDisposition.completed;
    } on Object catch (error, stackTrace) {
      throw LocalSaveTransferException(
        code: 'save_transfer_export_failed',
        message: 'The save document could not be exported.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }

  bool get _usesSaveDialog =>
      !kIsWeb &&
      switch (defaultTargetPlatform) {
        TargetPlatform.linux ||
        TargetPlatform.macOS ||
        TargetPlatform.windows => true,
        _ => false,
      };
}

String? _saveName(String fileName) {
  final normalized = fileName.trim();
  if (normalized.isEmpty) return null;
  final dot = normalized.lastIndexOf('.');
  return dot <= 0 ? normalized : normalized.substring(0, dot);
}
