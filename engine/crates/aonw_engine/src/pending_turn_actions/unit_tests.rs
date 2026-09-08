use aonw_domain::{
    ArtifactId, CityFoundingJob, CityId, HexCoord, MerchantTradeRoute, MovementUnits, PlayerId,
    Unit, UnitActivity, UnitId, UnitKind, UnitPosture, WorkerJob,
};

use super::needs_manual_order;

#[test]
fn each_work_slot_excludes_manual_attention_even_with_movement_remaining() {
    let at = HexCoord::new(0, 0);
    let activities = [
        UnitActivity::new(
            Some(WorkerJob::RoadConstruction {
                target: at,
                remaining_turns: 1,
                total_turns: 2,
            }),
            None,
            None,
            None,
        ),
        UnitActivity::new(None, Some(CityFoundingJob::new(at, [at], 1, 2)), None, None),
        UnitActivity::new(None, None, Some(at), None),
        UnitActivity::new(
            None,
            None,
            None,
            Some(ArtifactId::new("artifact").expect("id")),
        ),
    ];
    for activity in activities {
        let unit = builder()
            .with_activity(activity)
            .build()
            .expect("working unit");
        assert!(!needs_manual_order(&unit));
    }
}

#[test]
fn merchant_standing_route_excludes_attention_without_a_queued_movement_path() {
    let route = MerchantTradeRoute::new(
        CityId::new("origin").expect("id"),
        CityId::new("destination").expect("id"),
        [],
        "network",
    );
    let unit = builder()
        .with_merchant_trade_route(Some(route))
        .build()
        .expect("merchant");
    assert!(!needs_manual_order(&unit));
}

#[test]
fn manual_attention_uses_remaining_movement_even_for_fortified_posture() {
    let unit = builder()
        .with_posture(UnitPosture::Fortified)
        .build()
        .expect("unit");
    assert!(needs_manual_order(&unit));
    assert!(!needs_manual_order(&unit.after_skip_turn()));
}

fn builder() -> aonw_domain::UnitBuilder {
    Unit::builder(
        UnitId::new("unit").expect("id"),
        PlayerId::new("player").expect("id"),
        UnitKind::Worker,
        "unit",
        HexCoord::new(0, 0),
        MovementUnits::new(10),
    )
}
