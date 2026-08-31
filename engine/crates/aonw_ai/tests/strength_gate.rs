//! Pinned deterministic league for production AI tactical strength.

use std::collections::{BTreeMap, BTreeSet};

use aonw_ai::{
    AiDifficulty, AiPersona, AiProfile, BaselinePlanner, BaselinePlanningOutcome, PlannedCommand,
    RandomPlanner, RandomPlanningOutcome, StrategicPlanner, StrategicPlanningOutcome,
};
use aonw_domain::HexCoord;
use aonw_local_runtime::{ReachableRequest, RuntimeQuery, RuntimeQueryResult};
use serde_json::{Map, Value, json};

#[path = "strength_gate/fixture.rs"]
mod fixture;

const CORPUS_JSON: &str = include_str!("../../../fixtures/ai/strength-corpus.json");
const BASELINE_JSON: &str = include_str!("../../../fixtures/ai/strength-baseline.json");

#[derive(Clone, Debug)]
struct StrengthCase {
    id: String,
    cols: u16,
    rows: u16,
    actor: HexCoord,
    opponent: HexCoord,
    movement_units: u64,
}

struct Corpus {
    cases: Vec<StrengthCase>,
    random_seeds: Vec<u32>,
    thresholds: Thresholds,
}

struct Thresholds {
    minimum_default_vs_random_win_rate_basis_points: u64,
    maximum_baseline_losses_per_profile: u64,
    maximum_reference_losses_per_profile: u64,
    maximum_unhandled_decisions: u64,
    minimum_movement_family_usage: u64,
    difficulty_score_monotonic: bool,
}

#[derive(Default)]
struct Outcomes {
    wins: u64,
    draws: u64,
    losses: u64,
}

impl Outcomes {
    fn record(&mut self, own: u64, opponent: u64) {
        match own.cmp(&opponent) {
            core::cmp::Ordering::Greater => self.wins += 1,
            core::cmp::Ordering::Equal => self.draws += 1,
            core::cmp::Ordering::Less => self.losses += 1,
        }
    }

    fn json(&self) -> Value {
        json!({"wins": self.wins, "draws": self.draws, "losses": self.losses})
    }
}

#[derive(Default)]
struct ProfileReport {
    score_sum: u64,
    vs_random: Outcomes,
    vs_baseline: Outcomes,
    vs_reference: Outcomes,
    tactical_searches: u64,
    search_iterations: u64,
    quality_guarded_selections: u64,
}

struct OpponentScores {
    reference: u64,
    baseline: u64,
    random: Vec<u64>,
}

#[test]
fn production_profiles_pass_the_pinned_deterministic_strength_league() {
    let corpus = parse_corpus();
    let mut unhandled = 0;
    let mut movement_usage = 0;
    let opponents = corpus
        .cases
        .iter()
        .map(|case| {
            let reference = reference_score(case);
            let baseline = baseline_score(case, &mut unhandled, &mut movement_usage);
            assert_eq!(
                baseline, reference,
                "baseline drifted from the reference scorer in {}",
                case.id
            );
            let random = corpus
                .random_seeds
                .iter()
                .map(|seed| random_score(case, *seed, &mut unhandled, &mut movement_usage))
                .collect();
            OpponentScores {
                reference,
                baseline,
                random,
            }
        })
        .collect::<Vec<_>>();
    let mut reports = BTreeMap::new();
    for (name, difficulty) in difficulties() {
        let mut report = ProfileReport::default();
        for (case, opponents) in corpus.cases.iter().zip(&opponents) {
            let (score, search) =
                strategic_score(case, difficulty, &mut unhandled, &mut movement_usage);
            report.score_sum += score;
            report.vs_baseline.record(score, opponents.baseline);
            report.vs_reference.record(score, opponents.reference);
            if let Some((iterations, guarded)) = search {
                report.tactical_searches += 1;
                report.search_iterations += u64::from(iterations);
                report.quality_guarded_selections += u64::from(guarded);
            }
            for random in &opponents.random {
                report.vs_random.record(score, *random);
            }
        }
        reports.insert(name, report);
    }

    let report = report_json(&corpus, &reports, unhandled, movement_usage);
    enforce_thresholds(&corpus, &reports, unhandled, movement_usage);
    let expected: Value = serde_json::from_str(BASELINE_JSON).expect("strict strength baseline");
    exact_keys(
        &expected,
        &[
            "caseCount",
            "movementFamilyUsage",
            "profiles",
            "randomSampleCount",
            "unhandledDecisions",
        ],
    );
    assert_eq!(
        report,
        expected,
        "strength report changed:\n{}",
        serde_json::to_string_pretty(&report).expect("report JSON")
    );
}

fn strategic_score(
    case: &StrengthCase,
    difficulty: AiDifficulty,
    unhandled: &mut u64,
    movement_usage: &mut u64,
) -> (u64, Option<(u32, u32)>) {
    let mut runtime = fixture::opened(case);
    let outcome = StrategicPlanner
        .plan_with_profile(
            &mut runtime,
            AiProfile::new(difficulty, AiPersona::Balanced),
        )
        .expect("strategic strength plan");
    let StrategicPlanningOutcome::Planned(plan) = outcome else {
        eprintln!(
            "{} {difficulty:?}: strategic outcome was not planned",
            case.id
        );
        *unhandled += 1;
        return (0, None);
    };
    let PlannedCommand::MoveUnit(request) = plan.command() else {
        eprintln!(
            "{} {difficulty:?}: strategic family was {:?}",
            case.id,
            plan.command().family()
        );
        *unhandled += 1;
        return (0, None);
    };
    *movement_usage += 1;
    let search = plan.tactical_search().map(|evidence| {
        (
            evidence.stats().iterations(),
            evidence.stats().quality_guarded_selections(),
        )
    });
    (
        score_target(case, request.target, reference_distance(case)),
        search,
    )
}

fn baseline_score(case: &StrengthCase, unhandled: &mut u64, movement_usage: &mut u64) -> u64 {
    let mut runtime = fixture::opened(case);
    let mut planner = BaselinePlanner::default();
    let outcome = planner.plan(&mut runtime).expect("baseline strength plan");
    let BaselinePlanningOutcome::Planned(plan) = outcome else {
        eprintln!("{}: baseline outcome was not planned", case.id);
        *unhandled += 1;
        return 0;
    };
    let PlannedCommand::MoveUnit(request) = plan.command() else {
        eprintln!(
            "{}: baseline family was {:?}",
            case.id,
            plan.command().family()
        );
        *unhandled += 1;
        return 0;
    };
    *movement_usage += 1;
    score_target(case, request.target, reference_distance(case))
}

fn random_score(
    case: &StrengthCase,
    seed: u32,
    unhandled: &mut u64,
    movement_usage: &mut u64,
) -> u64 {
    let mut runtime = fixture::opened(case);
    let outcome = RandomPlanner::new(seed)
        .plan(&mut runtime)
        .expect("random strength plan");
    let RandomPlanningOutcome::Planned(plan) = outcome else {
        eprintln!("{} seed {seed}: random outcome was not planned", case.id);
        *unhandled += 1;
        return 0;
    };
    let PlannedCommand::MoveUnit(request) = plan.command() else {
        *unhandled += 1;
        return 0;
    };
    *movement_usage += 1;
    score_target(case, request.target, reference_distance(case))
}

fn reference_score(case: &StrengthCase) -> u64 {
    score_target(case, case.opponent, reference_distance(case))
}

fn reference_distance(case: &StrengthCase) -> u64 {
    let mut runtime = fixture::opened(case);
    let response = runtime
        .query(&RuntimeQuery::Reachable(ReachableRequest {
            expected_revision: 0,
            unit_id: fixture::unit_id(),
        }))
        .expect("reference reachable query");
    let RuntimeQueryResult::Reachable(reachable) = response else {
        panic!("reachable response")
    };
    reachable
        .tiles
        .iter()
        .map(|tile| tile.coordinate.distance_to(case.opponent))
        .min()
        .expect("reference legal target")
}

fn score_target(case: &StrengthCase, target: HexCoord, ideal_distance: u64) -> u64 {
    let initial = case.actor.distance_to(case.opponent);
    let possible = initial.saturating_sub(ideal_distance);
    let achieved = initial.saturating_sub(target.distance_to(case.opponent));
    achieved
        .min(possible)
        .saturating_mul(10_000)
        .checked_div(possible)
        .unwrap_or(10_000)
}

fn enforce_thresholds(
    corpus: &Corpus,
    reports: &BTreeMap<&'static str, ProfileReport>,
    unhandled: u64,
    movement_usage: u64,
) {
    let thresholds = &corpus.thresholds;
    assert!(unhandled <= thresholds.maximum_unhandled_decisions);
    assert!(movement_usage >= thresholds.minimum_movement_family_usage);
    let default = &reports["normal"].vs_random;
    let samples = default.wins + default.draws + default.losses;
    let win_rate = default.wins.saturating_mul(10_000) / samples;
    assert!(win_rate >= thresholds.minimum_default_vs_random_win_rate_basis_points);
    for report in reports.values() {
        assert!(report.vs_baseline.losses <= thresholds.maximum_baseline_losses_per_profile);
        assert!(report.vs_reference.losses <= thresholds.maximum_reference_losses_per_profile);
    }
    if thresholds.difficulty_score_monotonic {
        for pair in difficulties().windows(2) {
            assert!(
                reports[pair[1].0].score_sum >= reports[pair[0].0].score_sum,
                "{} is weaker than {}",
                pair[1].0,
                pair[0].0
            );
        }
    }
}

fn report_json(
    corpus: &Corpus,
    reports: &BTreeMap<&'static str, ProfileReport>,
    unhandled: u64,
    movement_usage: u64,
) -> Value {
    let profiles = reports
        .iter()
        .map(|(name, report)| {
            (
                (*name).to_owned(),
                json!({
                    "normalizedScoreBasisPoints": report.score_sum / corpus.cases.len() as u64,
                    "vsRandom": report.vs_random.json(),
                    "vsBaseline": report.vs_baseline.json(),
                    "vsReference": report.vs_reference.json(),
                    "tacticalSearches": report.tactical_searches,
                    "searchIterations": report.search_iterations,
                    "qualityGuardedSelections": report.quality_guarded_selections
                }),
            )
        })
        .collect::<Map<_, _>>();
    json!({
        "caseCount": corpus.cases.len(),
        "randomSampleCount": corpus.cases.len() * corpus.random_seeds.len(),
        "unhandledDecisions": unhandled,
        "movementFamilyUsage": movement_usage,
        "profiles": profiles
    })
}

fn parse_corpus() -> Corpus {
    let root: Value = serde_json::from_str(CORPUS_JSON).expect("strict strength corpus");
    exact_keys(
        &root,
        &[
            "capability",
            "cases",
            "evaluation",
            "randomSeeds",
            "thresholds",
        ],
    );
    assert_eq!(root["capability"], "deterministic-ai-strength-gate");
    assert_eq!(root["evaluation"], "legal-move-progress-basis-points");
    let cases = array(&root["cases"])
        .iter()
        .map(parse_case)
        .collect::<Vec<_>>();
    assert!(cases.windows(2).all(|pair| pair[0].id < pair[1].id));
    let random_seeds = array(&root["randomSeeds"])
        .iter()
        .map(|value| u32::try_from(number(value)).expect("bounded random seed"))
        .collect::<Vec<_>>();
    assert_eq!(
        random_seeds.iter().copied().collect::<BTreeSet<_>>().len(),
        random_seeds.len()
    );
    Corpus {
        cases,
        random_seeds,
        thresholds: parse_thresholds(&root["thresholds"]),
    }
}

fn parse_case(value: &Value) -> StrengthCase {
    exact_keys(
        value,
        &["actor", "cols", "id", "movementUnits", "opponent", "rows"],
    );
    StrengthCase {
        id: string(&value["id"]).to_owned(),
        cols: u16::try_from(number(&value["cols"])).expect("bounded cols"),
        rows: u16::try_from(number(&value["rows"])).expect("bounded rows"),
        actor: coordinate(&value["actor"]),
        opponent: coordinate(&value["opponent"]),
        movement_units: number(&value["movementUnits"]),
    }
}

fn parse_thresholds(value: &Value) -> Thresholds {
    exact_keys(
        value,
        &[
            "difficultyScoreMonotonic",
            "maximumBaselineLossesPerProfile",
            "maximumReferenceLossesPerProfile",
            "maximumUnhandledDecisions",
            "minimumDefaultVsRandomWinRateBasisPoints",
            "minimumMovementFamilyUsage",
        ],
    );
    Thresholds {
        minimum_default_vs_random_win_rate_basis_points: number(
            &value["minimumDefaultVsRandomWinRateBasisPoints"],
        ),
        maximum_baseline_losses_per_profile: number(&value["maximumBaselineLossesPerProfile"]),
        maximum_reference_losses_per_profile: number(&value["maximumReferenceLossesPerProfile"]),
        maximum_unhandled_decisions: number(&value["maximumUnhandledDecisions"]),
        minimum_movement_family_usage: number(&value["minimumMovementFamilyUsage"]),
        difficulty_score_monotonic: value["difficultyScoreMonotonic"]
            .as_bool()
            .expect("boolean threshold"),
    }
}

fn coordinate(value: &Value) -> HexCoord {
    let values = array(value);
    assert_eq!(values.len(), 2);
    HexCoord::new(
        i32::try_from(number(&values[0])).expect("bounded col"),
        i32::try_from(number(&values[1])).expect("bounded row"),
    )
}

fn difficulties() -> [(&'static str, AiDifficulty); 4] {
    [
        ("easy", AiDifficulty::Easy),
        ("normal", AiDifficulty::Normal),
        ("hard", AiDifficulty::Hard),
        ("veryHard", AiDifficulty::VeryHard),
    ]
}

fn exact_keys(value: &Value, expected: &[&str]) {
    let keys = value
        .as_object()
        .expect("JSON object")
        .keys()
        .map(String::as_str)
        .collect::<BTreeSet<_>>();
    assert_eq!(keys, expected.iter().copied().collect());
}

fn array(value: &Value) -> &[Value] {
    value.as_array().expect("JSON array")
}

fn string(value: &Value) -> &str {
    value.as_str().expect("JSON string")
}

fn number(value: &Value) -> u64 {
    value.as_u64().expect("unsigned JSON number")
}

#[test]
fn strength_corpus_declares_deterministic_policy_and_movement_family() {
    let corpus = parse_corpus();
    assert_eq!(corpus.cases.len(), 6);
    assert_eq!(corpus.random_seeds.len(), 8);
    assert_eq!(corpus.thresholds.minimum_movement_family_usage, 78);
}
