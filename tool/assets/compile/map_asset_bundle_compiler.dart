import 'dart:io';

import 'map_asset_bundle_manifest.dart';
import 'map_atlas_builder.dart';
import 'map_page_writer.dart';
import 'map_texture_geometry.dart';

final class MapAssetBundleCompiler {
  const MapAssetBundleCompiler({
    required this.spec,
    required this.source,
    required this.output,
    this.mapDocument,
  });

  final MapAssetBundleSpec spec;
  final MapTileImageSource source;
  final Directory output;
  final File? mapDocument;

  Future<MapAssetBundleManifest> compile() async {
    if (await output.exists()) await output.delete(recursive: true);
    await output.create(recursive: true);
    final build = await MapAtlasBuilder(
      columns: spec.cols,
      rows: spec.rows,
      source: source,
    ).build();
    final pages = await MapPageWriter(
      mapId: spec.mapId,
      output: output,
    ).write(build);
    final manifest = MapAssetBundleManifest(
      mapId: spec.mapId,
      mapContentHash: spec.mapContentHash,
      cols: spec.cols,
      rows: spec.rows,
      worldWidth: build.worldWidth,
      worldHeight: build.worldHeight,
      compiledScale: build.scale,
      filterQuality: 'medium',
      pageSizeLimit: mapPageSize,
      gutter: mapPageGutter,
      pages: pages,
      averageColors: build.averageColors,
    );
    await File(
      '${output.path}/$mapAssetBundleManifestName',
    ).writeAsString(manifest.encode(), flush: true);
    final document = mapDocument;
    if (document != null) {
      await document.copy('${output.path}/map.json');
    }
    return manifest;
  }
}

final class MapAssetBundleSpec {
  const MapAssetBundleSpec({
    required this.mapId,
    required this.mapContentHash,
    required this.cols,
    required this.rows,
  });

  final String mapId;
  final String mapContentHash;
  final int cols;
  final int rows;
}
