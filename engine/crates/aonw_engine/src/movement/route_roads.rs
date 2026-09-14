use aonw_content::RulesetDefinition;
use aonw_domain::{FogVisibility, GameState, HexCoord, MovementStep, Unit, UnitMovementDomain};

/// Returns destination-step indices whose edges use recipient-known roads.
///
/// Road-to-road and road-to-city edges apply only to the land movement domain.
/// Hidden foreign roads and city centers cannot affect the result. The caller
/// must disclose a stored itinerary only to its owner.
pub fn route_road_step_indices<'a>(
    state: &'a GameState,
    ruleset: &RulesetDefinition,
    unit: &'a Unit,
    steps: &'a [MovementStep],
) -> impl Iterator<Item = u32> + 'a {
    let land = unit_uses_roads(ruleset, unit);
    steps
        .windows(2)
        .enumerate()
        .filter_map(move |(index, pair)| {
            let from = pair[0].coordinate();
            let to = pair[1].coordinate();
            if land && from.distance_to(to) == 1 && known_edge(state, unit, from, to) {
                u32::try_from(index + 1).ok()
            } else {
                None
            }
        })
}

fn known_edge(state: &GameState, unit: &Unit, from: HexCoord, to: HexCoord) -> bool {
    let actor = unit.owner_player_id();
    let known =
        |coordinate| state.fog_of_war().visibility(actor, coordinate) != FogVisibility::Hidden;
    let road = |coordinate| {
        state
            .transport_network()
            .at(coordinate)
            .is_some_and(|segment| {
                segment.is_operational()
                    && (segment.built_by_player_id() == actor
                        || known(coordinate)
                        || segment
                            .built_by_city_id()
                            .and_then(|id| state.city(id))
                            .is_some_and(|city| city.owner_player_id() == actor))
            })
    };
    let city = |coordinate| {
        state.cities().iter().any(|city| {
            city.center() == coordinate && (city.owner_player_id() == actor || known(coordinate))
        })
    };
    let from_road = road(from);
    let to_road = road(to);
    road_edge(
        road_node(from_road, city(from)),
        road_node(to_road, city(to)),
    )
}

pub(super) fn unit_uses_roads(ruleset: &RulesetDefinition, unit: &Unit) -> bool {
    ruleset.unit(unit.kind()).is_some_and(|definition| {
        definition.capabilities().movement_domain.domain() == UnitMovementDomain::Land
    })
}

pub(super) enum RoadNode {
    Other,
    City,
    Road,
}

pub(super) const fn road_node(road: bool, city: bool) -> RoadNode {
    if road {
        RoadNode::Road
    } else if city {
        RoadNode::City
    } else {
        RoadNode::Other
    }
}

pub(super) const fn road_edge(from: RoadNode, to: RoadNode) -> bool {
    matches!(
        (from, to),
        (RoadNode::Road, RoadNode::Road | RoadNode::City) | (RoadNode::City, RoadNode::Road)
    )
}

#[cfg(test)]
mod tests;
