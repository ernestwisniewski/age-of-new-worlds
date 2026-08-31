import '../../map/read_model/map_view.dart';

enum WorldArtifactKindView {
  ancientImperialCrown,
  astronomersTablets,
  prophetMask,
  heroSword,
  merchantsSeal,
  firstPeoplesChronicle,
  templeReliquary,
  queensMirror,
}

sealed class ArtifactLocationView {
  const ArtifactLocationView();
}

final class MapArtifactLocationView extends ArtifactLocationView {
  const MapArtifactLocationView(this.coordinate);

  final MapHexCoordinate coordinate;
}

final class CarriedArtifactLocationView extends ArtifactLocationView {
  const CarriedArtifactLocationView(this.unitId);

  final String unitId;
}

final class StoredArtifactLocationView extends ArtifactLocationView {
  const StoredArtifactLocationView(this.cityId);

  final String cityId;
}

final class ExcavationArtifactLocationView extends ArtifactLocationView {
  const ExcavationArtifactLocationView({
    required this.unitId,
    required this.coordinate,
    required this.remainingTurns,
  });

  final String unitId;
  final MapHexCoordinate coordinate;
  final int remainingTurns;
}

final class WorldArtifactView {
  const WorldArtifactView({
    required this.id,
    required this.kind,
    required this.location,
  });

  final String id;
  final WorldArtifactKindView kind;
  final ArtifactLocationView location;
}

sealed class ArtifactActionView {
  const ArtifactActionView();
}

final class StartArtifactExcavationActionView extends ArtifactActionView {
  const StartArtifactExcavationActionView({required this.unitId});

  final String unitId;
}

final class StoreArtifactInCityActionView extends ArtifactActionView {
  const StoreArtifactInCityActionView({
    required this.unitId,
    required this.cityId,
  });

  final String unitId;
  final String? cityId;
}

final class TradeArtifactActionView extends ArtifactActionView {
  const TradeArtifactActionView({
    required this.targetPlayerId,
    required this.offeredArtifactId,
    required this.offeredGold,
  });

  final String targetPlayerId;
  final String offeredArtifactId;
  final int offeredGold;
}

enum ArtifactRejectionCodeView {
  staleRevision,
  matchFinished,
  unitNotFound,
  unitNotControlled,
  unitUnavailable,
  unitAlreadyCarryingArtifact,
  artifactNotFound,
  unitNotCarryingArtifact,
  cityNotFound,
  cityNotControlled,
  unitNotInCity,
  cityArtifactSlotFull,
  artifactTradeActorUnavailable,
  artifactTradeTargetInvalid,
  artifactTradeGoldInvalid,
  artifactTradeBlockedByWar,
  artifactTradeGoldUnavailable,
  offeredArtifactUnavailable,
  targetArtifactSlotUnavailable,
  stateRevisionOverflow,
}
