import 'package:aonw_engine_client/src/protocol_coordinate.dart';
import 'package:aonw_engine_client/src/protocol_json.dart';

enum AonwWorldArtifactType {
  ancientImperialCrown,
  astronomersTablets,
  prophetMask,
  heroSword,
  merchantsSeal,
  firstPeoplesChronicle,
  templeReliquary,
  queensMirror;

  factory AonwWorldArtifactType.fromJson(Object? source) {
    final name = readString(source, 'artifact type');
    return values.firstWhere(
      (value) => value.name == name,
      orElse: () => throw FormatException('Unknown AoNW artifact type $name.'),
    );
  }
}

sealed class AonwPlayerArtifactLocation {
  const AonwPlayerArtifactLocation();

  factory AonwPlayerArtifactLocation.fromJson(Object? source) {
    final value = readObject(source, 'artifact location');
    return switch (value['kind']) {
      'map' => AonwMapArtifactLocation.fromJson(value),
      'carried' => AonwCarriedArtifactLocation.fromJson(value),
      'stored' => AonwStoredArtifactLocation.fromJson(value),
      'excavation' => AonwExcavationArtifactLocation.fromJson(value),
      final Object? kind => throw FormatException(
        'Unknown AoNW artifact location $kind.',
      ),
    };
  }
}

final class AonwMapArtifactLocation extends AonwPlayerArtifactLocation {
  const AonwMapArtifactLocation(this.coordinate);

  factory AonwMapArtifactLocation.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'kind', 'coordinate'}, 'map artifact location');
    return AonwMapArtifactLocation(
      AonwCoordinate.fromJson(value['coordinate']),
    );
  }

  final AonwCoordinate coordinate;
}

final class AonwCarriedArtifactLocation extends AonwPlayerArtifactLocation {
  const AonwCarriedArtifactLocation(this.unitId);

  factory AonwCarriedArtifactLocation.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'kind', 'unitId'}, 'carried artifact location');
    return AonwCarriedArtifactLocation(
      readString(value['unitId'], 'artifact carrier unit id'),
    );
  }

  final String unitId;
}

final class AonwStoredArtifactLocation extends AonwPlayerArtifactLocation {
  const AonwStoredArtifactLocation(this.cityId);

  factory AonwStoredArtifactLocation.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'kind', 'cityId'}, 'stored artifact location');
    return AonwStoredArtifactLocation(
      readString(value['cityId'], 'artifact storage city id'),
    );
  }

  final String cityId;
}

final class AonwExcavationArtifactLocation extends AonwPlayerArtifactLocation {
  const AonwExcavationArtifactLocation({
    required this.unitId,
    required this.coordinate,
    required this.remainingTurns,
  });

  factory AonwExcavationArtifactLocation.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'kind',
      'unitId',
      'coordinate',
      'remainingTurns',
    }, 'excavation artifact location');
    return AonwExcavationArtifactLocation(
      unitId: readString(value['unitId'], 'artifact excavator unit id'),
      coordinate: AonwCoordinate.fromJson(value['coordinate']),
      remainingTurns: readUnsigned(
        value['remainingTurns'],
        'artifact excavation remaining turns',
      ),
    );
  }

  final String unitId;
  final AonwCoordinate coordinate;
  final int remainingTurns;
}

final class AonwPlayerArtifactView {
  const AonwPlayerArtifactView({
    required this.id,
    required this.type,
    required this.location,
  });

  factory AonwPlayerArtifactView.fromJson(Object? source) {
    final value = readObject(source, 'player artifact view');
    requireKeys(value, const {
      'id',
      'type',
      'location',
    }, 'player artifact view');
    return AonwPlayerArtifactView(
      id: readString(value['id'], 'artifact id'),
      type: AonwWorldArtifactType.fromJson(value['type']),
      location: AonwPlayerArtifactLocation.fromJson(value['location']),
    );
  }

  final String id;
  final AonwWorldArtifactType type;
  final AonwPlayerArtifactLocation location;
}
