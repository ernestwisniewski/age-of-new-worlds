import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;

import 'map_asset_bundle_manifest.dart';
import 'map_atlas_builder.dart';
import 'map_texture_geometry.dart';

const String mapRuntimeRoot = 'assets/runtime/maps';

final class MapPageWriter {
  const MapPageWriter({required this.mapId, required this.output});

  final String mapId;
  final Directory output;

  Future<List<MapAssetBundlePage>> write(MapAtlasBuild build) async {
    await output.create(recursive: true);
    final pages = <MapAssetBundlePage>[];
    var pageIndex = 0;
    for (
      var coreTop = 0;
      coreTop < build.image.height;
      coreTop += mapPageCoreSize
    ) {
      for (
        var coreLeft = 0;
        coreLeft < build.image.width;
        coreLeft += mapPageCoreSize
      ) {
        final page = _createPage(build.image, coreLeft, coreTop);
        final name = 'page_${pageIndex.toString().padLeft(2, '0')}.jpg';
        final bytes = img.encodeJpg(page.image, quality: 92);
        await File('${output.path}/$name').writeAsBytes(bytes, flush: true);
        pages.add(
          _pageRecord(
            name,
            page,
            coreLeft,
            coreTop,
            build.scale,
            sha256.convert(bytes).toString(),
          ),
        );
        pageIndex++;
      }
    }
    return pages;
  }

  _MapPage _createPage(img.Image atlas, int coreLeft, int coreTop) {
    final coreWidth = math.min(mapPageCoreSize, atlas.width - coreLeft);
    final coreHeight = math.min(mapPageCoreSize, atlas.height - coreTop);
    final width = coreWidth + mapPageGutter * 2;
    final height = coreHeight + mapPageGutter * 2;
    final page = img.Image(width: width, height: height, numChannels: 3);
    for (var y = 0; y < height; y++) {
      final sourceY = (coreTop + y - mapPageGutter)
          .clamp(0, atlas.height - 1)
          .toInt();
      for (var x = 0; x < width; x++) {
        final sourceX = (coreLeft + x - mapPageGutter)
            .clamp(0, atlas.width - 1)
            .toInt();
        final pixel = atlas.getPixel(sourceX, sourceY);
        page.setPixelRgb(x, y, pixel.r, pixel.g, pixel.b);
      }
    }
    return _MapPage(image: page);
  }

  MapAssetBundlePage _pageRecord(
    String name,
    _MapPage page,
    int coreLeft,
    int coreTop,
    double scale,
    String sha256Digest,
  ) => MapAssetBundlePage(
    file: name,
    asset: '$mapRuntimeRoot/$mapId/$name',
    format: 'jpeg',
    sha256: sha256Digest,
    pixelWidth: page.image.width,
    pixelHeight: page.image.height,
    destination: [
      (coreLeft - mapPageGutter) / scale,
      (coreTop - mapPageGutter) / scale,
      page.image.width / scale,
      page.image.height / scale,
    ],
  );
}

final class _MapPage {
  const _MapPage({required this.image});

  final img.Image image;
}
