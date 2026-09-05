part of 'protocol_event.dart';

final class AonwCityFoundedEvent extends AonwClientEvent {
  const AonwCityFoundedEvent({
    required this.cityId,
    required this.ownerPlayerId,
  }) : super(AonwClientEventKind.cityFounded);

  final String cityId;
  final String ownerPlayerId;
}

final class AonwCityBuiltBuildingEvent extends AonwClientEvent {
  const AonwCityBuiltBuildingEvent({
    required this.cityId,
    required this.buildingType,
  }) : super(AonwClientEventKind.cityBuiltBuilding);

  final String cityId;
  final AonwCityBuildingType buildingType;
}

final class AonwCityProducedUnitEvent extends AonwClientEvent {
  const AonwCityProducedUnitEvent({
    required this.cityId,
    required this.unitType,
    required this.producedUnitId,
  }) : super(AonwClientEventKind.cityProducedUnit);

  final String cityId;
  final AonwUnitKind unitType;
  final String producedUnitId;
}

final class AonwCityBuiltWonderEvent extends AonwClientEvent {
  const AonwCityBuiltWonderEvent({
    required this.cityId,
    required this.ownerPlayerId,
    required this.wonderType,
  }) : super(AonwClientEventKind.cityBuiltWonder);

  final String cityId;
  final String ownerPlayerId;
  final AonwWonderType wonderType;
}

final class AonwWonderProductionRefundedEvent extends AonwClientEvent {
  const AonwWonderProductionRefundedEvent({
    required this.cityId,
    required this.ownerPlayerId,
    required this.wonderType,
    required this.refundedProduction,
  }) : super(AonwClientEventKind.wonderProductionRefunded);

  final String cityId;
  final String ownerPlayerId;
  final AonwWonderType wonderType;
  final int refundedProduction;
}

final class AonwCityClaimedHexEvent extends AonwClientEvent {
  const AonwCityClaimedHexEvent({
    required this.cityId,
    required this.coordinate,
  }) : super(AonwClientEventKind.cityClaimedHex);

  final String cityId;
  final AonwCoordinate coordinate;
}

AonwClientEvent? _cityEvent(
  Map<String, Object?> value,
  AonwClientEventKind kind,
) => switch (kind) {
  AonwClientEventKind.cityFounded => AonwCityFoundedEvent(
    cityId: readString(value['cityId'], 'founded city id'),
    ownerPlayerId: readString(value['ownerPlayerId'], 'city owner id'),
  ),
  AonwClientEventKind.cityBuiltBuilding => AonwCityBuiltBuildingEvent(
    cityId: readString(value['cityId'], 'production city id'),
    buildingType: AonwCityBuildingType.fromJson(value['buildingType']),
  ),
  AonwClientEventKind.cityProducedUnit => AonwCityProducedUnitEvent(
    cityId: readString(value['cityId'], 'production city id'),
    unitType: AonwUnitKind.fromJson(value['unitType']),
    producedUnitId: readString(value['producedUnitId'], 'produced unit id'),
  ),
  AonwClientEventKind.cityBuiltWonder => AonwCityBuiltWonderEvent(
    cityId: readString(value['cityId'], 'production city id'),
    ownerPlayerId: readString(value['ownerPlayerId'], 'wonder owner id'),
    wonderType: AonwWonderType.fromJson(value['wonderType']),
  ),
  AonwClientEventKind.wonderProductionRefunded =>
    AonwWonderProductionRefundedEvent(
      cityId: readString(value['cityId'], 'refunded city id'),
      ownerPlayerId: readString(value['ownerPlayerId'], 'wonder owner id'),
      wonderType: AonwWonderType.fromJson(value['wonderType']),
      refundedProduction: readInt(
        value['refundedProduction'],
        'refunded production',
      ),
    ),
  AonwClientEventKind.cityClaimedHex => AonwCityClaimedHexEvent(
    cityId: readString(value['cityId'], 'claiming city id'),
    coordinate: AonwCoordinate(
      col: readInt(value['col'], 'claimed column'),
      row: readInt(value['row'], 'claimed row'),
    ),
  ),
  _ => null,
};
