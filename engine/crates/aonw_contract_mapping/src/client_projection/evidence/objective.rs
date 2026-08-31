use aonw_content::MapObjectiveType;
use aonw_contracts::client::{ClientEventDto, MapObjectiveTypeDto};
use aonw_engine::{DominationThresholdReachedEvent, MapObjectiveSecuredEvent};

pub(super) fn map_secured(value: &MapObjectiveSecuredEvent) -> ClientEventDto {
    ClientEventDto::MapObjectiveSecured {
        player_id: value.player_id().as_str().to_owned(),
        objective_id: value.objective_id().to_owned(),
        objective_type: objective_type(value.objective_type()),
        col: value.coordinate().col(),
        row: value.coordinate().row(),
        hold_turns: value.hold_turns(),
        required_hold_turns: value.required_hold_turns(),
        victory_points: value.victory_points(),
        gold_per_turn: value.gold_per_turn(),
    }
}

const fn objective_type(value: MapObjectiveType) -> MapObjectiveTypeDto {
    match value {
        MapObjectiveType::Ruins => MapObjectiveTypeDto::Ruins,
        MapObjectiveType::StrategicPass => MapObjectiveTypeDto::StrategicPass,
        MapObjectiveType::HolySite => MapObjectiveTypeDto::HolySite,
        MapObjectiveType::LegendaryResource => MapObjectiveTypeDto::LegendaryResource,
    }
}

pub(super) fn domination(value: &DominationThresholdReachedEvent) -> ClientEventDto {
    ClientEventDto::DominationThresholdReached {
        player_id: value.player_id().as_str().to_owned(),
        control_percent: serde_json::Number::from_f64(value.control_percent())
            .expect("finite domination percentage"),
        required_control_percent: value
            .required_control_percent_text()
            .parse()
            .expect("validated domination percentage"),
        hold_turns: value.hold_turns(),
        required_hold_turns: value.required_hold_turns(),
    }
}
