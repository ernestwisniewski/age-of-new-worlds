import 'dart:convert';
import 'dart:io';

import 'sprite_partition_source.dart';
import 'sprite_partition_writer.dart';

const _partitionedAtlases = {
  'cities',
  'improvements_1',
  'improvements_2',
  'improvements_3',
  'improvements_4',
};

/// Builds into a fresh directory, preserving all other atlases and frame IDs.
Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    throw ArgumentError('Usage: partition_static_sprites.dart SOURCE OUTPUT');
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
          as Map<String, dynamic>;
  if (manifest['version'] != 1)
    throw StateError('Unsupported sprite manifest.');
  final atlases = Map<String, dynamic>.from(manifest['atlases'] as Map);
  final frames = Map<String, dynamic>.from(manifest['frames'] as Map);
  final partitions = _partitions(source, atlases, frames);
  final scratch = await Directory.systemTemp.createTemp(
    'aonw-sprite-partition-',
  );
  try {
    await output.create(recursive: true);
    await _copyUnchanged(source, output);
    final writer = SpritePartitionWriter(output: output, scratch: scratch);
    for (final entry in partitions.entries) {
      await writer.write(entry.key, entry.value);
      atlases[entry.key] =
          'assets/runtime/sprites/${entry.key}/${entry.key}.atlas';
    }
    for (final old in _partitionedAtlases) {
      atlases.remove(old);
    }
    manifest['atlases'] = Map.fromEntries(
      atlases.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    manifest['frames'] = frames;
    await File('${output.path}/sprite_manifest.json').writeAsString(
      '${const JsonEncoder.withIndent('  ').convert(manifest)}\n',
    );
    stdout.writeln(
      'Partitioned ${partitions.values.expand((v) => v).length} '
      'frames into ${partitions.length} atlases without resizing.',
    );
  } finally {
    await scratch.delete(recursive: true);
  }
}

Map<String, List<SpritePartitionRegion>> _partitions(
  Directory source,
  Map<String, dynamic> atlases,
  Map<String, dynamic> frames,
) {
  final groups = <String, List<SpritePartitionRegion>>{};
  for (final atlasId in _partitionedAtlases) {
    final path = 'assets/runtime/sprites/$atlasId/$atlasId.atlas';
    if (atlases[atlasId] != path) {
      throw StateError('Source atlas $atlasId does not match its contract.');
    }
    final regions = readPartitionRegions(
      File('${source.path}/$atlasId/$atlasId.atlas'),
    );
    for (final region in regions) {
      final frame = Map<String, dynamic>.from(frames[region.name] as Map);
      if (frame['atlas'] != atlasId ||
          frame['region'] != region.name ||
          frame['index'] != region.index) {
        throw StateError('Manifest/region mismatch: ${region.name}');
      }
      final group = _partitionId(atlasId, region.name);
      (groups[group] ??= []).add(region);
      frame['atlas'] = group;
      frames[region.name] = frame;
    }
    if (frames.values.any((frame) => (frame as Map)['atlas'] == atlasId)) {
      throw StateError('The atlas is missing declared frames: $atlasId');
    }
  }
  return groups;
}

String _partitionId(String atlas, String region) {
  final level = int.parse(region.split('.').last);
  final city = atlas == 'cities';
  if (level < 0 ||
      level >= (city ? 6 : 4) ||
      !region.startsWith(city ? 'city.' : 'improvement.')) {
    throw StateError('Unsupported frame: $region');
  }
  if (city) {
    final profile = region.split('.')[1];
    if (!const {
      'growthCivic',
      'tradeKnowledgeMaritime',
      'militaryFortified',
      'industryModern',
    }.contains(profile)) {
      throw StateError('Unsupported city profile: $profile');
    }
    return 'cities_${profile}_level_$level';
  }
  return '${atlas}_era_$level';
}

Future<void> _copyUnchanged(Directory source, Directory output) async {
  await for (final entity in source.list(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    final relative = entity.path.substring(source.path.length + 1);
    if (_partitionedAtlases.contains(relative.split('/').first) ||
        relative == 'sprite_manifest.json')
      continue;
    final destination = File('${output.path}/$relative');
    await destination.parent.create(recursive: true);
    await entity.copy(destination.path);
  }
}
