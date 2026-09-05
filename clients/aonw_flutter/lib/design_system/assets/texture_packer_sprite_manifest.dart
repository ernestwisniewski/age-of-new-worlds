part of 'texture_packer_sprite_frame_repository.dart';

final class _SpriteManifest {
  const _SpriteManifest({required this.atlases, required this.frames});

  final Map<String, String> atlases;
  final Map<String, _SpriteManifestEntry> frames;
}

final class _SpriteManifestEntry {
  const _SpriteManifestEntry({
    required this.atlasId,
    required this.region,
    required this.index,
    required this.contentBounds,
    required this.statusTop,
  });

  factory _SpriteManifestEntry.fromJson(Map<String, dynamic> json) {
    return _SpriteManifestEntry(
      atlasId: json['atlas'] as String,
      region: json['region'] as String,
      index: json['index'] as int,
      contentBounds: _contentBoundsFromJson(json['content']),
      statusTop: (json['statusTop'] as num?)?.toDouble(),
    );
  }

  final String atlasId;
  final String region;
  final int index;
  final ui.Rect? contentBounds;
  final double? statusTop;

  static ui.Rect? _contentBoundsFromJson(Object? value) {
    if (value is! List || value.length != 4) return null;
    final numbers = value.cast<num>();
    return ui.Rect.fromLTWH(
      numbers[0].toDouble(),
      numbers[1].toDouble(),
      numbers[2].toDouble(),
      numbers[3].toDouble(),
    );
  }
}
