use std::collections::BTreeMap;

use aonw_domain::{PlayerId, RuleNumber};

use super::{VictoryProgress, VictoryStatusKind as Kind};
use crate::{CulturalVictoryProgress, DominationVictoryProgress};

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).unwrap()
}

fn progress() -> VictoryProgress {
    VictoryProgress {
        conquest_enabled: true,
        domination_enabled: true,
        domination_required_control_percent: RuleNumber::new("60").unwrap(),
        domination_required_hold_turns: 5,
        cultural_enabled: true,
        cultural_required_artifacts: 6,
        cultural_required_hold_turns: 5,
        score_fallback_enabled: true,
        turn_limit: Some(100),
        remaining_turns: Some(10),
        score_by_player_id: BTreeMap::from([(player("a"), 20), (player("b"), 30)]),
        domination: Box::new([entry("a", 10, 0), entry("b", 20, 0)]),
        own_cultural: CulturalVictoryProgress::default(),
        map_objectives: Box::new([]),
    }
}

fn entry(id: &str, controlled: u32, hold: u32) -> DominationVictoryProgress {
    DominationVictoryProgress {
        player_id: player(id),
        controlled_passable_hexes: controlled,
        total_passable_hexes: 100,
        hold_turns: hold,
    }
}

#[test]
fn score_deadline_precedes_culture_and_domination_and_preserves_ties() {
    let actor = player("a");
    let mut view = progress();
    view.own_cultural = CulturalVictoryProgress {
        unique_stored_artifacts: 6,
        hold_turns: 4,
    };
    view.domination = Box::new([entry("b", 80, 4)]);
    view.remaining_turns = Some(5);
    let status = view.status(&actor);
    assert_eq!(status.kind(), Kind::Score);
    assert!(status.critical());
    assert_eq!(status.leader_player_id(), Some(&player("b")));
    view.score_by_player_id.insert(actor.clone(), 30);
    assert_eq!(view.status(&actor).leader_player_id(), None);
    view.remaining_turns = Some(0);
    assert!(view.status(&actor).critical());
}

#[test]
fn own_culture_precedes_unheld_territory_and_breaks_hold_ties_by_remaining_turns() {
    let actor = player("a");
    let mut view = progress();
    assert_eq!(view.status(&actor).kind(), Kind::Domination);
    view.own_cultural = CulturalVictoryProgress {
        unique_stored_artifacts: 1,
        hold_turns: 0,
    };
    assert_eq!(view.status(&actor).kind(), Kind::Culture);
    assert!(!view.status(&actor).critical());
    view.domination = Box::new([entry("b", 60, 2)]);
    assert_eq!(view.status(&actor).kind(), Kind::Domination);
    view.own_cultural = CulturalVictoryProgress {
        unique_stored_artifacts: 6,
        hold_turns: 2,
    };
    assert_eq!(view.status(&actor).kind(), Kind::Domination);
    view.own_cultural.hold_turns = 3;
    assert_eq!(view.status(&actor).kind(), Kind::Culture);
    assert_eq!(view.status(&actor).leader_player_id(), Some(&actor));
    assert!(view.status(&actor).critical());
}

#[test]
fn domination_warning_matches_hold_duration_and_near_threshold_policy() {
    let actor = player("a");
    for (required, control, held, warning) in [
        (2, 53, 0, false),
        (2, 54, 0, true),
        (3, 56, 0, false),
        (3, 57, 0, true),
        (4, 59, 0, false),
        (3, 60, 0, true),
        (5, 60, 3, false),
        (5, 60, 4, true),
    ] {
        let mut view = progress();
        view.domination_required_hold_turns = required;
        view.domination = Box::new([entry("b", control, held)]);
        assert_eq!(
            view.status(&actor).critical(),
            warning,
            "{required}/{control}/{held}"
        );
        assert!(
            !view.status(&player("b")).critical(),
            "own control is not an opponent threat"
        );
    }
}

#[test]
fn disabled_conditions_empty_maps_and_equal_leaders_have_stable_fallbacks() {
    let actor = player("a");
    let mut view = progress();
    view.domination = Box::new([entry("b", 20, 0), entry("a", 20, 0)]);
    assert_eq!(view.status(&actor).leader_player_id(), Some(&actor));
    view.domination[0].hold_turns = 1;
    assert_eq!(view.status(&actor).leader_player_id(), Some(&player("b")));
    for value in &mut view.domination {
        value.total_passable_hexes = 0;
    }
    assert_eq!(view.status(&actor).kind(), Kind::Score);
    view.remaining_turns = None;
    assert_eq!(view.status(&actor).kind(), Kind::Conquest);
    view.conquest_enabled = false;
    assert_eq!(view.status(&actor).kind(), Kind::None);
    view.domination = Box::new([entry("b", 80, 5)]);
    view.domination_enabled = false;
    view.cultural_enabled = false;
    view.own_cultural.unique_stored_artifacts = 6;
    assert_eq!(view.status(&actor).kind(), Kind::None);
}
