use aonw_content::{GridLayout, TerrainType, TileDefinition};
use aonw_domain::{
    CityFoundingJob, FogOfWarState, FogVisibility, HexCoord, InteractionState, MovementUnits,
    PendingInteraction, PlayerFogState, StateRevision, Unit, UnitId, UnitKind,
};

use super::*;

#[test]
fn founding_phase_updates_visibility_and_discovers_contacts() {
    let rules = RulesetDefinition::standard();
    let map = founding_map();
    let actor = PlayerId::new("player-1").expect("actor");
    let foreign = PlayerId::new("player-2").expect("foreign");
    let center = HexCoord::new(3, 3);
    let foreign_position = HexCoord::new(4, 3);
    let old_discovery = HexCoord::new(0, 0);
    let founder_id = UnitId::new("settler-1").expect("founder id");
    let founder = Unit::builder(
        founder_id.clone(),
        actor.clone(),
        UnitKind::Settler,
        "Settler",
        center,
        MovementUnits::ZERO,
    )
    .build()
    .expect("founder")
    .with_city_founding_job(Some(CityFoundingJob::new(
        center,
        [HexCoord::new(3, 2), HexCoord::new(2, 3)],
        1,
        1,
    )));
    let scout = Unit::builder(
        UnitId::new("scout-2").expect("id"),
        foreign.clone(),
        UnitKind::Scout,
        "Scout",
        foreign_position,
        MovementUnits::new(10),
    )
    .build()
    .expect("scout");
    let interaction = InteractionState::new(
        None,
        Some(PendingInteraction::ResearchSelection {
            owner_player_id: actor.clone(),
        }),
    );
    let state = GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        rules.occupancy_policy(),
        [founder, scout],
    )
    .with_fog_of_war(
        FogOfWarState::try_new([
            PlayerFogState::new(actor.clone(), [old_discovery], [center]),
            PlayerFogState::new(foreign.clone(), [], [foreign_position]),
        ])
        .expect("fog"),
    )
    .with_interaction(interaction.clone())
    .try_build()
    .expect("state");
    assert_eq!(
        state.fog_of_war().visibility(&actor, foreign_position),
        FogVisibility::Hidden
    );
    assert!(state.diplomacy().contacts().is_empty());
    let phase = advance_city_phase(state, &map, rules, std::slice::from_ref(&actor))
        .expect("founding phase");
    assert_eq!(phase.founded_city_ids.len(), 1);
    assert_eq!(phase.events.len(), 1);
    assert!(phase.state.unit(&founder_id).is_none());
    assert_eq!(phase.state.revision(), StateRevision::new(9));
    assert_eq!(phase.state.interaction(), &interaction);
    assert_eq!(
        phase
            .state
            .fog_of_war()
            .visibility(&actor, foreign_position),
        FogVisibility::Visible
    );
    assert_eq!(
        phase.state.fog_of_war().visibility(&actor, old_discovery),
        FogVisibility::Discovered
    );
    assert!(phase.state.diplomacy().has_contact(&actor, &foreign));
}

fn founding_map() -> MapDefinition {
    MapDefinition::try_new(
        "founding-visibility",
        GridLayout::OddQFlatTop,
        7,
        7,
        (0..7)
            .flat_map(|row| {
                (0..7).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(col, row),
                        vec![TerrainType::Plains],
                        Vec::new(),
                        0,
                    )
                    .expect("tile")
                })
            })
            .collect(),
        Vec::new(),
    )
    .expect("map")
}
