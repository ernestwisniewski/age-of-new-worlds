use aonw_domain::{DiplomacyState, FogOfWarState, PlayerFogState, PlayerPair};

use super::*;

#[test]
fn city_commands_preserve_existing_fog_and_diplomacy() {
    let map = map(7, 7);
    let actor = player("player-1");
    let foreign = player("player-2");
    let center = HexCoord::new(3, 3);
    let controlled = [HexCoord::new(3, 2), HexCoord::new(2, 3)];
    let founder_id = unit_id("settler-1");
    let city_id = city_id("city-a");
    let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
    let fog = FogOfWarState::try_new([
        PlayerFogState::new(actor.clone(), [HexCoord::new(0, 0)], [center]),
        PlayerFogState::new(foreign.clone(), [], [HexCoord::new(6, 6)]),
    ])
    .expect("fog");
    let diplomacy =
        DiplomacyState::new([PlayerPair::new(actor.clone(), foreign.clone()).expect("contact")]);
    for command in [
        PlayerCommand::FoundCity(FoundCityCommand::new(9, &founder_id, &controlled)),
        PlayerCommand::ToggleWorkedHex(ToggleWorkedHexCommand::new(9, &city_id, controlled[0])),
        PlayerCommand::SelectCityExpansionHex(SelectCityExpansionHexCommand::new(
            9,
            &city_id,
            HexCoord::new(4, 3),
        )),
    ] {
        let cities = if matches!(&command, PlayerCommand::FoundCity(_)) {
            Vec::new()
        } else {
            vec![
                City::builder(city_id.clone(), actor.clone(), "Warsaw", center)
                    .with_controlled_hexes(controlled)
                    .build()
                    .expect("city"),
            ]
        };
        let state = state(
            &map,
            vec![
                unit("settler-1", &actor, UnitKind::Settler, center),
                unit("scout-2", &foreign, UnitKind::Scout, HexCoord::new(6, 6)),
            ],
            cities,
            InteractionState::default(),
        );
        let lifecycle = state.match_lifecycle().clone();
        let state = state
            .into_started_match(lifecycle, fog.clone(), diplomacy.clone())
            .expect("state with environment");
        let result = GameEngine::apply_player_owned(state, context, command).expect("command");
        assert!(result.is_accepted(), "{:?}", result.rejection());
        assert_eq!(result.revision().get(), 10);
        assert_eq!(result.state().fog_of_war(), &fog);
        assert_eq!(result.state().diplomacy(), &diplomacy);
    }
}
