use aonw_domain::{
    FieldImprovementKind, FogVisibility, GameState, HexCoord, PlayerId, TransportCondition,
};

/// Recipient-safe current field improvement.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct PlayerFieldImprovementView {
    coordinate: HexCoord,
    improvement: FieldImprovementKind,
}

impl PlayerFieldImprovementView {
    /// Returns the improved coordinate.
    #[must_use]
    pub const fn coordinate(self) -> HexCoord {
        self.coordinate
    }

    /// Returns the improvement identity.
    #[must_use]
    pub const fn improvement(self) -> FieldImprovementKind {
        self.improvement
    }
}

/// Recipient-safe dynamic road segment.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct PlayerRoadView {
    coordinate: HexCoord,
    condition: TransportCondition,
}

impl PlayerRoadView {
    /// Returns the road coordinate.
    #[must_use]
    pub const fn coordinate(self) -> HexCoord {
        self.coordinate
    }

    /// Returns current road condition.
    #[must_use]
    pub const fn condition(self) -> TransportCondition {
        self.condition
    }
}

pub(crate) fn visible_infrastructure(
    state: &GameState,
    actor: &PlayerId,
) -> (Vec<PlayerFieldImprovementView>, Vec<PlayerRoadView>) {
    let improvements = state
        .field_improvements()
        .iter()
        .filter(|improvement| {
            known_coordinate(state, actor, improvement.coordinate())
                || improvement.built_by_city_id().is_some_and(|city_id| {
                    state
                        .city(city_id)
                        .is_some_and(|city| city.owner_player_id() == actor)
                })
        })
        .map(|improvement| PlayerFieldImprovementView {
            coordinate: improvement.coordinate(),
            improvement: improvement.kind(),
        })
        .collect::<Vec<_>>();

    let roads = state
        .transport_network()
        .segments()
        .iter()
        .filter(|segment| {
            segment.built_by_player_id() == actor
                || known_coordinate(state, actor, segment.coordinate())
        })
        .map(|segment| PlayerRoadView {
            coordinate: segment.coordinate(),
            condition: segment.condition(),
        })
        .collect::<Vec<_>>();
    (improvements, roads)
}

fn known_coordinate(state: &GameState, actor: &PlayerId, coordinate: HexCoord) -> bool {
    state.fog_of_war().visibility(actor, coordinate) != FogVisibility::Hidden
}
