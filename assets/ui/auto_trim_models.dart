part of 'auto_trim_coordinates.dart';

final class _Cell {
  const _Cell({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory _Cell.full(_Region region) {
    return _Cell(left: 0, top: 0, right: region.width, bottom: region.height);
  }

  final int left;
  final int top;
  final int right;
  final int bottom;

  int get width => right - left;
  int get height => bottom - top;

  bool isConstrained(_Region region) {
    return left > 0 ||
        top > 0 ||
        right < region.width ||
        bottom < region.height;
  }

  _Cell intersect(_Cell other) {
    final intersection = _Cell(
      left: _max(left, other.left),
      top: _max(top, other.top),
      right: _min(right, other.right),
      bottom: _min(bottom, other.bottom),
    );
    if (intersection.width <= 0 || intersection.height <= 0) return this;
    return intersection;
  }
}

final class _Component {
  const _Component({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.area,
  });

  final int x;
  final int y;
  final int width;
  final int height;
  final int area;

  int get right => x + width;
  int get bottom => y + height;
}

final class _Region {
  const _Region({
    required this.sheet,
    required this.id,
    required this.frameName,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final String sheet;
  final String id;
  final String frameName;
  final int x;
  final int y;
  final int width;
  final int height;

  String get bounds => '[$x,$y,$width,$height]';

  bool hasSameBounds(_Region other) {
    return x == other.x &&
        y == other.y &&
        width == other.width &&
        height == other.height;
  }

  _Region withBounds({
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    return _Region(
      sheet: sheet,
      id: id,
      frameName: frameName,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }
}

final class _AtlasDocument {
  _AtlasDocument({
    required this.file,
    required this.sheet,
    required this.source,
    required this.document,
    required this.regions,
  });

  static const _encoder = JsonEncoder.withIndent('  ');

  final File file;
  final String sheet;
  final String source;
  final Map<String, dynamic> document;
  final List<_Region> regions;

  static Future<_AtlasDocument> load(File file, String sheet) async {
    final source = await file.readAsString();
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('${file.path} must contain a JSON object.');
    }
    final framesValue = decoded['frames'];
    if (framesValue is! Map<String, dynamic>) {
      throw FormatException('${file.path} must contain a frames object.');
    }
    final regions = <_Region>[];
    for (final entry in framesValue.entries) {
      if (!entry.key.endsWith('.webp')) {
        throw FormatException(
          '${file.path} frame name must end in .webp: ${entry.key}',
        );
      }
      final value = entry.value;
      if (value is! Map<String, dynamic>) {
        throw FormatException('${file.path} frame ${entry.key} is invalid.');
      }
      if (value['rotated'] == true) {
        throw FormatException(
          '${file.path} frame ${entry.key} must not be rotated.',
        );
      }
      final bounds = value['frame'];
      if (bounds is! Map<String, dynamic>) {
        throw FormatException(
          '${file.path} frame ${entry.key} has no frame bounds.',
        );
      }
      regions.add(
        _Region(
          sheet: sheet,
          id: entry.key.substring(0, entry.key.length - '.webp'.length),
          frameName: entry.key,
          x: _readInt(bounds, 'x', file, entry.key),
          y: _readInt(bounds, 'y', file, entry.key),
          width: _readInt(bounds, 'w', file, entry.key),
          height: _readInt(bounds, 'h', file, entry.key),
        ),
      );
    }
    return _AtlasDocument(
      file: file,
      sheet: sheet,
      source: source,
      document: decoded,
      regions: regions,
    );
  }

  void update(_Region region) {
    final frames = document['frames'] as Map<String, dynamic>;
    final frame = frames[region.frameName] as Map<String, dynamic>;
    frame['frame'] = <String, int>{
      'x': region.x,
      'y': region.y,
      'w': region.width,
      'h': region.height,
    };
    frame['rotated'] = false;
    frame['trimmed'] = false;
    frame['spriteSourceSize'] = <String, int>{
      'x': 0,
      'y': 0,
      'w': region.width,
      'h': region.height,
    };
    frame['sourceSize'] = <String, int>{'w': region.width, 'h': region.height};
    frame['pivot'] = <String, double>{'x': 0.5, 'y': 0.5};
  }

  String encode() => '${_encoder.convert(document)}\n';
}

int _readInt(Map<String, dynamic> values, String key, File file, String frame) {
  final value = values[key];
  if (value is int) return value;
  throw FormatException('${file.path} frame $frame has invalid $key: $value');
}
