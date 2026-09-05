import 'package:aonw_flutter/features/map/presentation/map_feedback_labels.dart';
import 'package:aonw_flutter/features/map/presentation/map_render_snapshot.dart';
import 'package:aonw_flutter/features/map/read_model/map_feedback_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/l10n/generated/aonw_localizations_en.dart';

MapRenderSnapshot mapEventPerformanceSnapshot(
  MapRenderSnapshot source, {
  bool floatingText = false,
}) {
  final player = source.player;
  final cues = <MapFeedbackCueView>[
    for (var index = 0; index < 8; index++) ...[
      MapParticleCueView(
        identity: (revision: player.stamp.revision + 1, eventIndex: index),
        coordinate: (col: index % 4, row: index ~/ 4),
        kind: floatingText
            ? MapParticleKindView.technologyResearched
            : MapParticleKindView.cityFounded,
        colorValue: 0xff68a7e8,
      ),
      if (floatingText)
        MapFloatingTextCueView(
          identity: (revision: player.stamp.revision + 1, eventIndex: index),
          coordinate: (col: index % 4, row: index ~/ 4),
          content: const MapMessageTextView(
            MapFeedbackMessageView.artifactCarried,
          ),
          colorValue: 0xffffd166,
          style: MapFloatingTextStyleView.bubble,
        ),
    ],
  ];
  return MapRenderSnapshot(
    map: source.map,
    reference: source.reference,
    interaction: source.interaction,
    feedbackLabels: buildMapFeedbackLabels(cues, AonwLocalizationsEn()),
    player: PlayerMapView(
      actorPlayerId: player.actorPlayerId,
      stamp: SessionStampView(
        revision: player.stamp.revision + 1,
        stateDigest: 'e' * 64,
        mapHash: player.stamp.mapHash,
        rulesetHash: player.stamp.rulesetHash,
      ),
      turnMode: player.turnMode,
      participants: player.participants,
      fog: player.fog,
      economy: player.economy,
      research: player.research,
      victory: player.victory,
      turnView: player.turnView,
      diplomacy: player.diplomacy,
      units: player.units,
      recentFeedback: cues,
      cities: player.cities,
      artifacts: player.artifacts,
      fieldImprovements: player.fieldImprovements,
      roads: player.roads,
      cityFoundingDraft: player.cityFoundingDraft,
    ),
  );
}
