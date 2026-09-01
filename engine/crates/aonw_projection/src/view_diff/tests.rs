use aonw_domain::{
    GameOutcome, HexCoord, MovementUnits, PlayerId, TurnMode, Unit, UnitId, UnitKind,
};

use super::{ProjectedView, diff_coordinate_views, diff_view};
use crate::{PlayerDiplomacyView, PlayerTurnLifecycleView, PlayerUnitView};

#[test]
fn sorted_view_diff_reports_updates_insertions_and_removals() {
    let before = vec![view("unit-a", 0), view("unit-b", 1)];
    let after = vec![view("unit-b", 2), view("unit-c", 3)];

    let turn = PlayerTurnLifecycleView::default();
    let before = ProjectedView::new(
        turn,
        GameOutcome::ongoing(),
        PlayerDiplomacyView::default(),
        before,
        Vec::new(),
        Vec::new(),
        (Vec::new(), Vec::new()),
    )
    .with_turn_mode(TurnMode::Simultaneous);
    let after = ProjectedView::new(
        turn,
        GameOutcome::ongoing(),
        PlayerDiplomacyView::default(),
        after,
        Vec::new(),
        Vec::new(),
        (Vec::new(), Vec::new()),
    )
    .with_turn_mode(TurnMode::Simultaneous)
    .with_gold(25)
    .with_science_per_turn(7)
    .with_live_score(42)
    .with_fog(
        &[HexCoord::new(1, 0), HexCoord::new(2, 0)],
        &[HexCoord::new(2, 0)],
    );
    let patch = diff_view(4, 5, &before, &after);

    assert_eq!(patch.from_revision, 4);
    assert_eq!(patch.to_revision, 5);
    assert_eq!(patch.turn, 0);
    assert_eq!(patch.turn_mode, TurnMode::Simultaneous);
    let fog = patch.fog.expect("changed fog");
    assert!(fog.enabled());
    assert_eq!(
        fog.discovered_hexes(),
        [HexCoord::new(1, 0), HexCoord::new(2, 0)]
    );
    assert_eq!(fog.visible_hexes(), [HexCoord::new(2, 0)]);
    assert_eq!(patch.economy.expect("changed economy").gold(), 25);
    assert_eq!(
        patch.research.expect("changed research").science_per_turn(),
        7
    );
    assert_eq!(
        patch
            .victory
            .expect("changed victory")
            .score_by_player_id()
            .values()
            .next(),
        Some(&42)
    );
    assert_eq!(
        patch
            .upserted_units
            .iter()
            .map(|unit| unit.id().as_str())
            .collect::<Vec<_>>(),
        ["unit-b", "unit-c"]
    );
    assert_eq!(
        patch
            .removed_unit_ids
            .iter()
            .map(UnitId::as_str)
            .collect::<Vec<_>>(),
        ["unit-a"]
    );
    assert_eq!(patch.pending_action, None);
}

#[test]
fn coordinate_view_diff_reports_updates_insertions_and_removals() {
    #[derive(Clone, Copy, Debug, Eq, PartialEq)]
    struct View {
        coordinate: HexCoord,
        value: u8,
    }

    let view = |col, value| View {
        coordinate: HexCoord::new(col, 0),
        value,
    };
    let before = [view(0, 0), view(2, 0), view(4, 0)];
    let after = [view(1, 0), view(2, 1), view(3, 0)];

    let (upserted, removed) = diff_coordinate_views(&before, &after, |view| view.coordinate);

    assert_eq!(upserted.as_ref(), [view(1, 0), view(2, 1), view(3, 0)]);
    assert_eq!(removed.as_ref(), [HexCoord::new(0, 0), HexCoord::new(4, 0)]);
}

fn view(id: &str, col: i32) -> PlayerUnitView {
    let unit = Unit::builder(
        UnitId::new(id).expect("unit id"),
        PlayerId::new("player-1").expect("player id"),
        UnitKind::Commander,
        "Commander",
        HexCoord::new(col, 0),
        MovementUnits::new(10),
    )
    .build()
    .expect("unit");
    PlayerUnitView::from_unit(&unit, true)
}
