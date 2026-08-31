//! Executes canonical command fixtures directly through the Rust engine.

use std::{fmt, fs};

use aonw_content::RulesetDefinition;
use aonw_contract_mapping::{
    canonicalize_game_state, decode_city_building, decode_city_project, decode_city_specialization,
    decode_city_wonder, decode_game_state, decode_troop, decode_unit_kind, encode_game_state,
};
use aonw_contracts::{GameStateDto, ReplayCommandDto};
use aonw_domain::{CityConquestAction, CityId, HexCoord, PlayerId, UnitId};
use aonw_engine::{
    AssignMerchantTradeRouteCommand, AttackHexCommand, AutoExploreUnitCommand, DetachTroopCommand,
    EngineContext, GameEngine, MoveMerchantToCityCommand, MoveUnitCommand, PlayerCommand,
    RushProductionCommand, SetCitySpecializationCommand, StartBuildingCommand,
    StartCityProjectCommand, StartUnitProductionCommand, StartWonderCommand, UnitActionCommand,
};
use aonw_testkit::{
    CanonicalFixtureExecutor, CanonicalFixtureInput, CanonicalFixtureLoader,
    CanonicalFixtureOutput, verify_canonical_corpus,
};

#[path = "canonical_fixture_engine/artifact.rs"]
mod artifact;
#[path = "canonical_fixture_engine/city.rs"]
mod city;
#[path = "canonical_fixture_engine/diplomacy.rs"]
mod diplomacy;
#[path = "canonical_fixture_engine/encoding.rs"]
mod encoding;
#[path = "canonical_fixture_engine/path.rs"]
mod path;
#[path = "canonical_fixture_engine/research.rs"]
mod research;
#[path = "canonical_fixture_engine/review.rs"]
mod review;
#[path = "canonical_fixture_engine/turn.rs"]
mod turn;
#[path = "canonical_fixture_engine/worker.rs"]
mod worker;

use encoding::{encode_event, encode_evidence};
use path::repository_root;

#[derive(Debug)]
struct ExecutionError(String);

impl fmt::Display for ExecutionError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(&self.0)
    }
}

impl std::error::Error for ExecutionError {}
struct CanonicalRustEngineExecutor;
const CANONICAL_COMMAND_FIXTURE_COUNT: usize = 44;

impl CanonicalFixtureExecutor for CanonicalRustEngineExecutor {
    type Error = ExecutionError;

    fn execute(
        &self,
        _fixture_id: &str,
        _capability: &str,
        input: &CanonicalFixtureInput,
    ) -> Result<CanonicalFixtureOutput, Self::Error> {
        let state = decode_game_state(input.state().clone()).map_err(display_error)?;
        let actor = PlayerId::new(input.actor_player_id()).map_err(display_error)?;
        let map = input.map();
        let context = EngineContext::canonical(&actor, map, RulesetDefinition::standard());
        let transition = apply_command(state, context, input.command())?;
        let output_state = encode_game_state(transition.state());
        if let Some(rejection) = transition.rejection() {
            return Ok(CanonicalFixtureOutput::reject(
                rejection.code().as_str(),
                output_state,
            ));
        }
        Ok(CanonicalFixtureOutput::accept(
            output_state,
            transition
                .events()
                .iter()
                .map(encode_event)
                .collect::<Vec<_>>(),
            transition.evidence().map(encode_evidence),
        ))
    }
}

#[allow(clippy::too_many_lines)]
fn apply_command(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    command: &ReplayCommandDto,
) -> Result<aonw_engine::DomainTransition, ExecutionError> {
    match command {
        command @ ReplayCommandDto::SelectTechnology { .. } => {
            research::apply(state, context, command)
        }
        command @ (ReplayCommandDto::DeclareWar { .. }
        | ReplayCommandDto::SendGoldGift { .. }
        | ReplayCommandDto::OpenResourceTrade { .. }
        | ReplayCommandDto::OpenResourceExchange { .. }
        | ReplayCommandDto::SendDiplomaticProposal { .. }
        | ReplayCommandDto::RespondDiplomaticProposal { .. }
        | ReplayCommandDto::SendDiplomaticMessage { .. }
        | ReplayCommandDto::RespondDiplomaticMessage { .. }) => {
            diplomacy::apply(state, context, command)
        }
        command @ (ReplayCommandDto::StartArtifactExcavation { .. }
        | ReplayCommandDto::StoreArtifactInCity { .. }
        | ReplayCommandDto::TradeArtifact { .. }) => artifact::apply(state, context, command),
        ReplayCommandDto::FoundCity {
            expected_revision,
            founder_unit_id,
            controlled_hexes,
        } => city::apply_found(
            state,
            context,
            *expected_revision,
            founder_unit_id,
            controlled_hexes,
        ),
        ReplayCommandDto::ToggleWorkedHex {
            expected_revision,
            city_id,
            target,
        } => city::apply_toggle_worked(state, context, *expected_revision, city_id, *target),
        ReplayCommandDto::SelectCityExpansionHex {
            expected_revision,
            city_id,
            target,
        } => city::apply_select_expansion(state, context, *expected_revision, city_id, *target),
        ReplayCommandDto::StartBuilding {
            expected_revision,
            city_id,
            building,
        } => {
            let city_id = CityId::new(city_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::StartBuilding(StartBuildingCommand::new(
                    *expected_revision,
                    &city_id,
                    decode_city_building(*building),
                )),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::StartUnitProduction {
            expected_revision,
            city_id,
            unit,
            resource_option_index,
        } => {
            let city_id = CityId::new(city_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::StartUnitProduction(StartUnitProductionCommand::new(
                    *expected_revision,
                    &city_id,
                    decode_unit_kind(*unit),
                    *resource_option_index,
                )),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::StartCityProject {
            expected_revision,
            city_id,
            project,
        } => {
            let city_id = CityId::new(city_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::StartCityProject(StartCityProjectCommand::new(
                    *expected_revision,
                    &city_id,
                    decode_city_project(*project),
                )),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::StartWonder {
            expected_revision,
            city_id,
            wonder,
        } => {
            let city_id = CityId::new(city_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::StartWonder(StartWonderCommand::new(
                    *expected_revision,
                    &city_id,
                    decode_city_wonder(*wonder),
                )),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::SetCitySpecialization {
            expected_revision,
            city_id,
            specialization,
        } => {
            let city_id = CityId::new(city_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::SetCitySpecialization(SetCitySpecializationCommand::new(
                    *expected_revision,
                    &city_id,
                    decode_city_specialization(*specialization),
                )),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::RushProduction {
            expected_revision,
            city_id,
        } => {
            let city_id = CityId::new(city_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::RushProduction(RushProductionCommand::new(
                    *expected_revision,
                    &city_id,
                )),
            )
            .map_err(display_error)
        }
        command @ (ReplayCommandDto::SelectWorkerImprovement { .. }
        | ReplayCommandDto::ConfirmWorkerImprovement { .. }
        | ReplayCommandDto::CancelWorkerJob { .. }
        | ReplayCommandDto::AssignWorkerToHex { .. }
        | ReplayCommandDto::CancelWorkerAssignment { .. }
        | ReplayCommandDto::BuildRoad { .. }
        | ReplayCommandDto::AutomateWorker { .. }) => worker::apply(state, context, command),
        ReplayCommandDto::AttackHex {
            expected_revision,
            attacker_unit_id,
            defender,
            city_conquest_action,
        } => {
            let attacker_unit_id = UnitId::new(attacker_unit_id.as_str()).map_err(display_error)?;
            let action = match city_conquest_action {
                aonw_contracts::CityConquestActionDto::Capture => CityConquestAction::Capture,
                aonw_contracts::CityConquestActionDto::Destroy => CityConquestAction::Destroy,
            };
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::AttackHex(
                    AttackHexCommand::new(
                        *expected_revision,
                        &attacker_unit_id,
                        HexCoord::new(defender.col, defender.row),
                    )
                    .with_city_conquest_action(action),
                ),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::MoveUnit {
            expected_revision,
            unit_id,
            target,
        } => apply_move_command(state, context, *expected_revision, unit_id, *target),
        ReplayCommandDto::AutoExploreUnit {
            expected_revision,
            unit_id,
        } => apply_auto_explore(state, context, *expected_revision, unit_id),
        ReplayCommandDto::AssignMerchantTradeRoute {
            expected_revision,
            unit_id,
            destination_city_id,
        } => apply_merchant_command(
            state,
            context,
            *expected_revision,
            unit_id,
            destination_city_id,
            true,
        ),
        ReplayCommandDto::MoveMerchantToCity {
            expected_revision,
            unit_id,
            destination_city_id,
        } => apply_merchant_command(
            state,
            context,
            *expected_revision,
            unit_id,
            destination_city_id,
            false,
        ),
        ReplayCommandDto::DetachTroop {
            expected_revision,
            unit_id,
            troop_kind,
        } => apply_detachment(state, context, *expected_revision, unit_id, *troop_kind),
        ReplayCommandDto::CancelUnitAction {
            expected_revision,
            unit_id,
        } => apply_unit_action(
            state,
            context,
            *expected_revision,
            unit_id,
            FixtureUnitAction::Cancel,
        ),
        ReplayCommandDto::SkipUnitTurn {
            expected_revision,
            unit_id,
        } => apply_unit_action(
            state,
            context,
            *expected_revision,
            unit_id,
            FixtureUnitAction::Skip,
        ),
        ReplayCommandDto::FortifyUnit {
            expected_revision,
            unit_id,
        } => apply_unit_action(
            state,
            context,
            *expected_revision,
            unit_id,
            FixtureUnitAction::Fortify,
        ),
        command @ (ReplayCommandDto::EndTurn { .. } | ReplayCommandDto::SubmitTurn { .. }) => {
            turn::apply(state, context, command)
        }
    }
}

fn apply_move_command(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    expected_revision: u64,
    unit_id: &str,
    target: aonw_contracts::CoordinateDto,
) -> Result<aonw_engine::DomainTransition, ExecutionError> {
    let unit_id = UnitId::new(unit_id).map_err(display_error)?;
    GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::MoveUnit(MoveUnitCommand::new(
            expected_revision,
            &unit_id,
            HexCoord::new(target.col, target.row),
        )),
    )
    .map_err(display_error)
}

fn apply_auto_explore(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    expected_revision: u64,
    unit_id: &str,
) -> Result<aonw_engine::DomainTransition, ExecutionError> {
    let unit_id = UnitId::new(unit_id).map_err(display_error)?;
    GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::AutoExploreUnit(AutoExploreUnitCommand::new(expected_revision, &unit_id)),
    )
    .map_err(display_error)
}

fn apply_detachment(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    expected_revision: u64,
    unit_id: &str,
    troop_kind: aonw_contracts::TroopKindDto,
) -> Result<aonw_engine::DomainTransition, ExecutionError> {
    let unit_id = UnitId::new(unit_id).map_err(display_error)?;
    GameEngine::apply_player_owned(
        state,
        context,
        PlayerCommand::DetachTroop(DetachTroopCommand::new(
            expected_revision,
            &unit_id,
            decode_troop(troop_kind),
        )),
    )
    .map_err(display_error)
}

fn apply_merchant_command(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    expected_revision: u64,
    unit_id: &str,
    destination_city_id: &str,
    cyclic: bool,
) -> Result<aonw_engine::DomainTransition, ExecutionError> {
    let unit_id = UnitId::new(unit_id).map_err(display_error)?;
    let city_id = CityId::new(destination_city_id).map_err(display_error)?;
    let command = if cyclic {
        PlayerCommand::AssignMerchantTradeRoute(AssignMerchantTradeRouteCommand::new(
            expected_revision,
            &unit_id,
            &city_id,
        ))
    } else {
        PlayerCommand::MoveMerchantToCity(MoveMerchantToCityCommand::new(
            expected_revision,
            &unit_id,
            &city_id,
        ))
    };
    GameEngine::apply_player_owned(state, context, command).map_err(display_error)
}

#[derive(Clone, Copy)]
enum FixtureUnitAction {
    Cancel,
    Skip,
    Fortify,
}

fn apply_unit_action(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    expected_revision: u64,
    unit_id: &str,
    action: FixtureUnitAction,
) -> Result<aonw_engine::DomainTransition, ExecutionError> {
    let unit_id = UnitId::new(unit_id).map_err(display_error)?;
    let command = UnitActionCommand::new(expected_revision, &unit_id);
    let command = match action {
        FixtureUnitAction::Cancel => PlayerCommand::CancelUnitAction(command),
        FixtureUnitAction::Skip => PlayerCommand::SkipUnitTurn(command),
        FixtureUnitAction::Fortify => PlayerCommand::FortifyUnit(command),
    };
    GameEngine::apply_player_owned(state, context, command).map_err(display_error)
}

fn display_error(error: impl fmt::Display) -> ExecutionError {
    ExecutionError(error.to_string())
}

#[test]
fn rust_executes_the_canonical_command_corpus() {
    let fixture_dir = repository_root().join("engine/fixtures/canonical_commands");
    let fixtures = CanonicalFixtureLoader::default()
        .load_corpus(fixture_dir)
        .expect("canonical command corpus must load");

    assert_eq!(fixtures.len(), CANONICAL_COMMAND_FIXTURE_COUNT);
    assert!(
        fixtures
            .iter()
            .all(|fixture| fixture.fixture_version() == 3)
    );
    for fixture in &fixtures {
        assert_eq!(
            canonicalize_game_state(fixture.input().state().clone())
                .expect("valid canonical input state"),
            *fixture.input().state(),
            "fixture {} input state is not canonically ordered",
            fixture.id()
        );
        assert_eq!(
            canonicalize_game_state(fixture.expected().state().clone())
                .expect("valid canonical expected state"),
            *fixture.expected().state(),
            "fixture {} expected state is not canonically ordered",
            fixture.id()
        );
    }
    verify_canonical_corpus(&fixtures, &CanonicalRustEngineExecutor)
        .unwrap_or_else(|failure| panic!("{failure:?}"));
}

#[test]
fn invalid_origin_is_rejected_at_the_canonical_state_boundary() {
    let path = repository_root()
        .join("engine/fixtures/canonical_state_rejections/unit-out-of-bounds.json");
    let source = fs::read(path).expect("canonical state rejection fixture");
    let dto = serde_json::from_slice::<GameStateDto>(&source).expect("strict state DTO");
    let error = decode_game_state(dto).expect_err("out-of-bounds state must fail closed");

    assert_eq!(error.path(), "$");
    assert!(error.to_string().contains("outside the map"));
}
