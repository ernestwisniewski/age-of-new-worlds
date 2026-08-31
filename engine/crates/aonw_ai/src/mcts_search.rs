use core::{cmp::Ordering, num::NonZeroUsize};

use aonw_domain::{HexCoord, PlayerId};
use aonw_local_runtime::{LocalRuntime, MoveUnitRequest, PlayerViewSnapshot, RuntimeError};

use crate::{
    AiRng, PlanningBudget,
    actions::{bounded_tactical_move_candidates, compare_move_requests},
    rng::draw_index,
};

/// Deterministic work evidence produced by one MCTS search.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct MctsSearchStats {
    iterations: u32,
    expanded_nodes: u32,
    executed_commands: u32,
    rollout_commands: u32,
    rejected_commands: u32,
    max_depth_reached: u32,
    quality_guarded_selections: u32,
}

impl MctsSearchStats {
    /// Returns the exact completed iteration count.
    #[must_use]
    pub const fn iterations(self) -> u32 {
        self.iterations
    }
    /// Returns retained action nodes, excluding the root.
    #[must_use]
    pub const fn expanded_nodes(self) -> u32 {
        self.expanded_nodes
    }
    /// Returns all public runtime command executions in simulations.
    #[must_use]
    pub const fn executed_commands(self) -> u32 {
        self.executed_commands
    }
    /// Returns executions made after tree selection and expansion.
    #[must_use]
    pub const fn rollout_commands(self) -> u32 {
        self.rollout_commands
    }
    /// Returns normal typed command rejections observed in simulations.
    #[must_use]
    pub const fn rejected_commands(self) -> u32 {
        self.rejected_commands
    }
    /// Returns the deepest executed command sequence.
    #[must_use]
    pub const fn max_depth_reached(self) -> u32 {
        self.max_depth_reached
    }

    /// Returns root selections replaced by the deterministic immediate-quality guard.
    #[must_use]
    pub const fn quality_guarded_selections(self) -> u32 {
        self.quality_guarded_selections
    }

    pub(crate) fn fingerprint_counters(self) -> [u64; 7] {
        [
            u64::from(self.iterations),
            u64::from(self.expanded_nodes),
            u64::from(self.executed_commands),
            u64::from(self.rollout_commands),
            u64::from(self.rejected_commands),
            u64::from(self.max_depth_reached),
            u64::from(self.quality_guarded_selections),
        ]
    }

    pub(crate) fn record_quality_guard(&mut self) {
        self.quality_guarded_selections += 1;
    }
}

pub(crate) struct SearchResult {
    pub(crate) command: MoveUnitRequest,
    pub(crate) stats: MctsSearchStats,
}

pub(crate) fn search(
    runtime: &LocalRuntime,
    recipient: &PlayerId,
    initial_movement: u64,
    budget: PlanningBudget,
    root_actions: Vec<MoveUnitRequest>,
    rng: &mut AiRng,
    draws: &mut Vec<u32>,
) -> Result<SearchResult, RuntimeError> {
    let mut nodes = vec![SearchNode::root(root_actions)];
    let mut stats = MctsSearchStats::default();
    let simulation_template = runtime.simulation_clone();
    for _ in 0..budget.iterations() {
        let mut simulation = simulation_template.clone();
        let iteration = run_iteration(
            &mut simulation,
            recipient,
            initial_movement,
            budget,
            &mut nodes,
            rng,
            draws,
            &mut stats,
        )?;
        backpropagate(&mut nodes, iteration.node, iteration.score);
        stats.iterations += 1;
    }
    stats.expanded_nodes = u32::try_from(nodes.len() - 1).unwrap_or(u32::MAX);
    let selected = best_final_child(&nodes, 0);
    Ok(SearchResult {
        command: nodes[selected]
            .command
            .as_ref()
            .expect("root child has command")
            .clone(),
        stats,
    })
}

#[derive(Clone, Debug)]
struct SearchNode {
    parent: Option<usize>,
    command: Option<MoveUnitRequest>,
    children: Vec<usize>,
    untried: Option<Vec<MoveUnitRequest>>,
    visits: u32,
    total_score: i64,
}

impl SearchNode {
    fn root(actions: Vec<MoveUnitRequest>) -> Self {
        Self {
            parent: None,
            command: None,
            children: Vec::new(),
            untried: Some(actions),
            visits: 0,
            total_score: 0,
        }
    }

    fn child(parent: usize, command: MoveUnitRequest) -> Self {
        Self {
            parent: Some(parent),
            command: Some(command),
            children: Vec::new(),
            untried: None,
            visits: 0,
            total_score: 0,
        }
    }
}

#[derive(Clone, Copy, Debug)]
struct IterationResult {
    node: usize,
    score: i64,
}

#[allow(clippy::too_many_arguments)]
fn run_iteration(
    simulation: &mut LocalRuntime,
    recipient: &PlayerId,
    initial_movement: u64,
    budget: PlanningBudget,
    nodes: &mut Vec<SearchNode>,
    rng: &mut AiRng,
    draws: &mut Vec<u32>,
    stats: &mut MctsSearchStats,
) -> Result<IterationResult, RuntimeError> {
    let mut node = 0;
    let mut depth = 0;
    let mut rejected = false;

    while depth < budget.max_depth() {
        cache_actions(simulation, node, nodes, budget)?;
        let can_expand = nodes.len() < usize::try_from(budget.max_nodes()).unwrap_or(usize::MAX);
        if can_expand
            && nodes[node]
                .untried
                .as_ref()
                .is_some_and(|items| !items.is_empty())
        {
            let command = take_random_action(&mut nodes[node], rng, draws);
            if !execute_move(simulation, &command, stats)? {
                rejected = true;
                break;
            }
            let child = nodes.len();
            nodes.push(SearchNode::child(node, command));
            nodes[node].children.push(child);
            node = child;
            depth += 1;
            break;
        }
        if nodes[node].children.is_empty() {
            break;
        }
        let child = best_tree_child(nodes, node);
        let command = nodes[child]
            .command
            .as_ref()
            .expect("child has command")
            .clone();
        if !execute_move(simulation, &command, stats)? {
            rejected = true;
            break;
        }
        node = child;
        depth += 1;
    }

    while !rejected && depth < budget.max_depth() {
        let snapshot = simulation.snapshot()?;
        let candidates = bounded_tactical_move_candidates(
            simulation,
            &snapshot,
            usize::try_from(budget.max_nodes() - 1).unwrap_or(usize::MAX),
        )?;
        let Some(maximum) = NonZeroUsize::new(candidates.len()) else {
            break;
        };
        let selected = draw_index(rng, maximum, draws);
        if !execute_move(simulation, candidates[selected].request(), stats)? {
            rejected = true;
            break;
        }
        stats.rollout_commands += 1;
        depth += 1;
    }
    stats.max_depth_reached = stats.max_depth_reached.max(depth);
    let score = iteration_score(rejected, simulation, recipient, initial_movement)?;
    Ok(IterationResult { node, score })
}

fn iteration_score(
    rejected: bool,
    simulation: &LocalRuntime,
    recipient: &PlayerId,
    initial_movement: u64,
) -> Result<i64, RuntimeError> {
    if rejected {
        Ok(-1_000_000)
    } else {
        evaluate(simulation, recipient, initial_movement)
    }
}

fn cache_actions(
    simulation: &mut LocalRuntime,
    node: usize,
    nodes: &mut [SearchNode],
    budget: PlanningBudget,
) -> Result<(), RuntimeError> {
    if nodes[node].untried.is_some() {
        return Ok(());
    }
    let snapshot = simulation.snapshot()?;
    nodes[node].untried = Some(
        bounded_tactical_move_candidates(
            simulation,
            &snapshot,
            usize::try_from(budget.max_nodes() - 1).unwrap_or(usize::MAX),
        )?
        .into_iter()
        .map(crate::actions::MoveCandidate::into_request)
        .collect(),
    );
    Ok(())
}

fn take_random_action(
    node: &mut SearchNode,
    rng: &mut AiRng,
    draws: &mut Vec<u32>,
) -> MoveUnitRequest {
    let actions = node.untried.as_mut().expect("actions cached");
    let maximum = NonZeroUsize::new(actions.len()).expect("non-empty actions");
    actions.remove(draw_index(rng, maximum, draws))
}

fn execute_move(
    simulation: &mut LocalRuntime,
    request: &aonw_local_runtime::MoveUnitRequest,
    stats: &mut MctsSearchStats,
) -> Result<bool, RuntimeError> {
    let result = simulation.dispatch(request)?;
    stats.executed_commands += 1;
    if result.is_accepted() {
        Ok(true)
    } else {
        stats.rejected_commands += 1;
        Ok(false)
    }
}

fn evaluate(
    simulation: &LocalRuntime,
    recipient: &PlayerId,
    initial_movement: u64,
) -> Result<i64, RuntimeError> {
    let snapshot = simulation.snapshot()?;
    let spent = initial_movement.saturating_sub(owned_movement(&snapshot, recipient));
    let opponents = snapshot
        .units()
        .iter()
        .filter(|unit| unit.owner_player_id() != recipient)
        .map(|unit| HexCoord::new(unit.col(), unit.row()))
        .collect::<Vec<_>>();
    let proximity = snapshot
        .units()
        .iter()
        .filter(|unit| {
            unit.owner_player_id() == recipient && crate::strategy::is_military(unit.kind())
        })
        .flat_map(|unit| {
            let position = HexCoord::new(unit.col(), unit.row());
            opponents
                .iter()
                .map(move |opponent| position.distance_to(*opponent))
        })
        .min()
        .map_or(0, |distance| {
            10_000_i64.saturating_sub(to_i64(distance) * 100)
        });
    Ok(to_i64(spent) * 1_000 + proximity)
}

pub(crate) fn owned_movement(snapshot: &PlayerViewSnapshot, recipient: &PlayerId) -> u64 {
    snapshot
        .units()
        .iter()
        .filter(|unit| {
            unit.owner_player_id() == recipient && crate::strategy::is_military(unit.kind())
        })
        .map(|unit| u64::from(unit.movement_units()))
        .sum()
}

fn best_tree_child(nodes: &[SearchNode], parent: usize) -> usize {
    let parent_visits = i64::from(nodes[parent].visits.max(1));
    *nodes[parent]
        .children
        .iter()
        .max_by(|left, right| compare_tree_score(&nodes[**left], &nodes[**right], parent_visits))
        .expect("tree child")
}

fn compare_tree_score(left: &SearchNode, right: &SearchNode, parent_visits: i64) -> Ordering {
    tree_policy_score(left, parent_visits)
        .cmp(&tree_policy_score(right, parent_visits))
        .then_with(|| right.visits.cmp(&left.visits))
        .then_with(|| compare_node_commands(right, left))
}

fn tree_policy_score(node: &SearchNode, parent_visits: i64) -> i64 {
    let visits = i64::from(node.visits.max(1));
    node.total_score.saturating_mul(1_024) / visits + parent_visits.saturating_mul(64) / visits
}

fn best_final_child(nodes: &[SearchNode], parent: usize) -> usize {
    *nodes[parent]
        .children
        .iter()
        .max_by(|left, right| compare_final(&nodes[**left], &nodes[**right]))
        .expect("at least one root child")
}

fn compare_final(left: &SearchNode, right: &SearchNode) -> Ordering {
    left.visits
        .cmp(&right.visits)
        .then_with(|| compare_average(left, right))
        .then_with(|| compare_node_commands(right, left))
}

fn compare_average(left: &SearchNode, right: &SearchNode) -> Ordering {
    let left_visits = i128::from(left.visits.max(1));
    let right_visits = i128::from(right.visits.max(1));
    (i128::from(left.total_score) * right_visits)
        .cmp(&(i128::from(right.total_score) * left_visits))
}

fn compare_node_commands(left: &SearchNode, right: &SearchNode) -> Ordering {
    compare_move_requests(
        left.command.as_ref().expect("child command"),
        right.command.as_ref().expect("child command"),
    )
}

fn backpropagate(nodes: &mut [SearchNode], mut node: usize, score: i64) {
    loop {
        nodes[node].visits += 1;
        nodes[node].total_score = nodes[node].total_score.saturating_add(score);
        let Some(parent) = nodes[node].parent else {
            break;
        };
        node = parent;
    }
}

fn to_i64(value: u64) -> i64 {
    i64::try_from(value).unwrap_or(i64::MAX)
}

#[cfg(test)]
pub(crate) mod tests;
