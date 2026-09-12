import 'dart:io';

import 'package:image/image.dart' as img;

import 'sprite_partition_source.dart';
import 'sprite_partition_writer.dart';
import 'unit_sprite_crop.dart';
import 'unit_sprite_packing.dart';

Future<void> writeTrimmedUnitAtlas(
  String id,
  List<SpritePartitionRegion> regions, {
  required Directory output,
  required Directory scratch,
}) async {
  final pages = regions.map((r) => r.page).toSet();
  if (pages.length != 1) throw StateError('Expected one unit source page: $id');
  final png = File('${scratch.path}/$id.png');
  await runSpriteCodec('dwebp', ['-quiet', pages.single, '-o', png.path]);
  final original = img.decodePng(await png.readAsBytes());
  if (original == null) throw StateError('Invalid unit page: $id');
  final packing = packUnitSprites([
    for (final region in regions) cropUnitSprite(original, region),
  ]);
  final page = img.Image(
    width: packing.width,
    height: packing.height,
    numChannels: 4,
  );
  final descriptor = StringBuffer(
    '${id}_0.webp\nsize:${page.width},${page.height}\n'
    'format:RGBA8888\nfilter:Linear,Linear\nrepeat:none\n',
  );
  for (final frame in packing.frames) {
    img.compositeImage(
      page,
      frame.crop.pixels,
      dstX: frame.x,
      dstY: frame.y,
      blend: img.BlendMode.direct,
    );
    descriptor.write(frame.crop.descriptor(frame.x, frame.y));
  }
  await png.writeAsBytes(img.encodePng(page));
  final destination = Directory('${output.path}/$id');
  await destination.create();
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
    '${destination.path}/${id}_0.webp',
  ]);
  await File(
    '${destination.path}/$id.atlas',
  ).writeAsString(descriptor.toString());
  stdout.writeln(
    '$id: ${original.width * original.height * 4} -> ${page.width * page.height * 4} decoded bytes',
  );
}
