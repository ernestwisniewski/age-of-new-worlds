import 'package:aonw_flutter/features/map/read_model/pending_action_view.dart';
import 'package:aonw_flutter/features/map/read_model/player_map_view.dart';
import 'package:aonw_flutter/features/research/read_model/research_discovery_view.dart';
import 'package:aonw_flutter/features/research/read_model/research_view.dart';

PlayerMapView discoveryPlayer({
  int revision = 0,
  String actor = 'player',
  PendingActionView? pendingAction,
  List<ResearchDiscoveryView> discoveries = const [],
}) {
  final base = PlayerMapView.preview(
    actorPlayerId: actor,
    stamp: SessionStampView(
      revision: revision,
      stateDigest: 'digest-$revision',
      mapHash: 'map',
      rulesetHash: 'rules',
    ),
    turn: 1,
    pendingAction: pendingAction,
    units: const [],
  );
  return PlayerMapView(
    actorPlayerId: actor,
    stamp: base.stamp,
    turnMode: base.turnMode,
    participants: base.participants,
    fog: base.fog,
    economy: base.economy,
    research: base.research,
    victory: base.victory,
    turnView: base.turnView,
    diplomacy: base.diplomacy,
    units: const [],
    recentDiscoveries: discoveries,
  );
}

const firstDiscovery = ResearchDiscoveryView(
  identity: (revision: 1, eventIndex: 0),
  technology: TechnologyIdView.mining,
);
const secondDiscovery = ResearchDiscoveryView(
  identity: (revision: 2, eventIndex: 0),
  technology: TechnologyIdView.agriculture,
);

ResearchOptionsView discoveryOptions(PlayerMapView player) =>
    ResearchOptionsView(
      stamp: SessionStampView(
        revision: player.stamp.revision,
        stateDigest: player.stamp.stateDigest,
        mapHash: player.stamp.mapHash,
        rulesetHash: player.stamp.rulesetHash,
      ),
      playerId: player.actorPlayerId,
      activeTechnology: null,
      scienceOverflow: 0,
      scienceYield: ScienceYieldBreakdownView(
        total: 1,
        byCityId: const {},
        sources: const [],
      ),
      options: [
        ResearchOptionView(
          technology: TechnologyIdView.mining,
          availability: TechnologyAvailabilityView.unlocked,
          effectiveCost: 10,
          progress: 10,
          boostDiscountBasisPoints: 0,
          prerequisites: const [],
          blockedBy: const [],
          unlocks: const [
            TechnologyUnlockView(
              kind: TechnologyUnlockKindView.resourceVisibility,
              target: 'iron',
            ),
          ],
        ),
      ],
    );
