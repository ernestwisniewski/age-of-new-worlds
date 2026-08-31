use aonw_domain::{FogOfWar, PlayerFog};
use aonw_engine::{EngineContext, calculate_victory_progress};

use super::*;

#[test]
fn live_victory_progress_is_exact_and_recipient_safe() {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let rules = outcome_rules(OutcomeRuleOptions {
        domination: RuleToggle::Enabled,
        cultural: RuleToggle::Enabled,
        score_fallback: RuleToggle::Enabled,
        turn_limit: Some(10),
        ..OutcomeRuleOptions::default()
    });
    let identity = identity(rules, &p1, &p2);
    let objective = MapObjective::try_new(
        "central-ruins",
        MapObjectiveType::Ruins,
        HexCoord::new(2, 0),
        3,
        7,
        0,
    )
    .expect("objective");
    let map = map(vec![objective]);
    let p1_city_id = CityId::new("city-1").expect("city id");
    let p1_city = City::new(
        p1_city_id.clone(),
        p1.clone(),
        HexCoord::new(0, 0),
        Some(HexCoord::new(1, 0)),
    );
    let p2_city = City::new(
        CityId::new("city-2").expect("city id"),
        p2.clone(),
        HexCoord::new(3, 0),
        Some(HexCoord::new(2, 0)),
    );
    let objectives = ObjectiveState::try_new(
        &identity,
        BTreeMap::from([(p1.clone(), 2), (p2.clone(), 1)]),
        BTreeMap::from([(p1.clone(), 3)]),
        [
            MapObjectiveHoldState::try_new("central-ruins".into(), p2.clone(), 2)
                .expect("objective hold"),
        ],
    )
    .expect("objectives");
    let artifacts = [WorldArtifact::new(
        ArtifactId::new("artifact-0").expect("artifact id"),
        artifact_types()[0],
        WorldArtifactLocation::Stored(p1_city_id),
    )];
    let fog = FogOfWar::try_new([
        PlayerFog::new(p1.clone(), [HexCoord::new(0, 0)], [HexCoord::new(0, 0)]),
        PlayerFog::new(p2.clone(), [], []),
    ])
    .expect("fog");
    let state = state_builder(
        &map,
        identity,
        7,
        [
            unit("unit-1", &p1, UnitKind::Commander, 0, 0),
            unit("unit-2", &p2, UnitKind::Commander, 3, 0),
        ],
    )
    .with_cities([p1_city, p2_city])
    .with_artifacts(artifacts)
    .with_objectives(objectives)
    .with_fog_of_war(fog)
    .try_build()
    .expect("progress state");

    let p1_progress = calculate_victory_progress(
        &state,
        EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
    )
    .expect("player one progress");
    assert_rule_progress(&p1_progress);
    assert_eq!(p1_progress.score_by_player_id().len(), 2);
    assert_eq!(p1_progress.domination()[0].player_id(), &p1);
    assert_eq!(p1_progress.domination()[0].controlled_passable_hexes(), 2);
    assert_eq!(p1_progress.domination()[0].total_passable_hexes(), 4);
    assert_eq!(p1_progress.domination()[0].hold_turns(), 2);
    assert_eq!(p1_progress.own_cultural().unique_stored_artifacts(), 1);
    assert_eq!(p1_progress.own_cultural().hold_turns(), 3);
    assert_eq!(p1_progress.map_objectives()[0].controller_player_id(), None);
    assert_eq!(p1_progress.map_objectives()[0].hold_turns(), 0);

    let p2_progress = calculate_victory_progress(
        &state,
        EngineContext::canonical(&p2, &map, RulesetDefinition::standard()),
    )
    .expect("player two progress");
    assert_eq!(
        p2_progress.map_objectives()[0].controller_player_id(),
        Some(&p2)
    );
    assert_eq!(p2_progress.map_objectives()[0].hold_turns(), 2);
    assert_eq!(p2_progress.own_cultural().unique_stored_artifacts(), 0);
    assert_eq!(p2_progress.own_cultural().hold_turns(), 0);
}

fn assert_rule_progress(progress: &aonw_engine::VictoryProgress) {
    assert!(!progress.conquest_enabled());
    assert!(progress.domination_enabled());
    assert_eq!(progress.domination_required_control_percent(), "60");
    assert_eq!(progress.domination_required_hold_turns(), 5);
    assert!(progress.cultural_enabled());
    assert_eq!(progress.cultural_required_artifacts(), 6);
    assert_eq!(progress.cultural_required_hold_turns(), 5);
    assert!(progress.score_fallback_enabled());
    assert_eq!(progress.turn_limit(), Some(10));
    assert_eq!(progress.remaining_turns(), Some(3));
}
