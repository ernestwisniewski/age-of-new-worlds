use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    CityId, FieldImprovementKind, GameState, HexCoord, PlayerId, ResourceType, UnitKind,
};
use aonw_engine::{
    CanonicalQueryError, EconomyForecastQuery, EngineContext, GameEngine, GameQuery, QueryResult,
    StabilityBand, StrategicResourceProjectionQuery,
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

/// One recipient-owned city contribution to the gold forecast.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerGoldIncomeSourceView {
    city_id: CityId,
    amount: i64,
}

impl PlayerGoldIncomeSourceView {
    /// Returns the contributing city.
    #[must_use]
    pub const fn city_id(&self) -> &CityId {
        &self.city_id
    }

    /// Returns the positive contribution.
    #[must_use]
    pub const fn amount(&self) -> i64 {
        self.amount
    }
}

/// One charged unit-kind group in the recipient's upkeep forecast.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct PlayerUnitUpkeepSourceView {
    kind: UnitKind,
    paid_unit_count: i64,
    amount: i64,
}

impl PlayerUnitUpkeepSourceView {
    /// Returns the charged unit type.
    #[must_use]
    pub const fn kind(self) -> UnitKind {
        self.kind
    }
    /// Returns the paid count of this type.
    #[must_use]
    pub const fn paid_unit_count(self) -> i64 {
        self.paid_unit_count
    }
    /// Returns the combined upkeep of this type.
    #[must_use]
    pub const fn amount(self) -> i64 {
        self.amount
    }
}

/// Exact unit-upkeep allocation used by the next turn settlement.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerUnitUpkeepView {
    upkeep_bearing_unit_count: i64,
    free_unit_count: i64,
    paid_unit_count: i64,
    total: i64,
    next_worker_upkeep: i64,
    sources: Box<[PlayerUnitUpkeepSourceView]>,
}

impl PlayerUnitUpkeepView {
    /// Returns the count participating in upkeep allocation.
    #[must_use]
    pub const fn upkeep_bearing_unit_count(&self) -> i64 {
        self.upkeep_bearing_unit_count
    }
    /// Returns the free upkeep limit.
    #[must_use]
    pub const fn free_unit_count(&self) -> i64 {
        self.free_unit_count
    }
    /// Returns the count outside the free limit.
    #[must_use]
    pub const fn paid_unit_count(&self) -> i64 {
        self.paid_unit_count
    }
    /// Returns total upkeep.
    #[must_use]
    pub const fn total(&self) -> i64 {
        self.total
    }
    /// Returns the marginal displayed upkeep of the next worker.
    #[must_use]
    pub const fn next_worker_upkeep(&self) -> i64 {
        self.next_worker_upkeep
    }
    /// Returns charged groups in canonical unit-kind order.
    #[must_use]
    pub const fn sources(&self) -> &[PlayerUnitUpkeepSourceView] {
        &self.sources
    }
}

/// Recipient-safe evidence for current effective empire stability.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerStabilityBreakdownView {
    pub base_order: i64,
    pub building_sources: i64,
    pub luxury_sources: i64,
    pub technology_sources: i64,
    pub artifact_sources: i64,
    pub wonder_sources: i64,
    pub city_cost: i64,
    pub population_cost: i64,
    pub cohesion_cost: i64,
    pub conquered_city_cost: i64,
    pub war_weariness_cost: i64,
    pub hegemony_tax: i64,
    pub source_total: i64,
    pub cost_total: i64,
    pub relative_standing_adjustment: i64,
    pub effective_net: i64,
    pub band: StabilityBand,
}

/// Complete recipient-owned gold and stability forecast required by the legacy HUD.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerEconomyForecastView {
    pub treasury: i64,
    pub city_income: i64,
    pub project_income: i64,
    pub gross_income: i64,
    pub net_per_turn: i64,
    pub city_sources: Box<[PlayerGoldIncomeSourceView]>,
    pub project_sources: Box<[PlayerGoldIncomeSourceView]>,
    pub upkeep: PlayerUnitUpkeepView,
    pub stability: PlayerStabilityBreakdownView,
}

impl PlayerEconomyForecastView {
    fn from_engine(value: &aonw_engine::EconomyForecast) -> Self {
        let gold_source = |city_id: &CityId, amount| PlayerGoldIncomeSourceView {
            city_id: city_id.clone(),
            amount,
        };
        let upkeep = value.upkeep();
        let stability = value.stability();
        Self {
            treasury: value.treasury(),
            city_income: value.city_income(),
            project_income: value.project_income(),
            gross_income: value.gross_income(),
            net_per_turn: value.net_per_turn(),
            city_sources: value
                .city_sources()
                .iter()
                .map(|source| gold_source(source.city_id(), source.amount()))
                .collect(),
            project_sources: value
                .project_sources()
                .iter()
                .map(|source| gold_source(source.city_id(), source.amount()))
                .collect(),
            upkeep: PlayerUnitUpkeepView {
                upkeep_bearing_unit_count: upkeep.upkeep_bearing_unit_count(),
                free_unit_count: upkeep.free_unit_count(),
                paid_unit_count: upkeep.paid_unit_count(),
                total: upkeep.total(),
                next_worker_upkeep: upkeep.next_worker_upkeep(),
                sources: upkeep
                    .sources()
                    .iter()
                    .map(|source| PlayerUnitUpkeepSourceView {
                        kind: source.kind(),
                        paid_unit_count: source.paid_unit_count(),
                        amount: source.amount(),
                    })
                    .collect(),
            },
            stability: PlayerStabilityBreakdownView {
                base_order: stability.base_order(),
                building_sources: stability.building_sources(),
                luxury_sources: stability.luxury_sources(),
                technology_sources: stability.technology_sources(),
                artifact_sources: stability.artifact_sources(),
                wonder_sources: stability.wonder_sources(),
                city_cost: stability.city_cost(),
                population_cost: stability.population_cost(),
                cohesion_cost: stability.cohesion_cost(),
                conquered_city_cost: stability.conquered_city_cost(),
                war_weariness_cost: stability.war_weariness_cost(),
                hegemony_tax: stability.hegemony_tax(),
                source_total: stability.source_total(),
                cost_total: stability.cost_total(),
                relative_standing_adjustment: stability.relative_standing_adjustment(),
                effective_net: stability.effective_net(),
                band: stability.band(),
            },
        }
    }

    #[cfg(test)]
    fn empty() -> Self {
        Self {
            treasury: 0,
            city_income: 0,
            project_income: 0,
            gross_income: 0,
            net_per_turn: 0,
            city_sources: Box::new([]),
            project_sources: Box::new([]),
            upkeep: PlayerUnitUpkeepView {
                upkeep_bearing_unit_count: 0,
                free_unit_count: 0,
                paid_unit_count: 0,
                total: 0,
                next_worker_upkeep: 0,
                sources: Box::new([]),
            },
            stability: PlayerStabilityBreakdownView {
                base_order: 0,
                building_sources: 0,
                luxury_sources: 0,
                technology_sources: 0,
                artifact_sources: 0,
                wonder_sources: 0,
                city_cost: 0,
                population_cost: 0,
                cohesion_cost: 0,
                conquered_city_cost: 0,
                war_weariness_cost: 0,
                hegemony_tax: 0,
                source_total: 0,
                cost_total: 0,
                relative_standing_adjustment: 0,
                effective_net: 0,
                band: StabilityBand::Stable,
            },
        }
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
    forecast: PlayerEconomyForecastView,
}

impl PlayerEconomyView {
    pub(crate) fn try_for_recipient(
        state: &GameState,
        actor: &PlayerId,
        map: &MapDefinition,
        ruleset: &RulesetDefinition,
    ) -> Result<Self, CanonicalQueryError> {
        let context = EngineContext::canonical(actor, map, ruleset);
        let result = GameEngine::query(
            state,
            context,
            GameQuery::StrategicResourceProjection(StrategicResourceProjectionQuery::new(
                state.revision().get(),
            )),
        )?;
        let QueryResult::StrategicResourceProjection(projection) = result else {
            unreachable!("strategic resource query returned another result kind");
        };
        let result = GameEngine::query(
            state,
            context,
            GameQuery::EconomyForecast(EconomyForecastQuery::new(state.revision().get())),
        )?;
        let QueryResult::EconomyForecast(forecast) = result else {
            unreachable!("economy forecast query returned another result kind");
        };
        debug_assert_eq!(forecast.player_id(), actor);
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
            forecast: PlayerEconomyForecastView::from_engine(&forecast),
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
            forecast: PlayerEconomyForecastView::empty(),
        }
    }

    #[cfg(test)]
    pub(crate) const fn with_gold(mut self, gold: i64) -> Self {
        self.gold = gold;
        self.forecast.treasury = gold;
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

    /// Returns the complete authoritative top-resource forecast.
    #[must_use]
    pub const fn forecast(&self) -> &PlayerEconomyForecastView {
        &self.forecast
    }
}
