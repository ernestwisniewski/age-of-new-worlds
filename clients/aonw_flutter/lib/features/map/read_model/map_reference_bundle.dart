import 'dart:typed_data';

final class MapReferencePage {
  MapReferencePage({
    required this.file,
    required Uint8List bytes,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.destination,
  }) : bytes = Uint8List.fromList(bytes);

  final String file;
  final Uint8List bytes;
  final int pixelWidth;
  final int pixelHeight;
  final ({double x, double y, double width, double height}) destination;
}

final class MapReferenceBundle {
  MapReferenceBundle({
    required this.mapId,
    required this.mapContentHash,
    required this.worldWidth,
    required this.worldHeight,
    required List<MapReferencePage> pages,
  }) : pages = List.unmodifiable(pages);

  final String mapId;
  final String mapContentHash;
  final double worldWidth;
  final double worldHeight;
  final List<MapReferencePage> pages;
}
