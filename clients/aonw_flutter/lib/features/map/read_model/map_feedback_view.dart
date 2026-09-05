import '../../cities/read_model/city_view.dart';
import 'map_view.dart';
import 'pending_action_view.dart';

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

enum MapFloatingTextStyleView { plain, bubble }

enum MapFeedbackMessageView {
  roadCompleted,
  unitKilled,
  unitRetreated,
  artifactExcavationStarted,
  artifactCarried,
  artifactStored,
}

sealed class MapFeedbackTextView {
  const MapFeedbackTextView();
}

final class MapMessageTextView extends MapFeedbackTextView {
  const MapMessageTextView(this.message);
  final MapFeedbackMessageView message;
}

final class MapImprovementYieldTextView extends MapFeedbackTextView {
  const MapImprovementYieldTextView({
    required this.improvement,
    required this.yieldDelta,
  });
  final FieldImprovementKind improvement;
  final YieldValueView yieldDelta;
}

sealed class MapTextAnchorView {
  const MapTextAnchorView();
}

final class MapTileTextAnchorView extends MapTextAnchorView {
  const MapTileTextAnchorView();
}

final class MapUnitTextAnchorView extends MapTextAnchorView {
  const MapUnitTextAnchorView(this.unitId);
  final String unitId;
}

final class MapCityTextAnchorView extends MapTextAnchorView {
  const MapCityTextAnchorView(this.cityId);
  final String cityId;
}

final class MapFloatingTextCueView extends MapFeedbackCueView {
  const MapFloatingTextCueView({
    required super.identity,
    required super.coordinate,
    required this.content,
    required this.colorValue,
    this.style = MapFloatingTextStyleView.plain,
    this.anchor = const MapTileTextAnchorView(),
    this.delay = Duration.zero,
  });

  final MapFeedbackTextView content;
  final int colorValue;
  final MapFloatingTextStyleView style;
  final MapTextAnchorView anchor;
  final Duration delay;
}
