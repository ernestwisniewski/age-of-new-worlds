import 'map_view.dart';

typedef MapEventIdentityView = ({int revision, int eventIndex});

enum MapParticleKindView {
  cityFounded,
  unitProduced,
  hexClaimed,
  technologyResearched,
}

/// Recipient-safe presentation facts retained across coalesced UI updates.
sealed class MapFeedbackCueView {
  const MapFeedbackCueView({required this.identity, required this.coordinate});

  final MapEventIdentityView identity;
  final MapHexCoordinate coordinate;
}

final class MapParticleCueView extends MapFeedbackCueView {
  const MapParticleCueView({
    required super.identity,
    required super.coordinate,
    required this.kind,
    required this.colorValue,
  });

  final MapParticleKindView kind;
  final int colorValue;
}
