use aonw_domain::{EconomyState, GameState, ResourceTradeAgreement};

use super::super::*;

pub(super) fn inventory_state(
    research: ResearchState,
    oil: i64,
    allocated: i64,
    improved: bool,
    trades: Vec<ResourceTradeAgreement>,
) -> GameState {
    let map = resource_map();
    let first = player("player-1");
    let second = player("player-2");
    let own_city = City::builder(
        city_id("city-1"),
        first.clone(),
        "Capital",
        HexCoord::new(0, 0),
    )
    .with_controlled_hexes([HexCoord::new(1, 0)])
    .with_production(Some(queue(allocated, ResourceType::Oil)), 0)
    .build()
    .unwrap();
    let rival_city = City::builder(
        city_id("city-2"),
        second.clone(),
        "Rival",
        HexCoord::new(2, 0),
    )
    .with_production(Some(queue(99, ResourceType::Aluminium)), 0)
    .build()
    .unwrap();
    let improvements = improved.then(|| {
        FieldImprovement::new(
            HexCoord::new(1, 0),
            FieldImprovementKind::OilWell,
            Some(city_id("city-1")),
        )
    });
    let base = state_with_resource_parts(
        &map,
        Vec::new(),
        vec![rival_city, own_city],
        InteractionState::default(),
        InfrastructureState::try_new(improvements, TransportNetwork::default()).unwrap(),
        Vec::new(),
        InitialResourceDistribution::try_new(
            0,
            [
                InitialResourcePlacement::new(HexCoord::new(1, 0), ResourceType::Oil),
                InitialResourcePlacement::new(HexCoord::new(2, 0), ResourceType::Aluminium),
            ],
        )
        .unwrap(),
        research,
    );
    let identity = base.match_lifecycle().identity();
    let economy = EconomyState::try_new(
        identity,
        base.bounds(),
        BTreeMap::new(),
        BTreeMap::new(),
        BTreeMap::new(),
        BTreeMap::from([
            (first, stockpile(oil, ResourceType::Oil)),
            (second, stockpile(99, ResourceType::Aluminium)),
        ]),
        base.economy().initial_resource_distribution().clone(),
    )
    .unwrap();
    let diplomacy = base
        .diplomacy()
        .try_with_resource_trades(identity, trades)
        .unwrap();
    GameState::builder(
        base.revision(),
        base.turn(),
        base.bounds(),
        base.occupancy_policy(),
        [],
    )
    .with_match_lifecycle(base.match_lifecycle().clone())
    .with_cities(base.cities().iter().cloned())
    .with_knowledge(base.knowledge().clone())
    .with_infrastructure(base.infrastructure().clone())
    .with_economy(economy)
    .with_diplomacy(diplomacy)
    .try_build()
    .unwrap()
}

fn queue(amount: i64, resource: ResourceType) -> CityProductionQueue {
    CityProductionQueue::try_new(
        CityProductionTarget::Unit(UnitKind::Tank),
        0,
        stockpile(amount, resource),
    )
    .unwrap()
}

fn stockpile(amount: i64, resource: ResourceType) -> StrategicResourceStockpile {
    StrategicResourceStockpile::try_new(if amount == 0 {
        BTreeMap::new()
    } else {
        BTreeMap::from([(resource, amount)])
    })
    .unwrap()
}

pub(super) fn advanced_research(owner: &str) -> ResearchState {
    ResearchState::try_new([(
        player(owner),
        PlayerResearchState::try_new(
            [
                TechnologyId::AnimalHusbandry,
                TechnologyId::CoalMining,
                TechnologyId::Combustion,
                TechnologyId::Flight,
                TechnologyId::NuclearPhysics,
                TechnologyId::MassProduction,
            ],
            None,
            [],
            0,
        )
        .unwrap(),
    )])
    .unwrap()
}

pub(super) fn trade(
    id: &str,
    resource: ResourceType,
    inbound: bool,
    amount: u32,
) -> ResourceTradeAgreement {
    let (exporter, importer) = if inbound {
        ("player-2", "player-1")
    } else {
        ("player-1", "player-2")
    };
    ResourceTradeAgreement::try_new(
        id.into(),
        player(exporter),
        player(importer),
        resource,
        0,
        3,
        amount,
        None,
    )
    .unwrap()
}
