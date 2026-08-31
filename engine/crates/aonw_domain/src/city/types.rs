/// Building identity retained by canonical city state.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum CityBuildingType {
    Granary,
    WaterMill,
    Workshop,
    Storehouse,
    Housing,
    MerchantHall,
    Stonemason,
    Barracks,
    Marketplace,
    Port,
    Aqueduct,
    Forge,
    Stable,
    Bank,
    BuildersGuild,
    Factory,
    Lighthouse,
    TrainingGrounds,
    TownHall,
    Monument,
    Archive,
    Academy,
    University,
    Observatory,
    Laboratory,
    Reactor,
    Courthouse,
    Court,
    GovernorsOffice,
    SurveyorsOffice,
    PlanningOffice,
    Apothecary,
    PublicBaths,
    Hospital,
    Ministries,
    Walls,
    Armory,
    SiegeWorkshop,
    Citadel,
    WarCollege,
    ConscriptionOffice,
    BorderFort,
    Airfield,
    ArtisansGuild,
    MasterWorkshop,
    Steelworks,
    RailDepot,
    PowerPlant,
    AssemblyPlant,
    Refinery,
    MapRoom,
    Shipyard,
    DryDock,
    NavalAcademy,
    HarborCustoms,
    Museum,
    Parliament,
    BroadcastTower,
    WorldFairGrounds,
}

/// Wonder identity retained by canonical city state.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum WonderType {
    GreatLibrary,
    HangingGardens,
    GreatWall,
    Petra,
    CentralBank,
    ImperialUniversity,
    GrandCathedral,
    MotherFactory,
    NationalObservatory,
    SvalbardSeedVault,
    GrandExposition,
}

/// Repeatable city project.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum CityProjectType {
    Wealth,
    Research,
}

/// Optional city specialization.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum CitySpecializationType {
    Growth,
    Industry,
    Commerce,
    Science,
    Military,
}
