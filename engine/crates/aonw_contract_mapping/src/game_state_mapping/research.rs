use aonw_contracts::{
    PlayerResearchStateDto, ResearchStateDto, TechnologyIdDto, WonderRegistryDto, WonderTypeDto,
};
use aonw_domain::{
    KnowledgeState, MatchIdentity, PlayerId, PlayerResearchState, PlayerResearchStateBuildError,
    ResearchState, TechnologyId, WonderRegistry, WonderType,
};

use super::error::GameStateMappingError;

pub(super) fn decode_knowledge(
    identity: &MatchIdentity,
    research: ResearchStateDto,
    wonders: WonderRegistryDto,
) -> Result<KnowledgeState, GameStateMappingError> {
    let mut players = Vec::with_capacity(research.players.len());
    for (player, state) in research.players {
        let path = format!("$.research.players.{player}");
        let player = decode_player_id(player, &path)?;
        require_participant(identity, &player, &path)?;
        players.push((player, decode_player_research(state, &path)?));
    }
    let research = ResearchState::try_new(players).map_err(|player| {
        GameStateMappingError::new(
            "$.research.players",
            format!("duplicate player research: {player}"),
        )
    })?;

    let mut completed = Vec::with_capacity(wonders.0.len());
    for (wonder, player) in wonders.0 {
        let path = format!("$.wonderRegistry.{}", wonder_key(wonder));
        let player = decode_player_id(player, &path)?;
        require_participant(identity, &player, &path)?;
        completed.push((decode_wonder(wonder), player));
    }
    let wonder_registry = WonderRegistry::try_new(completed).map_err(|wonder| {
        GameStateMappingError::new(
            "$.wonderRegistry",
            format!("duplicate completed wonder: {wonder:?}"),
        )
    })?;
    Ok(KnowledgeState::new(research, wonder_registry))
}

const fn wonder_key(value: WonderTypeDto) -> &'static str {
    match value {
        WonderTypeDto::GreatLibrary => "greatLibrary",
        WonderTypeDto::HangingGardens => "hangingGardens",
        WonderTypeDto::GreatWall => "greatWall",
        WonderTypeDto::Petra => "petra",
        WonderTypeDto::CentralBank => "centralBank",
        WonderTypeDto::ImperialUniversity => "imperialUniversity",
        WonderTypeDto::GrandCathedral => "grandCathedral",
        WonderTypeDto::MotherFactory => "motherFactory",
        WonderTypeDto::NationalObservatory => "nationalObservatory",
        WonderTypeDto::SvalbardSeedVault => "svalbardSeedVault",
        WonderTypeDto::GrandExposition => "grandExposition",
    }
}

#[must_use]
pub(super) fn encode_research(value: &ResearchState) -> ResearchStateDto {
    ResearchStateDto {
        players: value
            .players()
            .iter()
            .map(|(player, state)| {
                (
                    player.as_str().to_owned(),
                    PlayerResearchStateDto {
                        unlocked_technology_ids: state
                            .unlocked_technology_ids()
                            .iter()
                            .copied()
                            .map(encode_technology)
                            .collect(),
                        active_technology_id: state.active_technology_id().map(encode_technology),
                        progress_by_technology_id: state
                            .progress_by_technology_id()
                            .iter()
                            .map(|(technology, progress)| {
                                (encode_technology(*technology), *progress)
                            })
                            .collect(),
                        science_overflow: state.science_overflow(),
                    },
                )
            })
            .collect(),
    }
}

#[must_use]
pub(super) fn encode_wonder_registry(value: &WonderRegistry) -> WonderRegistryDto {
    WonderRegistryDto(
        value
            .completed_by()
            .iter()
            .map(|(wonder, player)| (encode_wonder(*wonder), player.as_str().to_owned()))
            .collect(),
    )
}

fn decode_player_research(
    value: PlayerResearchStateDto,
    path: &str,
) -> Result<PlayerResearchState, GameStateMappingError> {
    PlayerResearchState::try_new(
        value
            .unlocked_technology_ids
            .into_iter()
            .map(decode_technology),
        value.active_technology_id.map(decode_technology),
        value
            .progress_by_technology_id
            .into_iter()
            .map(|(technology, progress)| (decode_technology(technology), progress)),
        value.science_overflow,
    )
    .map_err(|error| map_player_research_error(path, error))
}

fn map_player_research_error(
    path: &str,
    error: PlayerResearchStateBuildError,
) -> GameStateMappingError {
    let field = match error {
        PlayerResearchStateBuildError::DuplicateUnlocked(_) => "unlockedTechnologyIds",
        PlayerResearchStateBuildError::ActiveAlreadyUnlocked(_) => "activeTechnologyId",
        PlayerResearchStateBuildError::DuplicateProgress(_)
        | PlayerResearchStateBuildError::NonPositiveProgress { .. }
        | PlayerResearchStateBuildError::ProgressForUnlocked(_) => "progressByTechnologyId",
        PlayerResearchStateBuildError::NegativeScienceOverflow(_) => "scienceOverflow",
    };
    GameStateMappingError::new(format!("{path}.{field}"), error.to_string())
}

fn decode_player_id(value: String, path: &str) -> Result<PlayerId, GameStateMappingError> {
    PlayerId::new(value).map_err(|error| GameStateMappingError::new(path, error.to_string()))
}

fn require_participant(
    identity: &MatchIdentity,
    player: &PlayerId,
    path: &str,
) -> Result<(), GameStateMappingError> {
    if identity.contains(player) {
        Ok(())
    } else {
        Err(GameStateMappingError::new(
            path,
            format!("knowledge state references non-participant: {player}"),
        ))
    }
}

macro_rules! enum_mapping {
    ($decode:ident, $encode:ident, $dto:ident, $domain:ident; $($variant:ident),+ $(,)?) => {
        pub(super) const fn $decode(value: $dto) -> $domain {
            match value {
                $($dto::$variant => $domain::$variant),+
            }
        }

        pub(super) const fn $encode(value: $domain) -> $dto {
            match value {
                $($domain::$variant => $dto::$variant),+
            }
        }
    };
}

enum_mapping!(
    decode_wonder,
    encode_wonder,
    WonderTypeDto,
    WonderType;
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
);

enum_mapping!(
    decode_technology_inner,
    encode_technology_inner,
    TechnologyIdDto,
    TechnologyId;
    Agriculture,
    Woodworking,
    Mining,
    AnimalHusbandry,
    Hunting,
    Fishing,
    Craftsmanship,
    Trade,
    Storage,
    WaterEngineering,
    Stoneworking,
    MilitaryOrganization,
    AdvancedTrade,
    Construction,
    Navigation,
    Irrigation,
    Banking,
    Engineering,
    Metallurgy,
    HorsebackRiding,
    IronWorking,
    CoalMining,
    Machinery,
    Administration,
    Logistics,
    Shipbuilding,
    Tactics,
    Economy,
    Urbanization,
    Fortifications,
    Strategy,
    Specialization,
    Writing,
    Mathematics,
    Medicine,
    CivilService,
    Siegecraft,
    Cartography,
    Guilds,
    Law,
    Education,
    UrbanPlanning,
    NavalDoctrine,
    Steel,
    Bureaucracy,
    Nationalism,
    ScientificMethod,
    SteamPower,
    Electricity,
    Combustion,
    Flight,
    MassProduction,
    Radio,
    NuclearPhysics,
);

/// Converts a current client technology identity into the domain identity.
#[must_use]
pub const fn decode_technology(value: TechnologyIdDto) -> TechnologyId {
    decode_technology_inner(value)
}

/// Converts a domain technology identity into the current client identity.
#[must_use]
pub const fn encode_technology(value: TechnologyId) -> TechnologyIdDto {
    encode_technology_inner(value)
}
