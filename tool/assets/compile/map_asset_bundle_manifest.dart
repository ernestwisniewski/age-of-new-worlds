import 'dart:convert';

const String mapAssetBundleManifestName = 'map_texture_manifest.json';
const String mapAssetBundleGridLayout = 'oddQFlatTop';

final class MapAssetBundleManifest {
  const MapAssetBundleManifest({
    required this.mapId,
    required this.mapContentHash,
    required this.cols,
    required this.rows,
    required this.worldWidth,
    required this.worldHeight,
    required this.compiledScale,
    required this.filterQuality,
    required this.pageSizeLimit,
    required this.gutter,
    required this.pages,
    required this.averageColors,
  });

  factory MapAssetBundleManifest.decode(String contents) {
    final value = jsonDecode(contents);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Map asset bundle root must be an object');
    }
    _expectKeys(value, const {
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
    }, 'map asset bundle');
    if (value['gridLayout'] != mapAssetBundleGridLayout) {
      throw const FormatException('Unsupported map asset bundle grid layout');
    }
    final pages = value['pages'];
    final colors = value['averageColors'];
    if (pages is! List<dynamic> || pages.isEmpty) {
      throw const FormatException('Map asset bundle pages must not be empty');
    }
    if (colors is! Map<String, dynamic>) {
      throw const FormatException('Map asset bundle colors must be an object');
    }
    return MapAssetBundleManifest(
      mapId: _identifier(value['mapId'], 'mapId'),
      mapContentHash: _digest(value['mapContentHash'], 'mapContentHash'),
      cols: _positiveInt(value['cols'], 'cols'),
      rows: _positiveInt(value['rows'], 'rows'),
      worldWidth: _positiveDouble(value['worldWidth'], 'worldWidth'),
      worldHeight: _positiveDouble(value['worldHeight'], 'worldHeight'),
      compiledScale: _positiveDouble(value['compiledScale'], 'compiledScale'),
      filterQuality: _string(value['filterQuality'], 'filterQuality'),
      pageSizeLimit: _positiveInt(value['pageSizeLimit'], 'pageSizeLimit'),
      gutter: _nonNegativeInt(value['gutter'], 'gutter'),
      pages: List.unmodifiable(pages.map(MapAssetBundlePage.fromJson)),
      averageColors: Map.unmodifiable({
        for (final entry in colors.entries)
          entry.key: _color(entry.value, 'averageColors.${entry.key}'),
      }),
    );
  }

  final String mapId;
  final String mapContentHash;
  final int cols;
  final int rows;
  final double worldWidth;
  final double worldHeight;
  final double compiledScale;
  final String filterQuality;
  final int pageSizeLimit;
  final int gutter;
  final List<MapAssetBundlePage> pages;
  final Map<String, int> averageColors;

  void verifyMapIdentity({
    required String mapId,
    required String mapContentHash,
    required int cols,
    required int rows,
  }) {
    if (this.mapId != mapId) {
      throw const FormatException('Map asset bundle mapId does not match');
    }
    if (this.mapContentHash != mapContentHash) {
      throw const FormatException(
        'Map asset bundle mapContentHash does not match',
      );
    }
    if (this.cols != cols || this.rows != rows) {
      throw const FormatException('Map asset bundle dimensions do not match');
    }
  }

  Map<String, Object> toJson() => {
    'mapId': mapId,
    'mapContentHash': mapContentHash,
    'gridLayout': mapAssetBundleGridLayout,
    'cols': cols,
    'rows': rows,
    'worldWidth': worldWidth,
    'worldHeight': worldHeight,
    'compiledScale': compiledScale,
    'filterQuality': filterQuality,
    'pageSizeLimit': pageSizeLimit,
    'gutter': gutter,
    'pages': pages.map((page) => page.toJson()).toList(growable: false),
    'averageColors': averageColors,
  };

  String encode() =>
      '${const JsonEncoder.withIndent('  ').convert(toJson())}\n';
}

final class MapAssetBundlePage {
  const MapAssetBundlePage({
    required this.file,
    required this.asset,
    required this.format,
    required this.sha256,
    required this.pixelWidth,
    required this.pixelHeight,
    required this.destination,
  });

  factory MapAssetBundlePage.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Map asset bundle page must be an object');
    }
    _expectKeys(value, const {
      'file',
      'asset',
      'format',
      'sha256',
      'pixelWidth',
      'pixelHeight',
      'destination',
    }, 'map asset bundle page');
    final destination = value['destination'];
    if (destination is! List<dynamic> || destination.length != 4) {
      throw const FormatException('Map asset page destination is invalid');
    }
    return MapAssetBundlePage(
      file: _safeFile(value['file']),
      asset: _safeAsset(value['asset']),
      format: _format(value['format']),
      sha256: _digest(value['sha256'], 'page sha256'),
      pixelWidth: _positiveInt(value['pixelWidth'], 'pixelWidth'),
      pixelHeight: _positiveInt(value['pixelHeight'], 'pixelHeight'),
      destination: List.unmodifiable([
        for (final coordinate in destination)
          _finiteDouble(coordinate, 'destination'),
      ]),
    );
  }

  final String file;
  final String asset;
  final String format;
  final String sha256;
  final int pixelWidth;
  final int pixelHeight;
  final List<double> destination;

  Map<String, Object> toJson() => {
    'file': file,
    'asset': asset,
    'format': format,
    'sha256': sha256,
    'pixelWidth': pixelWidth,
    'pixelHeight': pixelHeight,
    'destination': destination,
  };
}

void _expectKeys(
  Map<String, dynamic> value,
  Set<String> expected,
  String context,
) {
  final actual = value.keys.toSet();
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw FormatException('$context has unexpected fields: $actual');
  }
}

String _identifier(Object? value, String field) {
  final identifier = _string(value, field);
  if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(identifier)) {
    throw FormatException('$field must be a safe identifier');
  }
  return identifier;
}

String _digest(Object? value, String field) {
  final digest = _string(value, field);
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(digest)) {
    throw FormatException('$field must be a lowercase SHA-256 digest');
  }
  return digest;
}

String _safeFile(Object? value) {
  final file = _string(value, 'page file');
  if (!RegExp(r'^page_[0-9]+\.jpg$').hasMatch(file)) {
    throw const FormatException('Map asset page file is unsafe');
  }
  return file;
}

String _safeAsset(Object? value) {
  final asset = _string(value, 'page asset');
  if (asset.startsWith('/') || asset.contains(r'\') || asset.contains('..')) {
    throw const FormatException('Map asset page path is unsafe');
  }
  return asset;
}

String _format(Object? value) {
  final format = _string(value, 'page format');
  if (format != 'jpeg') {
    throw const FormatException('Map asset page format must be jpeg');
  }
  return format;
}

String _string(Object? value, String field) {
  if (value is! String || value.isEmpty) {
    throw FormatException('$field must be a non-empty string');
  }
  return value;
}

int _positiveInt(Object? value, String field) {
  if (value is! int || value <= 0) {
    throw FormatException('$field must be a positive integer');
  }
  return value;
}

int _nonNegativeInt(Object? value, String field) {
  if (value is! int || value < 0) {
    throw FormatException('$field must be a non-negative integer');
  }
  return value;
}

int _color(Object? value, String field) {
  if (value is! int || value < 0 || value > 0xffffffff) {
    throw FormatException('$field must be an unsigned 32-bit color');
  }
  return value;
}

double _positiveDouble(Object? value, String field) {
  final number = _finiteDouble(value, field);
  if (number <= 0) throw FormatException('$field must be positive');
  return number;
}

double _finiteDouble(Object? value, String field) {
  if (value is! num || !value.toDouble().isFinite) {
    throw FormatException('$field must be a finite number');
  }
  return value.toDouble();
}
