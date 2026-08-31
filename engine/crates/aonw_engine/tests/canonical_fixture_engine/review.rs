use std::collections::{BTreeMap, BTreeSet};

use aonw_contract_mapping::canonicalize_game_state;
use aonw_testkit::{CanonicalFixtureLoader, verify_canonical_fixture};

use super::encoding::command_name;
use super::{CanonicalRustEngineExecutor, repository_root};

#[test]
fn canonical_command_corpus_covers_unit_command_outcomes() {
    let fixtures = CanonicalFixtureLoader::default()
        .load_corpus(repository_root().join("engine/fixtures/canonical_commands"))
        .expect("canonical command corpus");

    let mut outcomes_by_command = BTreeMap::<&str, BTreeSet<bool>>::new();
    for fixture in &fixtures {
        outcomes_by_command
            .entry(command_name(fixture.input().command()))
            .or_default()
            .insert(fixture.expected().accepted());

        assert_eq!(
            canonicalize_game_state(fixture.input().state().clone())
                .expect("canonical input round-trip"),
            *fixture.input().state()
        );
        assert_eq!(
            canonicalize_game_state(fixture.expected().state().clone())
                .expect("canonical output round-trip"),
            *fixture.expected().state()
        );
        verify_canonical_fixture(fixture, &CanonicalRustEngineExecutor)
            .unwrap_or_else(|failure| panic!("{failure:?}"));
    }

    assert_eq!(
        outcomes_by_command.keys().copied().collect::<BTreeSet<_>>(),
        BTreeSet::from([
            "CancelUnitAction",
            "FortifyUnit",
            "MoveUnit",
            "SkipUnitTurn",
        ])
    );
    assert_eq!(
        outcomes_by_command["MoveUnit"],
        BTreeSet::from([false, true])
    );
    assert_eq!(
        outcomes_by_command["FortifyUnit"],
        BTreeSet::from([false, true])
    );
}
