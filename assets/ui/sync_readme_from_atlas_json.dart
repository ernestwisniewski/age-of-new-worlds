import 'dart:convert';
import 'dart:io';

final _atlasJsonPattern = RegExp(r'^([0-9]+)\.json$');
final _sheetPattern = RegExp(r'^## Sheet ([0-9]+)$');
final _regionPattern = RegExp(
  r'^\| `([^`]+)` \| ([0-9]+) \| ([0-9]+) \| ([0-9]+) \| ([0-9]+) \|(?: ([^|]*?) \|)?$',
);

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    stdout.writeln(
      'Usage: dart run assets/ui/sync_readme_from_atlas_json.dart [--check]\n'
      '\n'
      'Without --check, mirrors FreeTexturePacker JSON coordinates to README.\n'
      'With --check, exits non-zero when the README mirror is out of date.',
    );
    return;
  }
  final unknown = arguments.where((argument) => argument != '--check');
  if (unknown.isNotEmpty) {
    stderr.writeln('Unknown arguments: ${unknown.join(' ')}');
    exitCode = 64;
    return;
  }

  await _synchronizeReadme(arguments.contains('--check'));
}

Future<void> _synchronizeReadme(bool checkOnly) async {
  final uiDirectory = File.fromUri(Platform.script).absolute.parent;
  final boundsBySheet = await _loadBounds(uiDirectory);
  final expectedFrames = boundsBySheet.values.fold<int>(
    0,
    (sum, frames) => sum + frames.length,
  );
  if (expectedFrames == 0) {
    throw const FormatException(
      'No frames found in FreeTexturePacker JSON files.',
    );
  }

  final readme = File('${uiDirectory.path}/README.md');
  final source = await readme.readAsString();
  final trailingNewline = source.endsWith('\n');
  final lines = source.split('\n');
  if (trailingNewline) lines.removeLast();

  final seen = _mirrorRows(lines, boundsBySheet);
  final missing = _missingFrames(boundsBySheet, seen);
  if (missing.isNotEmpty) {
    throw FormatException(
      '${missing.length} JSON frames are missing from README: '
      '${missing.take(20).join(', ')}',
    );
  }

  final updated = '${lines.join('\n')}${trailingNewline ? '\n' : ''}';
  if (updated == source) {
    stdout.writeln(
      'README mirrors all $expectedFrames FreeTexturePacker JSON frames.',
    );
    return;
  }
  if (checkOnly) {
    stderr.writeln(
      'README coordinates are out of sync with FreeTexturePacker JSON.',
    );
    exitCode = 1;
    return;
  }

  await _writeAtomically(readme, updated);
  stdout.writeln(
    'Mirrored $expectedFrames FreeTexturePacker JSON frames to README.md.',
  );
}

Set<String> _mirrorRows(
  List<String> lines,
  Map<String, Map<String, _Bounds>> boundsBySheet,
) {
  final seen = <String>{};
  String? sheet;
  for (var index = 0; index < lines.length; index++) {
    final sheetMatch = _sheetPattern.firstMatch(lines[index]);
    if (sheetMatch != null) {
      sheet = sheetMatch.group(1)!;
      continue;
    }
    final regionMatch = _regionPattern.firstMatch(lines[index]);
    if (regionMatch == null) continue;
    if (sheet == null) {
      throw const FormatException('Region row appears before a sheet heading.');
    }
    final id = regionMatch.group(1)!;
    final bounds = boundsBySheet[sheet]?[id];
    if (bounds == null) {
      throw FormatException('README frame is absent from JSON: $sheet/$id');
    }
    final key = '$sheet/$id';
    if (!seen.add(key)) throw FormatException('Duplicate README frame: $key');
    lines[index] = bounds.markdownRow(id, regionMatch.group(6)?.trim());
  }
  return seen;
}

List<String> _missingFrames(
  Map<String, Map<String, _Bounds>> boundsBySheet,
  Set<String> seen,
) {
  return <String>[
    for (final sheetEntry in boundsBySheet.entries)
      for (final id in sheetEntry.value.keys)
        if (!seen.contains('${sheetEntry.key}/$id')) '${sheetEntry.key}/$id',
  ];
}

Future<void> _writeAtomically(File readme, String updated) async {
  final temporary = File('${readme.path}.atlas-json.tmp');
  await temporary.writeAsString(updated, flush: true);
  try {
    await temporary.rename(readme.path);
  } finally {
    if (await temporary.exists()) await temporary.delete();
  }
}

Future<Map<String, Map<String, _Bounds>>> _loadBounds(
  Directory uiDirectory,
) async {
  final files = await uiDirectory
      .list()
      .where((entity) {
        return entity is File &&
            _atlasJsonPattern.hasMatch(entity.uri.pathSegments.last);
      })
      .cast<File>()
      .toList();
  files.sort((left, right) => left.path.compareTo(right.path));

  final result = <String, Map<String, _Bounds>>{};
  for (final file in files) {
    final sheet = _atlasJsonPattern
        .firstMatch(file.uri.pathSegments.last)!
        .group(1)!;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> ||
        decoded['frames'] is! Map<String, dynamic>) {
      throw FormatException('${file.path} has no frames object.');
    }
    final frames = decoded['frames'] as Map<String, dynamic>;
    final sheetBounds = <String, _Bounds>{};
    for (final entry in frames.entries) {
      if (!entry.key.endsWith('.webp') ||
          entry.value is! Map<String, dynamic>) {
        throw FormatException('${file.path} has invalid frame ${entry.key}.');
      }
      final frame = entry.value as Map<String, dynamic>;
      final bounds = frame['frame'];
      if (bounds is! Map<String, dynamic>) {
        throw FormatException('${file.path} frame ${entry.key} has no bounds.');
      }
      final id = entry.key.substring(0, entry.key.length - '.webp'.length);
      sheetBounds[id] = _Bounds(
        x: _readInt(bounds, 'x', file, entry.key),
        y: _readInt(bounds, 'y', file, entry.key),
        width: _readInt(bounds, 'w', file, entry.key),
        height: _readInt(bounds, 'h', file, entry.key),
      );
    }
    result[sheet] = sheetBounds;
  }
  return result;
}

int _readInt(Map<String, dynamic> values, String key, File file, String frame) {
  final value = values[key];
  if (value is int) return value;
  throw FormatException('${file.path} frame $frame has invalid $key: $value');
}

final class _Bounds {
  const _Bounds({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  String markdownRow(String id, String? tags) {
    final tagColumn = tags == null || tags.isEmpty ? '' : ' $tags |';
    return '| `$id` | $x | $y | $width | $height |$tagColumn';
  }
}
