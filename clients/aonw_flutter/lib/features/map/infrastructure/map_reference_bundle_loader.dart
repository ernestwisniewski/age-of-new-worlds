import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

import '../application/map_session_port.dart';
import '../read_model/map_reference_bundle.dart';
import '../read_model/map_view.dart';

final class MapReferenceBundleLoader {
  const MapReferenceBundleLoader(this.assets);

  static const _maximumDecodedPixels = 64 * 1024 * 1024;

  final AssetBundle assets;

  Future<MapReferenceBundle> load({
    required String manifestAsset,
    required MapView map,
  }) async {
    try {
      final bundle = _decodeBundle(await assets.loadString(manifestAsset), map);
      final directory = manifestAsset.substring(
        0,
        manifestAsset.lastIndexOf('/'),
      );
      final seenFiles = <String>{};
      final pages = [
        for (final page in bundle.pages)
          _decodePage(
            page,
            mapId: map.mapId,
            compiledScale: bundle.compiledScale,
            pageSizeLimit: bundle.pageSizeLimit,
            seenFiles: seenFiles,
          ),
      ];
      _verifyPageLayout(
        pages,
        worldWidth: bundle.worldWidth,
        worldHeight: bundle.worldHeight,
        compiledScale: bundle.compiledScale,
        gutter: bundle.gutter,
      );
      return MapReferenceBundle(
        mapId: map.mapId,
        mapContentHash: map.contentHash,
        worldWidth: bundle.worldWidth,
        worldHeight: bundle.worldHeight,
        pages: [
          for (final page in pages) await _loadPage(page, directory: directory),
        ],
      );
    } on MapLoadException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw MapLoadException(
        code: 'invalid_map_bundle',
        message: 'The map reference artwork could not be loaded.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    }
  }

  Future<MapReferencePage> _loadPage(
    _PageDescriptor page, {
    required String directory,
  }) async {
    final data = await assets.load('$directory/${page.file}');
    final bytes = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
    if (sha256.convert(bytes).toString() != page.expectedHash) {
      throw FormatException(
        'Map bundle page hash does not match: ${page.file}',
      );
    }
    await _verifyImageSize(
      bytes,
      width: page.pixelWidth,
      height: page.pixelHeight,
      file: page.file,
    );
    return MapReferencePage(
      file: page.file,
      bytes: bytes,
      pixelWidth: page.pixelWidth,
      pixelHeight: page.pixelHeight,
      destination: page.destination,
    );
  }

  static void _verifyIdentity(Map<String, Object?> root, MapView map) {
    if (root['gridLayout'] != 'oddQFlatTop') {
      throw const FormatException('Unsupported map bundle contract.');
    }
    if (root['mapId'] != map.mapId ||
        root['mapContentHash'] != map.contentHash ||
        root['cols'] != map.cols ||
        root['rows'] != map.rows) {
      throw const FormatException(
        'Map bundle identity does not match MapView.',
      );
    }
    _digest(root['mapContentHash'], 'map content hash');
  }

  static void _verifyWorldBounds(
    MapView map, {
    required double worldWidth,
    required double worldHeight,
  }) {
    const radius = 60.0;
    final expectedWidth = radius * 2 + (map.cols - 1) * 1.5 * radius;
    final expectedHeight =
        math.sqrt(3) * radius * (map.rows + (map.cols > 1 ? 0.5 : 0));
    if ((worldWidth - expectedWidth).abs() > 1e-6 ||
        (worldHeight - expectedHeight).abs() > 1e-6) {
      throw const FormatException(
        'Map bundle world bounds do not match MapView geometry.',
      );
    }
  }

  static Future<void> _verifyImageSize(
    Uint8List bytes, {
    required int width,
    required int height,
    required String file,
  }) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    try {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      try {
        if (descriptor.width != width || descriptor.height != height) {
          throw FormatException('Map bundle page size does not match: $file');
        }
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  }
}

typedef _BundleDescriptor = ({
  double worldWidth,
  double worldHeight,
  double compiledScale,
  int pageSizeLimit,
  int gutter,
  List<Object?> pages,
});

typedef _PageDescriptor = ({
  String file,
  String expectedHash,
  int pixelWidth,
  int pixelHeight,
  ({double x, double y, double width, double height}) destination,
});

_BundleDescriptor _decodeBundle(String source, MapView map) {
  final root = _object(jsonDecode(source), 'map asset bundle');
  _expectKeys(root, const {
    'mapId',
    'mapContentHash',
    'gridLayout',
    'cols',
    'rows',
    'worldWidth',
    'worldHeight',
    'compiledScale',
    'filterQuality',
    'pageSizeLimit',
    'gutter',
    'pages',
    'averageColors',
  });
  MapReferenceBundleLoader._verifyIdentity(root, map);
  final worldWidth = _positiveDouble(root['worldWidth'], 'world width');
  final worldHeight = _positiveDouble(root['worldHeight'], 'world height');
  MapReferenceBundleLoader._verifyWorldBounds(
    map,
    worldWidth: worldWidth,
    worldHeight: worldHeight,
  );
  final pages = _list(root['pages'], 'bundle pages');
  if (pages.isEmpty) throw const FormatException('Map bundle has no pages.');
  if (root['filterQuality'] != 'medium') {
    throw const FormatException('Map bundle filter quality is unsupported.');
  }
  _verifyAverageColors(root['averageColors'], map);
  return (
    worldWidth: worldWidth,
    worldHeight: worldHeight,
    compiledScale: _positiveDouble(root['compiledScale'], 'compiled scale'),
    pageSizeLimit: _positiveInt(root['pageSizeLimit'], 'page size limit'),
    gutter: _nonNegativeInt(root['gutter'], 'page gutter', maximum: 64),
    pages: pages,
  );
}

_PageDescriptor _decodePage(
  Object? value, {
  required String mapId,
  required double compiledScale,
  required int pageSizeLimit,
  required Set<String> seenFiles,
}) {
  final page = _object(value, 'bundle page');
  _expectKeys(page, const {
    'file',
    'asset',
    'format',
    'sha256',
    'pixelWidth',
    'pixelHeight',
    'destination',
  });
  final file = _pageFile(page['file']);
  _verifyPageIdentity(page, mapId: mapId, file: file, seenFiles: seenFiles);
  final width = _positiveInt(page['pixelWidth'], 'page width');
  final height = _positiveInt(page['pixelHeight'], 'page height');
  if (width > pageSizeLimit || height > pageSizeLimit) {
    throw FormatException('Map bundle page exceeds pageSizeLimit: $file');
  }
  return (
    file: file,
    expectedHash: _digest(page['sha256'], 'page digest'),
    pixelWidth: width,
    pixelHeight: height,
    destination: _decodeDestination(
      page['destination'],
      file: file,
      compiledScale: compiledScale,
      pixelWidth: width,
      pixelHeight: height,
    ),
  );
}

void _verifyAverageColors(Object? value, MapView map) {
  final colors = _object(value, 'average colors');
  if (colors.length != map.cols * map.rows) {
    throw const FormatException('Map bundle average colors are incomplete.');
  }
  for (var row = 0; row < map.rows; row++) {
    for (var col = 0; col < map.cols; col++) {
      final color = colors['$col,$row'];
      if (color is! int || color < 0 || color > 0xffffffff) {
        throw FormatException('Map bundle average color is invalid: $col,$row');
      }
    }
  }
}

void _verifyPageLayout(
  List<_PageDescriptor> pages, {
  required double worldWidth,
  required double worldHeight,
  required double compiledScale,
  required int gutter,
}) {
  final atlasWidth = (worldWidth * compiledScale).ceil();
  final atlasHeight = (worldHeight * compiledScale).ceil();
  var decodedPixels = 0;
  final rectangles = <({int left, int top, int right, int bottom})>[];
  for (final page in pages) {
    decodedPixels += page.pixelWidth * page.pixelHeight;
    if (decodedPixels > MapReferenceBundleLoader._maximumDecodedPixels) {
      throw const FormatException(
        'Map bundle decoded pixel budget is exceeded.',
      );
    }
    final left = (page.destination.x * compiledScale).round();
    final top = (page.destination.y * compiledScale).round();
    final right = left + page.pixelWidth;
    final bottom = top + page.pixelHeight;
    if (left < -gutter ||
        top < -gutter ||
        right > atlasWidth + gutter ||
        bottom > atlasHeight + gutter) {
      throw FormatException(
        'Map bundle page is outside the atlas: ${page.file}',
      );
    }
    rectangles.add((
      left: left.clamp(0, atlasWidth),
      top: top.clamp(0, atlasHeight),
      right: right.clamp(0, atlasWidth),
      bottom: bottom.clamp(0, atlasHeight),
    ));
  }
  _rejectExcessiveOverlap(rectangles, gutter);
  _requireCompleteCoverage(rectangles, atlasWidth, atlasHeight);
}

void _rejectExcessiveOverlap(
  List<({int left, int top, int right, int bottom})> rectangles,
  int gutter,
) {
  final allowed = gutter * 2;
  for (var first = 0; first < rectangles.length; first++) {
    for (var second = first + 1; second < rectangles.length; second++) {
      final left = math.max(rectangles[first].left, rectangles[second].left);
      final top = math.max(rectangles[first].top, rectangles[second].top);
      final right = math.min(rectangles[first].right, rectangles[second].right);
      final bottom = math.min(
        rectangles[first].bottom,
        rectangles[second].bottom,
      );
      if (right - left > allowed && bottom - top > allowed) {
        throw const FormatException('Map bundle pages overlap excessively.');
      }
    }
  }
}

void _requireCompleteCoverage(
  List<({int left, int top, int right, int bottom})> rectangles,
  int atlasWidth,
  int atlasHeight,
) {
  final xs = <int>{0, atlasWidth};
  final ys = <int>{0, atlasHeight};
  for (final rectangle in rectangles) {
    xs.addAll([rectangle.left, rectangle.right]);
    ys.addAll([rectangle.top, rectangle.bottom]);
  }
  final sortedX = xs.toList()..sort();
  final sortedY = ys.toList()..sort();
  for (var x = 0; x < sortedX.length - 1; x++) {
    for (var y = 0; y < sortedY.length - 1; y++) {
      final left = sortedX[x];
      final right = sortedX[x + 1];
      final top = sortedY[y];
      final bottom = sortedY[y + 1];
      if (left == right || top == bottom) continue;
      final covered = rectangles.any(
        (rectangle) =>
            rectangle.left <= left &&
            rectangle.right >= right &&
            rectangle.top <= top &&
            rectangle.bottom >= bottom,
      );
      if (!covered) {
        throw const FormatException('Map bundle page coverage has a gap.');
      }
    }
  }
}

void _verifyPageIdentity(
  Map<String, Object?> page, {
  required String mapId,
  required String file,
  required Set<String> seenFiles,
}) {
  if (!seenFiles.add(file)) {
    throw FormatException('Duplicate map bundle page: $file');
  }
  if (page['asset'] != 'assets/runtime/maps/$mapId/$file') {
    throw FormatException('Map bundle page has an invalid asset path: $file');
  }
  if (page['format'] != 'jpeg') {
    throw FormatException('Map bundle page is not JPEG: $file');
  }
}

({double x, double y, double width, double height}) _decodeDestination(
  Object? value, {
  required String file,
  required double compiledScale,
  required int pixelWidth,
  required int pixelHeight,
}) {
  final destination = _list(value, 'page destination');
  if (destination.length != 4) {
    throw FormatException('Map bundle page destination is invalid: $file');
  }
  final values = [
    for (final part in destination) _finiteDouble(part, 'page destination'),
  ];
  if (values[2] <= 0 || values[3] <= 0) {
    throw FormatException('Map bundle page destination is empty: $file');
  }
  if ((values[2] * compiledScale - pixelWidth).abs() > 0.01 ||
      (values[3] * compiledScale - pixelHeight).abs() > 0.01) {
    throw FormatException(
      'Map bundle page destination does not match its pixel size: $file',
    );
  }
  return (x: values[0], y: values[1], width: values[2], height: values[3]);
}

Map<String, Object?> _object(Object? value, String field) {
  if (value is! Map<String, Object?>) {
    throw FormatException('$field must be an object.');
  }
  return value;
}

List<Object?> _list(Object? value, String field) {
  if (value is! List<Object?>) {
    throw FormatException('$field must be an array.');
  }
  return value;
}

void _expectKeys(Map<String, Object?> value, Set<String> expected) {
  final actual = value.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw const FormatException('Map bundle contains unexpected fields.');
  }
}

String _pageFile(Object? value) {
  if (value is! String || !RegExp(r'^page_[0-9]+\.jpg$').hasMatch(value)) {
    throw const FormatException('Map bundle page name is unsafe.');
  }
  return value;
}

String _digest(Object? value, String field) {
  if (value is! String || !RegExp(r'^[0-9a-f]{64}$').hasMatch(value)) {
    throw FormatException('$field is not a SHA-256 digest.');
  }
  return value;
}

int _positiveInt(Object? value, String field) {
  if (value is! int || value <= 0 || value > 16384) {
    throw FormatException('$field must be a supported positive integer.');
  }
  return value;
}

int _nonNegativeInt(Object? value, String field, {required int maximum}) {
  if (value is! int || value < 0 || value > maximum) {
    throw FormatException('$field must be a supported non-negative integer.');
  }
  return value;
}

double _positiveDouble(Object? value, String field) {
  final number = _finiteDouble(value, field);
  if (number <= 0) throw FormatException('$field must be positive.');
  return number;
}

double _finiteDouble(Object? value, String field) {
  if (value is! num || !value.isFinite) {
    throw FormatException('$field must be finite.');
  }
  return value.toDouble();
}
