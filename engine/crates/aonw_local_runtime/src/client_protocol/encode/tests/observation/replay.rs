use super::{HexCoord, MoveUnitRequest, command_result, opened, player, unit_id};

#[test]
fn replay_preserves_rejected_commands_without_advancing_revision() {
    let (map, rules, mut runtime) = opened();
    let unchanged = runtime
        .dispatch(&MoveUnitRequest {
            expected_revision: 0,
            unit_id: unit_id("human-unit"),
            target: HexCoord::new(0, 0),
        })
        .expect("unchanged movement");
    assert!(!unchanged.is_accepted());
    assert_eq!(unchanged.stamp.revision.get(), 0);
    let rejected = runtime
        .dispatch(&MoveUnitRequest {
            expected_revision: 0,
            unit_id: unit_id("hidden-ai"),
            target: HexCoord::new(9, 0),
        })
        .expect("foreign movement rejection");
    assert!(!rejected.is_accepted());
    let archive = runtime.export_replay_json().expect("archive");
    runtime
        .open_replay_json(map, rules, &archive, player("human"))
        .expect("playback");
    for (index, expected) in [unchanged, rejected].iter().enumerate() {
        let frame = runtime
            .seek_replay(u64::try_from(index + 1).expect("position"))
            .expect("forward frame");
        let observed = frame.command.expect("command boundary");
        assert_eq!(command_result(&observed), command_result(expected));
        assert_eq!(
            observed.view_patch.from_revision,
            observed.view_patch.to_revision
        );
        assert_eq!(frame.snapshot.stamp(), &observed.stamp);
    }
}
