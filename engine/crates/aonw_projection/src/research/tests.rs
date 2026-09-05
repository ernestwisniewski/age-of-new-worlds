use std::collections::{BTreeMap, BTreeSet};
use std::sync::Arc;

use aonw_content::{
    GridLayout, MapDefinition, RulesetDefinition, TechnologyEra, TerrainType, TileDefinition,
};
use aonw_domain::{
    GameMode, GameState, HexCoord, KnowledgeState, MatchIdentity, MatchLifecycle, MatchRules,
    Participant, PlayerCountry, PlayerId, PlayerKind, PlayerResearchState, PlayerTurnState,
    ResearchState, StateRevision, TechnologyId, TurnLifecycle, WonderRegistry,
};

use super::{PlayerResearchView, dominant_era_for_research};
use crate::{ProjectedView, diff_view};

#[test]
fn dominant_era_uses_completed_catalog_eras_instead_of_active_research() {
    let ruleset = RulesetDefinition::standard();
    let cases = [
        (TechnologyId::Agriculture, TechnologyEra::Foundation),
        (TechnologyId::Craftsmanship, TechnologyEra::Settlement),
        (TechnologyId::AdvancedTrade, TechnologyEra::Expansion),
        (TechnologyId::Banking, TechnologyEra::Specialization),
        (TechnologyId::CoalMining, TechnologyEra::Industry),
        (TechnologyId::Strategy, TechnologyEra::Strategy),
    ];
    assert_eq!(
        dominant_era_for_research(&PlayerResearchState::default(), ruleset),
        TechnologyEra::Foundation
    );
    for (technology, expected) in cases {
        let active = if technology == TechnologyId::Strategy {
            TechnologyId::Mining
        } else {
            TechnologyId::Strategy
        };
        let research = PlayerResearchState::try_new(
            [TechnologyId::Agriculture, technology]
                .into_iter()
                .collect::<BTreeSet<_>>(),
            Some(active),
            [(active, 100)],
            0,
        )
        .expect("research");
        assert_eq!(dominant_era_for_research(&research, ruleset), expected);
    }
}

#[test]
fn research_era_patches_are_private_to_the_recipient() {
    let (before, map, ruleset) = fixture(1, false);
    let (after, _, _) = fixture(2, true);
    let first = player("first");
    let second = player("second");
    let first_view =
        PlayerResearchView::try_for_recipient(&before, &first, &map, &ruleset).expect("first view");
    let second_view = PlayerResearchView::try_for_recipient(&before, &second, &map, &ruleset)
        .expect("second view");
    assert_eq!(first_view.dominant_era(), TechnologyEra::Settlement);
    assert_eq!(second_view.dominant_era(), TechnologyEra::Strategy);
    let projected = |state: &GameState, actor: &PlayerId| {
        ProjectedView::try_for_recipient(state, Arc::new(actor.clone()), &map, &ruleset)
            .expect("projection")
    };
    let own_patch = diff_view(
        1,
        2,
        &projected(&before, &first),
        &projected(&after, &first),
    );
    assert_eq!(
        own_patch.research.expect("changed era").dominant_era(),
        TechnologyEra::Expansion
    );
    let other_patch = diff_view(
        1,
        2,
        &projected(&before, &second),
        &projected(&after, &second),
    );
    assert!(other_patch.research.is_none());
}

fn fixture(revision: u64, advanced: bool) -> (GameState, MapDefinition, RulesetDefinition) {
    let first = player("first");
    let second = player("second");
    let ruleset = RulesetDefinition::standard().clone();
    let map = MapDefinition::try_new(
        "research-era",
        GridLayout::OddQFlatTop,
        1,
        1,
        vec![
            TileDefinition::try_new_for_simulation(
                HexCoord::new(0, 0),
                vec![TerrainType::Plains],
                Vec::new(),
                0,
            )
            .expect("tile"),
        ],
        Vec::new(),
    )
    .expect("map");
    let participants = [first.clone(), second.clone()].map(|id| {
        Participant::try_new(
            id,
            "Player",
            0xff00_0000,
            PlayerCountry::Poland,
            PlayerKind::Human,
            None,
        )
        .expect("participant")
    });
    let identity =
        MatchIdentity::try_new(MatchRules::default(), participants, GameMode::Multiplayer)
            .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (first.clone(), PlayerTurnState::Active),
            (second.clone(), PlayerTurnState::Active),
        ]),
        [first.clone(), second.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("turn");
    let research = ResearchState::try_new([
        (
            first,
            PlayerResearchState::try_new(
                if advanced {
                    vec![TechnologyId::Craftsmanship, TechnologyId::AdvancedTrade]
                } else {
                    vec![TechnologyId::Craftsmanship]
                },
                None,
                [],
                0,
            )
            .expect("first research"),
        ),
        (
            second,
            PlayerResearchState::try_new([TechnologyId::Strategy], None, [], 0)
                .expect("second research"),
        ),
    ])
    .expect("research");
    let state = GameState::builder(
        StateRevision::new(revision),
        1,
        map.bounds(),
        ruleset.occupancy_policy(),
        [],
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .try_build()
    .expect("state");
    (state, map, ruleset)
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player")
}
