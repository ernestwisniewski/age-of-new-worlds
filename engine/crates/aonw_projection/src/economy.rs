use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{FieldImprovementKind, GameState, HexCoord, PlayerId, ResourceType};
use aonw_engine::{
    CanonicalQueryError, EngineContext, GameEngine, GameQuery, QueryResult,
    StrategicResourceProjectionQuery,
};

/// One positive strategic-resource amount in canonical resource order.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct PlayerStrategicResourceAmountView {
    resource: ResourceType,
    amount: i64,
}

impl PlayerStrategicResourceAmountView {
    const fn new(resource: ResourceType, amount: i64) -> Self {
        Self { resource, amount }
    }

    /// Returns the strategic resource kind.
    #[must_use]
    pub const fn resource(self) -> ResourceType {
        self.resource
    }

    /// Returns the positive amount represented by this entry.
    #[must_use]
    pub const fn amount(self) -> i64 {
        self.amount
    }
}

/// One controlled, technology-visible strategic-resource extraction source.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerStrategicResourceSourceView {
    city_id: aonw_domain::CityId,
    coordinate: HexCoord,
    resource: ResourceType,
    improvement: FieldImprovementKind,
    amount_per_turn: i64,
}

impl PlayerStrategicResourceSourceView {
    /// Returns the recipient-owned city controlling this source.
    #[must_use]
    pub const fn city_id(&self) -> &aonw_domain::CityId {
        &self.city_id
    }

    /// Returns the improved map coordinate.
    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }

    /// Returns the extracted strategic resource.
    #[must_use]
    pub const fn resource(&self) -> ResourceType {
        self.resource
    }

    /// Returns the matching field improvement.
    #[must_use]
    pub const fn improvement(&self) -> FieldImprovementKind {
        self.improvement
    }

    /// Returns the amount credited on each economy turn.
    #[must_use]
    pub const fn amount_per_turn(&self) -> i64 {
        self.amount_per_turn
    }
}

/// Complete recipient-owned economy state required by the map HUD.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerEconomyView {
    gold: i64,
    war_weariness: i64,
    stability_net: i64,
    strategic_resource_stockpile: Box<[PlayerStrategicResourceAmountView]>,
    strategic_resource_output: Box<[PlayerStrategicResourceAmountView]>,
    strategic_resource_sources: Box<[PlayerStrategicResourceSourceView]>,
}

impl PlayerEconomyView {
    pub(crate) fn try_for_recipient(
        state: &GameState,
        actor: &PlayerId,
        map: &MapDefinition,
        ruleset: &RulesetDefinition,
    ) -> Result<Self, CanonicalQueryError> {
        let result = GameEngine::query(
            state,
            EngineContext::canonical(actor, map, ruleset),
            GameQuery::StrategicResourceProjection(StrategicResourceProjectionQuery::new(
                state.revision().get(),
            )),
        )?;
        let QueryResult::StrategicResourceProjection(projection) = result else {
            unreachable!("strategic resource query returned another result kind");
        };
        debug_assert_eq!(projection.player_id(), actor);
        let economy = state.economy();
        let strategic_resource_stockpile = economy
            .strategic_resources()
            .get(actor)
            .into_iter()
            .flat_map(aonw_domain::StrategicResourceStockpile::amounts)
            .map(|(resource, amount)| PlayerStrategicResourceAmountView::new(*resource, *amount))
            .collect::<Vec<_>>()
            .into_boxed_slice();
        let strategic_resource_output = projection
            .output()
            .iter()
            .map(|(resource, amount)| PlayerStrategicResourceAmountView::new(*resource, *amount))
            .collect::<Vec<_>>()
            .into_boxed_slice();
        let strategic_resource_sources = projection
            .sources()
            .iter()
            .map(|source| PlayerStrategicResourceSourceView {
                city_id: source.city_id().clone(),
                coordinate: source.coordinate(),
                resource: source.resource(),
                improvement: source.improvement(),
                amount_per_turn: source.amount_per_turn(),
            })
            .collect::<Vec<_>>()
            .into_boxed_slice();
        Ok(Self {
            gold: economy.player_gold().get(actor).copied().unwrap_or(0),
            war_weariness: economy
                .player_war_weariness()
                .get(actor)
                .copied()
                .unwrap_or(0),
            stability_net: economy
                .player_stability_net()
                .get(actor)
                .copied()
                .unwrap_or(0),
            strategic_resource_stockpile,
            strategic_resource_output,
            strategic_resource_sources,
        })
    }

    #[cfg(test)]
    pub(crate) fn empty() -> Self {
        Self {
            gold: 0,
            war_weariness: 0,
            stability_net: 0,
            strategic_resource_stockpile: Box::new([]),
            strategic_resource_output: Box::new([]),
            strategic_resource_sources: Box::new([]),
        }
    }

    #[cfg(test)]
    pub(crate) const fn with_gold(mut self, gold: i64) -> Self {
        self.gold = gold;
        self
    }

    /// Returns the recipient's current treasury balance.
    #[must_use]
    pub const fn gold(&self) -> i64 {
        self.gold
    }

    /// Returns the recipient's accumulated war weariness.
    #[must_use]
    pub const fn war_weariness(&self) -> i64 {
        self.war_weariness
    }

    /// Returns the recipient's persisted net empire stability.
    #[must_use]
    pub const fn stability_net(&self) -> i64 {
        self.stability_net
    }

    /// Returns positive transferable strategic-resource balances.
    #[must_use]
    pub const fn strategic_resource_stockpile(&self) -> &[PlayerStrategicResourceAmountView] {
        &self.strategic_resource_stockpile
    }

    /// Returns authoritative strategic-resource output per economy turn.
    #[must_use]
    pub const fn strategic_resource_output(&self) -> &[PlayerStrategicResourceAmountView] {
        &self.strategic_resource_output
    }

    /// Returns exact recipient-owned extraction sources.
    #[must_use]
    pub const fn strategic_resource_sources(&self) -> &[PlayerStrategicResourceSourceView] {
        &self.strategic_resource_sources
    }
}
