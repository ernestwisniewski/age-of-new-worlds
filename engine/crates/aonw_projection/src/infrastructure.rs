use aonw_content::{RulesetDefinition, TechnologyEra};
use aonw_domain::{
    FieldImprovementKind, FogVisibility, GameState, HexCoord, PlayerId, PlayerResearchState,
    TransportCondition,
};

/// Recipient-safe current field improvement.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct PlayerFieldImprovementView {
    coordinate: HexCoord,
    improvement: FieldImprovementKind,
    era_column: u8,
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

    /// Returns the deliberately coarse public visual era band (0 through 3).
    #[must_use]
    pub const fn era_column(self) -> u8 {
        self.era_column
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
    ruleset: &RulesetDefinition,
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
            era_column: improvement_owner(
                state,
                improvement.coordinate(),
                improvement.built_by_city_id(),
            )
            .map_or(0, |owner| visual_era_column(state, owner, ruleset)),
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

fn improvement_owner<'state>(
    state: &'state GameState,
    coordinate: HexCoord,
    built_by_city_id: Option<&aonw_domain::CityId>,
) -> Option<&'state PlayerId> {
    built_by_city_id
        .and_then(|city_id| state.city(city_id))
        .or_else(|| {
            state
                .cities()
                .iter()
                .find(|city| city.controlled_hexes().contains(&coordinate))
        })
        .map(aonw_domain::City::owner_player_id)
}

fn visual_era_column(state: &GameState, owner: &PlayerId, ruleset: &RulesetDefinition) -> u8 {
    state
        .research()
        .players()
        .get(owner)
        .map_or(0, |research| era_column_for_research(research, ruleset))
}

fn era_column_for_research(research: &PlayerResearchState, ruleset: &RulesetDefinition) -> u8 {
    match crate::research::dominant_era_for_research(research, ruleset) {
        TechnologyEra::Foundation | TechnologyEra::Settlement => 0,
        TechnologyEra::Expansion | TechnologyEra::Specialization => 1,
        TechnologyEra::Industry => 2,
        TechnologyEra::Strategy => 3,
    }
}

fn known_coordinate(state: &GameState, actor: &PlayerId, coordinate: HexCoord) -> bool {
    state.fog_of_war().visibility(actor, coordinate) != FogVisibility::Hidden
}

#[cfg(test)]
mod tests {
    use aonw_content::RulesetDefinition;
    use aonw_domain::{PlayerResearchState, TechnologyId};

    use super::era_column_for_research;

    #[test]
    fn visual_era_uses_the_highest_unlocked_technology_band() {
        let ruleset = RulesetDefinition::standard();
        let cases = [
            (TechnologyId::Agriculture, 0),
            (TechnologyId::AdvancedTrade, 1),
            (TechnologyId::CoalMining, 2),
            (TechnologyId::Strategy, 3),
        ];

        for (technology, expected) in cases {
            let research = PlayerResearchState::try_new([technology], None, [], 0)
                .expect("valid research state");
            assert_eq!(era_column_for_research(&research, ruleset), expected);
        }
    }

    #[test]
    fn visual_era_defaults_to_the_early_asset_band() {
        assert_eq!(
            era_column_for_research(
                &PlayerResearchState::default(),
                RulesetDefinition::standard(),
            ),
            0,
        );
    }
}
