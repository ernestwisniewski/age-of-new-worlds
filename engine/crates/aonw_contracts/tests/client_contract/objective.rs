use aonw_contracts::MapObjectiveTypeDto;
use aonw_contracts::client::ClientEventDto;

#[test]
fn objective_events_round_trip_with_strict_shapes() {
    let events = [
        ClientEventDto::MapObjectiveSecured {
            player_id: "player-2".to_owned(),
            objective_id: "central-ruins".to_owned(),
            objective_type: MapObjectiveTypeDto::Ruins,
            col: 2,
            row: 3,
            hold_turns: 2,
            required_hold_turns: 2,
            victory_points: 5,
            gold_per_turn: 3,
        },
        ClientEventDto::DominationThresholdReached {
            player_id: "player-2".to_owned(),
            control_percent: serde_json::Number::from_f64(66.666_666_666_666_67).expect("finite"),
            required_control_percent: serde_json::Number::from(60),
            hold_turns: 1,
            required_hold_turns: 5,
        },
    ];
    for event in events {
        let json = serde_json::to_string(&event).expect("event JSON");
        assert_eq!(
            serde_json::from_str::<ClientEventDto>(&json).expect("event"),
            event
        );
        let unknown = json.replacen('{', r#"{"unexpectedField":true,"#, 1);
        assert!(serde_json::from_str::<ClientEventDto>(&unknown).is_err());
    }
}
