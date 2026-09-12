import 'dart:convert';
import 'dart:io';

import 'sprite_partition_source.dart';
import 'sprite_partition_writer.dart';
import 'unit_sprite_writer.dart';

/// Writes only unit atlases to a fresh output; never changes the source assets.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    throw ArgumentError('Usage: trim_unit_sprites.dart SOURCE OUTPUT');
  }
  final source = Directory(arguments[0]).absolute;
  final output = Directory(arguments[1]).absolute;
  if (!source.existsSync() ||
      output.existsSync() ||
      output.path.startsWith('${source.path}/')) {
    throw ArgumentError('Use an existing source and a fresh external output.');
  }
  await verifySpriteCodecs();
  final manifest =
      jsonDecode(
            await File('${source.path}/sprite_manifest.json').readAsString(),
          )
          as Map;
  if (manifest['version'] != 1)
    throw StateError('Unsupported sprite manifest.');
  final atlases = manifest['atlases'] as Map;
  final frames = manifest['frames'] as Map;
  final ids =
      atlases.keys.cast<String>().where((id) => id.startsWith('unit_')).toList()
        ..sort();
  if (ids.isEmpty) throw StateError('No unit atlases found.');
  final scratch = await Directory.systemTemp.createTemp('aonw-unit-sprites-');
  try {
    await output.create();
    for (final id in ids) {
      final expected = 'assets/runtime/sprites/$id/$id.atlas';
      if (!RegExp(r'^unit_[A-Za-z0-9]+$').hasMatch(id) ||
          atlases[id] != expected)
        throw StateError('Unexpected atlas path: $id');
      final regions = readPartitionRegions(
        File('${source.path}/$id/$id.atlas'),
        indexed: true,
      );
      _validateFrames(id, regions, frames);
      await writeTrimmedUnitAtlas(
        id,
        regions,
        output: output,
        scratch: scratch,
      );
    }
  } finally {
    await scratch.delete(recursive: true);
  }
}

void _validateFrames(
  String id,
  List<SpritePartitionRegion> regions,
  Map frames,
) {
  for (final region in regions) {
    final key = '${region.name}.${region.index}';
    final frame = frames[key];
    if (frame is! Map ||
        frame['atlas'] != id ||
        frame['region'] != region.name ||
        frame['index'] != region.index) {
      throw StateError('Manifest/region mismatch: $key');
    }
  }
  if (frames.values.where((frame) => (frame as Map)['atlas'] == id).length !=
      regions.length) {
    throw StateError('Atlas does not cover its declared unit frames: $id');
  }
}
