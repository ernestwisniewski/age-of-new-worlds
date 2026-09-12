import 'dart:io';

/// Strict reader for the unrotated static atlas layout being partitioned.
final class SpritePartitionRegion {
  const SpritePartitionRegion({
    required this.name,
    required this.page,
    required this.bounds,
    required this.offsets,
    required this.index,
  });

  final String name;
  final String page;
  final List<int> bounds;
  final List<int> offsets;
  final int index;

  String descriptor(int left, int top) =>
      '$name\n'
      'bounds:${bounds[0] - left},${bounds[1] - top},'
      '${bounds[2]},${bounds[3]}\n'
      'offsets:${offsets.join(',')}\nindex:$index\n';
}

List<SpritePartitionRegion> readPartitionRegions(
  File atlas, {
  bool indexed = false,
}) {
  final regions = <SpritePartitionRegion>[];
  final pages = atlas.readAsStringSync().trim().split(RegExp(r'\n\s*\n'));
  for (final block in pages) {
    final lines = block.split('\n').map((line) => line.trim()).toList();
    if (lines.length < 9 || (lines.length - 5) % 4 != 0) {
      throw FormatException('Unsupported atlas layout: ${atlas.path}');
    }
    final pageName = lines.first;
    if (!RegExp(r'^[a-zA-Z0-9_]+\.webp$').hasMatch(pageName) ||
        lines[2] != 'format:RGBA8888' ||
        lines[3] != 'filter:Linear,Linear' ||
        lines[4] != 'repeat:none') {
      throw FormatException('Unsupported atlas page: ${atlas.path}');
    }
    final size = _integers(lines[1], 'size', 2);
    for (var index = 5; index < lines.length; index += 4) {
      final bounds = _integers(lines[index + 1], 'bounds', 4);
      final offsets = _integers(lines[index + 2], 'offsets', 4);
      final frameIndex = _integers(lines[index + 3], 'index', 1).single;
      if (indexed ? frameIndex < 0 : frameIndex != -1) {
        throw FormatException('Unsupported frame index: $frameIndex');
      }
      _validateRegion(lines[index], bounds, size);
      regions.add(
        SpritePartitionRegion(
          name: lines[index],
          page: '${atlas.parent.path}/$pageName',
          bounds: bounds,
          offsets: offsets,
          index: frameIndex,
        ),
      );
    }
  }
  if (regions.map((region) => (region.name, region.index)).toSet().length !=
      regions.length) {
    throw FormatException('Duplicate atlas region: ${atlas.path}');
  }
  return regions;
}

void _validateRegion(String name, List<int> bounds, List<int> size) {
  if (bounds[0] < 2 ||
      bounds[1] < 2 ||
      bounds[2] <= 0 ||
      bounds[3] <= 0 ||
      bounds[0] + bounds[2] + 2 > size[0] ||
      bounds[1] + bounds[3] + 2 > size[1]) {
    throw FormatException('Unsupported static region: $name');
  }
}

List<int> _integers(String line, String key, int count) {
  if (!line.startsWith('$key:')) throw FormatException('Expected $key');
  final values = line
      .substring(key.length + 1)
      .split(',')
      .map(int.parse)
      .toList();
  if (values.length != count) throw FormatException('Invalid $key');
  return values;
}
