use aonw_content::RulesetDefinition;
use aonw_domain::{HexCoord, WorldArtifactLocation};
use aonw_engine::{DomainEvent, EngineContext, GameEngine, PlayerCommand, TurnCommand};

use super::support::*;

#[test]
fn artifact_turn_phase_decrements_then_completes_in_owner_scope() {
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let artifact_id = artifact_id("sword");
    let excavator_id = unit_id("excavator");
    let excavator = excavating_unit("excavator", &p1, HexCoord::new(0, 0), artifact_id.clone());
    let excavation = |remaining_turns| {
        artifact(
            "sword",
            WorldArtifactLocation::Excavation {
                unit_id: excavator_id.clone(),
                coordinate: HexCoord::new(0, 0),
                remaining_turns,
            },
        )
    };

    let partial = GameEngine::apply_player_owned(
        state_with_active(
            vec![
                excavator.clone(),
                unit("foreign", &p2, HexCoord::new(3, 0)),
                unit("idle", &p1, HexCoord::new(2, 0)),
            ],
            Vec::new(),
            vec![excavation(2)],
            None,
            false,
            &p2,
        ),
        EngineContext::canonical(&p2, &map, RulesetDefinition::standard()),
        PlayerCommand::EndTurn(TurnCommand::new(9, &p2)),
    )
    .expect("partial excavation turn");
    assert!(matches!(partial.events(), [DomainEvent::TurnEnded(_)]));
    assert!(matches!(
        partial
            .state()
            .artifact(&artifact_id)
            .expect("artifact")
            .location(),
        WorldArtifactLocation::Excavation {
            remaining_turns: 1,
            ..
        }
    ));

    let completed = GameEngine::apply_player_owned(
        state_with_active(
            vec![excavator, unit("foreign", &p2, HexCoord::new(3, 0))],
            Vec::new(),
            vec![excavation(1)],
            None,
            false,
            &p2,
        ),
        EngineContext::canonical(&p2, &map, RulesetDefinition::standard()),
        PlayerCommand::EndTurn(TurnCommand::new(9, &p2)),
    )
    .expect("completed excavation turn");
    let [
        DomainEvent::ArtifactCarried(event),
        DomainEvent::TurnEnded(_),
    ] = completed.events()
    else {
        panic!("artifact completion events")
    };
    assert_eq!(event.artifact_id(), &artifact_id);
    assert_eq!(event.owner_player_id(), &p1);
    assert_eq!(event.unit_id(), &excavator_id);
    assert_eq!(event.coordinate(), HexCoord::new(0, 0));
    assert_eq!(
        completed
            .state()
            .unit(&excavator_id)
            .expect("carrier")
            .carried_artifact_id(),
        Some(&artifact_id)
    );
    assert_eq!(
        completed
            .state()
            .artifact(&artifact_id)
            .expect("artifact")
            .location(),
        &WorldArtifactLocation::Carried(excavator_id)
    );
}
