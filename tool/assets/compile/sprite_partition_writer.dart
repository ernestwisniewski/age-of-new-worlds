import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'sprite_partition_source.dart';

/// Crops complete rows/columns including their original two-pixel extrusion.
final class SpritePartitionWriter {
  SpritePartitionWriter({required this.output, required this.scratch});

  final Directory output;
  final Directory scratch;
  final _pages = <String, img.Image>{};

  Future<void> write(String id, List<SpritePartitionRegion> regions) async {
    final pagePaths = regions.map((region) => region.page).toSet();
    if (pagePaths.length != 1) {
      throw StateError('Partition $id must come from one source page.');
    }
    final page = await _decode(pagePaths.single);
    final left = regions.map((region) => region.bounds[0]).reduce(math.min) - 2;
    final top = regions.map((region) => region.bounds[1]).reduce(math.min) - 2;
    final right =
        regions.map((r) => r.bounds[0] + r.bounds[2]).reduce(math.max) + 2;
    final bottom =
        regions.map((r) => r.bounds[1] + r.bounds[3]).reduce(math.max) + 2;
    if (left < 0 ||
        top < 0 ||
        right > page.width ||
        bottom > page.height ||
        right - left > 2048 ||
        bottom - top > 2048) {
      throw StateError('Partition $id exceeds the source or page bounds.');
    }
    final crop = img.copyCrop(
      page,
      x: left,
      y: top,
      width: right - left,
      height: bottom - top,
    );
    final png = File('${scratch.path}/$id.png');
    await png.writeAsBytes(img.encodePng(crop));
    final directory = Directory('${output.path}/$id');
    await directory.create();
    await runSpriteCodec('cwebp', [
      '-quiet',
      '-lossless',
      '-exact',
      '-q',
      '100',
      '-m',
      '6',
      png.path,
      '-o',
      '${directory.path}/${id}_0.webp',
    ]);
    final descriptor = StringBuffer(
      '${id}_0.webp\n'
      'size:${crop.width},${crop.height}\n'
      'format:RGBA8888\nfilter:Linear,Linear\nrepeat:none\n',
    );
    for (final region in regions) {
      descriptor.write(region.descriptor(left, top));
    }
    await File(
      '${directory.path}/$id.atlas',
    ).writeAsString(descriptor.toString());
  }

  Future<img.Image> _decode(String path) async {
    final cached = _pages[path];
    if (cached != null) return cached;
    final png = File('${scratch.path}/source_${_pages.length}.png');
    await runSpriteCodec('dwebp', ['-quiet', path, '-o', png.path]);
    final image = img.decodePng(await png.readAsBytes());
    if (image == null) throw StateError('Cannot decode $path');
    return _pages[path] = image;
  }
}

Future<void> verifySpriteCodecs() async {
  for (final executable in ['cwebp', 'dwebp']) {
    final version = await runSpriteCodec(executable, ['-version']);
    if (version.trim().split('\n').first != '1.6.0') {
      throw StateError('$executable 1.6.0 is required.');
    }
  }
}

Future<String> runSpriteCodec(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments);
  if (result.exitCode != 0) {
    throw StateError('$executable failed: ${result.stderr}');
  }
  return result.stdout as String;
}
