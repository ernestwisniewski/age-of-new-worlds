import 'dart:convert';
import 'dart:io';

part 'auto_trim_models.dart';

const _alphaThreshold = '1%';
const _segmentationThresholds = ['1%', '5%', '10%', '20%', '30%'];
const _secondaryAreaRatio = 0.005;
const _minimumSecondaryArea = 8;
const _workerCount = 8;

final _atlasJsonPattern = RegExp(r'^([0-9]+)\.json$');
final _geometryPattern = RegExp(
  r'^([0-9]+) ([0-9]+) ([+-]?[0-9]+) ([+-]?[0-9]+)$',
);
final _componentPattern = RegExp(
  r'^\s*[0-9]+: ([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+) '
  r'[^ ]+ ([0-9]+) (.+)$',
);

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    stdout.writeln(
      'Usage: dart run assets/ui/auto_trim_coordinates.dart [--check]\n'
      '\n'
      'Without --check, rewrites FreeTexturePacker JSON coordinates in place.\n'
      'With --check, exits non-zero when any coordinate is not tightly trimmed.',
    );
    return;
  }
  final unknown = arguments.where((argument) => argument != '--check');
  if (unknown.isNotEmpty) {
    stderr.writeln('Unknown arguments: ${unknown.join(' ')}');
    exitCode = 64;
    return;
  }

  await _synchronizeAtlasCoordinates(arguments.contains('--check'));
}

Future<void> _synchronizeAtlasCoordinates(bool checkOnly) async {
  final uiDirectory = File.fromUri(Platform.script).absolute.parent;
  final atlases = await _loadAtlases(uiDirectory);
  final regions = atlases.values.expand((atlas) => atlas.regions).toList();
  if (regions.isEmpty) {
    throw const FormatException('No FreeTexturePacker JSON frames were found.');
  }

  final trimmed = <_Region>[];
  for (var start = 0; start < regions.length; start += _workerCount) {
    final end = (start + _workerCount).clamp(0, regions.length);
    trimmed.addAll(
      await Future.wait(
        regions.sublist(start, end).map((region) => _trim(uiDirectory, region)),
      ),
    );
  }

  final changed = <(_Region, _Region)>[];
  for (var index = 0; index < regions.length; index++) {
    final before = regions[index];
    final after = trimmed[index];
    if (!before.hasSameBounds(after)) changed.add((before, after));
    atlases[after.sheet]!.update(after);
  }

  final changedDocuments = <(_AtlasDocument, String)>[];
  for (final atlas in atlases.values) {
    final encoded = atlas.encode();
    if (encoded != atlas.source) changedDocuments.add((atlas, encoded));
  }

  if (changedDocuments.isEmpty) {
    stdout.writeln(
      'All ${regions.length} UI regions are already pixel-tight at alpha '
      'threshold $_alphaThreshold and their JSON metadata is canonical.',
    );
    return;
  }

  if (checkOnly) {
    stderr.writeln(
      '${changed.length} of ${regions.length} UI regions require trimming:',
    );
    for (final (before, after) in changed.take(20)) {
      stderr.writeln(
        '  ${before.sheet}/${before.id}: '
        '${before.bounds} -> ${after.bounds}',
      );
    }
    if (changed.length > 20) {
      stderr.writeln('  ...and ${changed.length - 20} more');
    }
    final metadataOnly = changedDocuments
        .map((entry) => entry.$1.sheet)
        .where((sheet) => !changed.any((entry) => entry.$1.sheet == sheet))
        .toList();
    if (metadataOnly.isNotEmpty) {
      stderr.writeln(
        '  JSON metadata also requires normalization: '
        '${metadataOnly.join(', ')}',
      );
    }
    exitCode = 1;
    return;
  }

  for (final (atlas, encoded) in changedDocuments) {
    await _writeAtomically(atlas.file, encoded);
  }
  stdout.writeln(
    'Updated ${changedDocuments.length} FreeTexturePacker JSON files; trimmed '
    '${changed.length} of ${regions.length} UI regions at alpha threshold '
    '$_alphaThreshold.',
  );
}

Future<Map<String, _AtlasDocument>> _loadAtlases(Directory directory) async {
  final files = await directory
      .list()
      .where(
        (entity) =>
            entity is File &&
            _atlasJsonPattern.hasMatch(entity.uri.pathSegments.last),
      )
      .cast<File>()
      .toList();
  files.sort(
    (left, right) => _sheetNumber(left).compareTo(_sheetNumber(right)),
  );

  final atlases = <String, _AtlasDocument>{};
  for (final file in files) {
    final sheet = _sheetNumber(file).toString();
    atlases[sheet] = await _AtlasDocument.load(file, sheet);
  }
  return atlases;
}

int _sheetNumber(File file) {
  return int.parse(
    _atlasJsonPattern.firstMatch(file.uri.pathSegments.last)!.group(1)!,
  );
}

Future<void> _writeAtomically(File output, String contents) async {
  final temporary = File('${output.path}.cropper.tmp');
  await temporary.writeAsString(contents, flush: true);
  try {
    await temporary.rename(output.path);
  } finally {
    if (await temporary.exists()) await temporary.delete();
  }
}

Future<_Region> _trim(Directory uiDirectory, _Region region) async {
  final atlas = File('${uiDirectory.path}/${region.sheet}.webp');
  if (!await atlas.exists()) {
    throw FileSystemException('Missing atlas sheet', atlas.path);
  }
  final cell = await _segmentationCell(atlas, region);
  return _trimCell(atlas, region, cell);
}

Future<_Cell> _segmentationCell(File atlas, _Region region) async {
  var result = _Cell.full(region);
  for (final threshold in _segmentationThresholds) {
    final components = await _foregroundComponents(atlas, region, threshold);
    if (components.isEmpty) continue;
    final main = components.first;
    final minimumArea = (main.area * _secondaryAreaRatio).round().clamp(
      _minimumSecondaryArea,
      main.area,
    );
    final secondary = components
        .skip(1)
        .where((component) => component.area >= minimumArea)
        .toList();
    if (secondary.isEmpty || !_isInset(main, region)) continue;
    final cell = _cellSeparating(main, secondary, region);
    if (cell.isConstrained(region)) result = result.intersect(cell);
  }
  return result;
}

Future<List<_Component>> _foregroundComponents(
  File atlas,
  _Region region,
  String threshold,
) async {
  final result = await Process.run('magick', [
    atlas.path,
    '-crop',
    '${region.width}x${region.height}+${region.x}+${region.y}',
    '+repage',
    '-alpha',
    'extract',
    '-threshold',
    threshold,
    '-define',
    'connected-components:verbose=true',
    '-connected-components',
    '8',
    'null:',
  ]);
  if (result.exitCode != 0) {
    throw ProcessException(
      'magick',
      const [],
      '${result.stdout}\n${result.stderr}',
      result.exitCode,
    );
  }
  final components = <_Component>[];
  for (final line in (result.stdout as String).split('\n')) {
    final match = _componentPattern.firstMatch(line);
    if (match == null) continue;
    final color = match.group(6)!;
    if (!color.contains('(255,255,255)') &&
        !color.contains('gray(255)') &&
        color.trim() != 'white') {
      continue;
    }
    components.add(
      _Component(
        x: int.parse(match.group(3)!),
        y: int.parse(match.group(4)!),
        width: int.parse(match.group(1)!),
        height: int.parse(match.group(2)!),
        area: int.parse(match.group(5)!),
      ),
    );
  }
  components.sort((left, right) => right.area.compareTo(left.area));
  return components;
}

bool _isInset(_Component component, _Region region) {
  return (region.x == 0 || component.x > 0) &&
      (region.y == 0 || component.y > 0) &&
      (region.x + region.width == 1254 || component.right < region.width) &&
      (region.y + region.height == 1254 || component.bottom < region.height);
}

_Cell _cellSeparating(
  _Component main,
  List<_Component> secondary,
  _Region region,
) {
  var left = 0;
  var top = 0;
  var right = region.width;
  var bottom = region.height;
  for (final component in secondary) {
    switch (_separationSide(main, component)) {
      case _SeparationSide.left:
        left = _max(left, (component.right + main.x) ~/ 2);
      case _SeparationSide.right:
        right = _min(right, (main.right + component.x + 1) ~/ 2);
      case _SeparationSide.above:
        top = _max(top, (component.bottom + main.y) ~/ 2);
      case _SeparationSide.below:
        bottom = _min(bottom, (main.bottom + component.y + 1) ~/ 2);
      case _SeparationSide.none:
        break;
    }
  }
  return _Cell(left: left, top: top, right: right, bottom: bottom);
}

_SeparationSide _separationSide(_Component main, _Component component) {
  final horizontal = _horizontalSide(main, component);
  final vertical = _verticalSide(main, component);
  if (vertical == _VerticalSide.overlap) return horizontal.separation;
  if (horizontal == _HorizontalSide.overlap) return vertical.separation;
  if (horizontal == _HorizontalSide.intersecting ||
      vertical == _VerticalSide.intersecting) {
    return _SeparationSide.none;
  }

  final horizontalGap = horizontal == _HorizontalSide.left
      ? main.x - component.right
      : component.x - main.right;
  final verticalGap = vertical == _VerticalSide.above
      ? main.y - component.bottom
      : component.y - main.bottom;
  if (horizontalGap <= verticalGap) {
    return horizontal.separation;
  }
  return vertical.separation;
}

enum _SeparationSide { left, right, above, below, none }

_HorizontalSide _horizontalSide(_Component main, _Component component) {
  if (component.right <= main.x) return _HorizontalSide.left;
  if (component.x >= main.right) return _HorizontalSide.right;
  if (component.x < main.right && component.right > main.x) {
    return _HorizontalSide.overlap;
  }
  return _HorizontalSide.intersecting;
}

enum _HorizontalSide {
  left,
  right,
  overlap,
  intersecting;

  _SeparationSide get separation => switch (this) {
    left => _SeparationSide.left,
    right => _SeparationSide.right,
    overlap || intersecting => _SeparationSide.none,
  };
}

_VerticalSide _verticalSide(_Component main, _Component component) {
  if (component.bottom <= main.y) return _VerticalSide.above;
  if (component.y >= main.bottom) return _VerticalSide.below;
  if (component.y < main.bottom && component.bottom > main.y) {
    return _VerticalSide.overlap;
  }
  return _VerticalSide.intersecting;
}

enum _VerticalSide {
  above,
  below,
  overlap,
  intersecting;

  _SeparationSide get separation => switch (this) {
    above => _SeparationSide.above,
    below => _SeparationSide.below,
    overlap || intersecting => _SeparationSide.none,
  };
}

Future<_Region> _trimCell(File atlas, _Region region, _Cell cell) async {
  final result = await Process.run('magick', [
    atlas.path,
    '-crop',
    '${cell.width}x${cell.height}+'
        '${region.x + cell.left}+${region.y + cell.top}',
    '+repage',
    '-alpha',
    'extract',
    '-threshold',
    _alphaThreshold,
    '-bordercolor',
    'black',
    '-border',
    '1',
    '-trim',
    '-format',
    '%w %h %X %Y',
    'info:',
  ]);
  if (result.exitCode != 0) {
    throw ProcessException(
      'magick',
      const [],
      '${result.stdout}\n${result.stderr}',
      result.exitCode,
    );
  }
  final geometry = _geometryPattern.firstMatch(
    (result.stdout as String).trim(),
  );
  if (geometry == null) {
    throw FormatException(
      'Cannot parse ImageMagick geometry for '
      '${region.sheet}/${region.id}: ${result.stdout}',
    );
  }
  final width = int.parse(geometry.group(1)!);
  final height = int.parse(geometry.group(2)!);
  final rawLocalX = int.parse(geometry.group(3)!);
  final rawLocalY = int.parse(geometry.group(4)!);
  if (width == 1 && height == 1 && rawLocalX == -1 && rawLocalY == -1) {
    throw StateError(
      '${region.sheet}/${region.id} has no pixels above alpha threshold '
      '$_alphaThreshold.',
    );
  }
  final localX = rawLocalX - 1;
  final localY = rawLocalY - 1;
  return region.withBounds(
    x: region.x + cell.left + localX,
    y: region.y + cell.top + localY,
    width: width,
    height: height,
  );
}

int _min(int left, int right) => left < right ? left : right;
int _max(int left, int right) => left > right ? left : right;
