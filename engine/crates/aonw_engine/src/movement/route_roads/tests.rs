use super::{RoadNode, road_edge, route_road_step_indices};
use aonw_content::RulesetDefinition;
use aonw_domain::{
    FogOfWarState, GameState, HexCoord, HexGridBounds, MovementStep, MovementUnits, PlayerFogState,
    PlayerId, StateRevision, TransportCondition, TransportNetwork, TransportSegment, Unit, UnitId,
    UnitKind, UnitOccupancyPolicy,
};

#[test]
fn roads_are_land_only_and_respect_recipient_visibility_and_condition() {
    for kind in [
        UnitKind::Commander,
        UnitKind::ReconPlane,
        UnitKind::ScoutShip,
    ] {
        for (foreign, discovered, pillaged, expected) in [
            (false, false, false, vec![1, 2]),
            (true, false, false, vec![]),
            (true, true, false, vec![1, 2]),
            (false, true, true, vec![]),
        ] {
            let actor = PlayerId::new("owner").unwrap();
            let builder = if foreign {
                PlayerId::new("foreign").unwrap()
            } else {
                actor.clone()
            };
            let unit = Unit::builder(
                UnitId::new("unit").unwrap(),
                actor.clone(),
                kind,
                "Unit",
                HexCoord::new(0, 0),
                MovementUnits::new(1),
            )
            .build()
            .unwrap();
            let steps: Vec<_> = (0..3)
                .map(|col| {
                    MovementStep::new(
                        HexCoord::new(col, 0),
                        MovementUnits::new(u32::from(col != 0)),
                        MovementUnits::new(u32::try_from(col).unwrap()),
                    )
                })
                .collect();
            let known = if discovered {
                steps.iter().map(|s| s.coordinate()).collect()
            } else {
                vec![]
            };
            let fog = FogOfWarState::try_new([PlayerFogState::new(actor, known, [])]).unwrap();
            let condition = if pillaged {
                TransportCondition::Pillaged
            } else {
                TransportCondition::Operational
            };
            let roads =
                TransportNetwork::try_new(steps.iter().map(|s| {
                    TransportSegment::road(s.coordinate(), condition, builder.clone(), None)
                }))
                .unwrap();
            let state = GameState::builder(
                StateRevision::INITIAL,
                0,
                HexGridBounds::new(3, 1).unwrap(),
                UnitOccupancyPolicy::Exclusive,
                [unit.clone()],
            )
            .with_fog_of_war(fog)
            .with_transport_network(roads)
            .try_build()
            .unwrap();
            let indices: Vec<_> =
                route_road_step_indices(&state, RulesetDefinition::standard(), &unit, &steps)
                    .collect();
            assert_eq!(
                indices,
                if kind == UnitKind::Commander {
                    expected
                } else {
                    vec![]
                }
            );
        }
    }
}

#[test]
fn city_edges_require_at_least_one_operational_road() {
    assert!(road_edge(RoadNode::City, RoadNode::Road));
    assert!(road_edge(RoadNode::Road, RoadNode::City));
    assert!(road_edge(RoadNode::Road, RoadNode::Road));
    assert!(!road_edge(RoadNode::City, RoadNode::City));
    assert!(!road_edge(RoadNode::Other, RoadNode::Road));
}
