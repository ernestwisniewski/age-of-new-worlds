//! Public-boundary coverage for canonical city invariants.

use aonw_domain::{
    City, CityBuildError, CityBuilder, CityBuildingType, CityId, CityProductionQueue,
    CityProductionQueueBuildError, CityProductionTarget, CityProjectType, CitySpecializationType,
    HexCoord, PlayerId, StrategicResourceStockpile, WonderType,
};

fn city() -> CityBuilder {
    City::builder(
        CityId::new("city").expect("city id"),
        PlayerId::new("player").expect("player id"),
        "City",
        HexCoord::new(1, 1),
    )
}

#[test]
fn complete_city_rejects_duplicate_and_uncontrolled_coordinates() {
    assert_eq!(
        city().with_controlled_hexes([HexCoord::new(1, 1)]).build(),
        Err(CityBuildError::CenterInControlledHexes)
    );
    assert_eq!(
        city()
            .with_controlled_hexes([HexCoord::new(0, 1), HexCoord::new(0, 1)])
            .build(),
        Err(CityBuildError::DuplicateControlledHex(HexCoord::new(0, 1)))
    );
    assert_eq!(
        city()
            .with_controlled_hexes([HexCoord::new(0, 1)])
            .with_worked_hexes([HexCoord::new(2, 1)])
            .build(),
        Err(CityBuildError::WorkedHexNotControlled(HexCoord::new(2, 1)))
    );
}

#[test]
fn complete_city_rejects_invalid_numeric_state() {
    let cases = [
        (
            city().with_progression(0, 0, 6, 2).build(),
            CityBuildError::NonPositivePopulation(0),
        ),
        (
            city().with_progression(3, -1, 6, 2).build(),
            CityBuildError::NegativeStoredFood(-1),
        ),
        (
            city().with_progression(3, 0, 0, 2).build(),
            CityBuildError::NonPositiveMaxHexes(0),
        ),
        (
            city().with_progression(3, 0, 6, -1).build(),
            CityBuildError::NegativeTerritoryRadius(-1),
        ),
        (
            city().with_production(None, -1).build(),
            CityBuildError::NegativeProductionOverflow(-1),
        ),
        (
            city().with_hit_points(Some(0)).build(),
            CityBuildError::NonPositiveHitPoints(0),
        ),
    ];
    for (actual, expected) in cases {
        assert_eq!(actual, Err(expected));
    }
}

#[test]
fn production_queue_rejects_negative_investment() {
    assert_eq!(
        CityProductionQueue::try_new(
            CityProductionTarget::Project(CityProjectType::Wealth),
            -1,
            StrategicResourceStockpile::default(),
        ),
        Err(CityProductionQueueBuildError::NegativeInvestedProduction(
            -1
        ))
    );
}

#[test]
fn production_transition_helpers_preserve_canonical_city_state() {
    let queue = CityProductionQueue::try_new(
        CityProductionTarget::Project(CityProjectType::Research),
        4,
        StrategicResourceStockpile::default(),
    )
    .expect("queue");
    let updated_queue = queue
        .try_with_invested_production(9)
        .expect("updated queue");
    assert_eq!(updated_queue.target(), queue.target());
    assert_eq!(updated_queue.invested_production(), 9);
    assert_eq!(
        updated_queue.resource_allocation(),
        queue.resource_allocation()
    );

    let city = city().build().expect("city");
    assert_eq!(
        city.try_with_production(None, -1),
        Err(CityBuildError::NegativeProductionOverflow(-1))
    );
    let city = city
        .try_with_production(Some(updated_queue), 3)
        .expect("production")
        .with_specialization(Some(CitySpecializationType::Industry))
        .try_with_completed_building(CityBuildingType::Marketplace, 2)
        .expect("building")
        .try_with_completed_wonder(WonderType::GreatLibrary)
        .expect("wonder");
    assert_eq!(city.production_overflow(), 3);
    assert_eq!(
        city.specialization(),
        Some(CitySpecializationType::Industry)
    );
    assert!(city.buildings().contains(&CityBuildingType::Marketplace));
    assert!(city.wonders().contains(&WonderType::GreatLibrary));
    assert_eq!(city.max_hexes(), 8);
    assert_eq!(
        city.try_with_completed_building(CityBuildingType::Marketplace, 2),
        Err(CityBuildError::DuplicateBuilding(
            CityBuildingType::Marketplace
        ))
    );
    assert_eq!(
        city.try_with_completed_wonder(WonderType::GreatLibrary),
        Err(CityBuildError::DuplicateWonder(WonderType::GreatLibrary))
    );
}

#[test]
fn building_completion_rejects_invalid_capacity_effects() {
    let canonical_city = city().build().expect("city");
    assert_eq!(
        canonical_city.try_with_completed_building(CityBuildingType::Marketplace, -1),
        Err(CityBuildError::NegativeMaxHexesDelta(-1))
    );
    let canonical_city = city()
        .with_progression(3, 0, i64::MAX, 2)
        .build()
        .expect("large city");
    assert_eq!(
        canonical_city.try_with_completed_building(CityBuildingType::Marketplace, 1),
        Err(CityBuildError::MaxHexesOverflow)
    );
}
