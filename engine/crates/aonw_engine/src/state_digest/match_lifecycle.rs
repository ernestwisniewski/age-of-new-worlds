use aonw_domain::{
    AiDifficulty, AiPersona, AiPlayer, AiStrategyId, GameLengthKind, GameMode, MatchIdentity,
    MatchLifecycle, MatchRules, PaceProfile, Participant, PlayerCountry, PlayerKind,
    PlayerTurnState, RuleValue, TurnLifecycle,
};

use super::writer::DigestWriter;

pub(super) fn hash_match_lifecycle(writer: &mut DigestWriter, lifecycle: &MatchLifecycle) {
    hash_rules(writer, lifecycle.identity().match_rules());
    hash_identity(writer, lifecycle.identity());
    hash_turn(writer, lifecycle.turn());
}

fn hash_rules(writer: &mut DigestWriter, rules: &MatchRules) {
    let length = rules.game_length();
    writer.u8(match length.kind() {
        GameLengthKind::Unlimited => 0,
        GameLengthKind::TargetMinutes => 1,
    });
    writer.optional_u32(length.target_minutes());
    writer.optional_u32(length.turn_limit());
    writer.u8(match length.pace_profile() {
        PaceProfile::Unlimited => 0,
        PaceProfile::Standard60 => 1,
        PaceProfile::Normal90 => 2,
        PaceProfile::Long120 => 3,
    });
    writer.u8(u8::from(length.score_fallback_enabled()));

    let victory = rules.victory();
    writer.u8(u8::from(victory.conquest_enabled()));
    writer.u8(u8::from(victory.domination_enabled()));
    writer.text(victory.domination_control_percent().as_str());
    writer.u32(victory.domination_hold_turns());
    writer.u8(u8::from(victory.score_fallback_enabled()));
    writer.optional_u32(victory.turn_limit());
    writer.optional_u32(victory.hard_time_limit_minutes());
    writer.u8(u8::from(victory.cultural_enabled()));
    writer.u32(victory.cultural_required_artifacts());
    writer.u32(victory.cultural_hold_turns());
    writer.usize(rules.balance().len());
    for (key, value) in rules.balance() {
        writer.text(key);
        hash_rule_value(writer, value);
    }
}

fn hash_identity(writer: &mut DigestWriter, identity: &MatchIdentity) {
    writer.u8(match identity.game_mode() {
        GameMode::HotSeat => 0,
        GameMode::Multiplayer => 1,
    });
    writer.usize(identity.participants().len());
    for participant in identity.participants() {
        writer.text(participant.id().as_str());
        writer.text(participant.name());
        writer.u32(participant.color_value());
        writer.u8(country_tag(participant.country()));
        writer.u8(match participant.kind() {
            PlayerKind::Human => 0,
            PlayerKind::Ai => 1,
        });
        hash_ai(writer, participant);
    }
}

fn hash_ai(writer: &mut DigestWriter, participant: &Participant) {
    let Some(ai) = participant.ai() else {
        writer.u8(0);
        return;
    };
    writer.u8(1);
    writer.u8(match ai.strategy_id() {
        AiStrategyId::Random => 0,
        AiStrategyId::Basic => 1,
        AiStrategyId::Scripted => 2,
        AiStrategyId::Utility => 3,
        AiStrategyId::Mcts => 4,
    });
    writer.u8(difficulty_tag(ai));
    writer.u8(match ai.persona() {
        AiPersona::Balanced => 0,
        AiPersona::Aggressive => 1,
        AiPersona::Expansive => 2,
        AiPersona::Economic => 3,
        AiPersona::Scientific => 4,
    });
    writer.i64(ai.seed());
}

const fn difficulty_tag(ai: AiPlayer) -> u8 {
    match ai.difficulty() {
        AiDifficulty::Easy => 0,
        AiDifficulty::Normal => 1,
        AiDifficulty::Hard => 2,
        AiDifficulty::VeryHard => 3,
    }
}

fn hash_turn(writer: &mut DigestWriter, turn: &TurnLifecycle) {
    writer.usize(turn.turn_states_by_player_id().len());
    for (player, state) in turn.turn_states_by_player_id() {
        writer.text(player.as_str());
        writer.u8(match state {
            PlayerTurnState::Active => 0,
            PlayerTurnState::Finished => 1,
        });
    }
    writer.usize(turn.required_submission_player_ids().len());
    for player in turn.required_submission_player_ids() {
        writer.text(player.as_str());
    }
    writer.usize(turn.submitted_player_ids().len());
    for player in turn.submitted_player_ids() {
        writer.text(player.as_str());
    }
    writer.usize(turn.timeout_streaks_by_player_id().len());
    for (player, streak) in turn.timeout_streaks_by_player_id() {
        writer.text(player.as_str());
        writer.i64(*streak);
    }
    writer.usize(turn.afk_player_ids().len());
    for player in turn.afk_player_ids() {
        writer.text(player.as_str());
    }
    writer.usize(turn.kicked_player_ids().len());
    for player in turn.kicked_player_ids() {
        writer.text(player.as_str());
    }
    writer.optional_text(
        turn.turn_started_at()
            .map(aonw_domain::UtcTimestamp::as_str),
    );
}

fn hash_rule_value(writer: &mut DigestWriter, value: &RuleValue) {
    match value {
        RuleValue::Null => writer.u8(0),
        RuleValue::Bool(value) => {
            writer.u8(1);
            writer.u8(u8::from(*value));
        }
        RuleValue::Number(value) => {
            writer.u8(2);
            writer.text(value.as_str());
        }
        RuleValue::String(value) => {
            writer.u8(3);
            writer.text(value);
        }
        RuleValue::Array(values) => {
            writer.u8(4);
            writer.usize(values.len());
            for value in values {
                hash_rule_value(writer, value);
            }
        }
        RuleValue::Object(values) => {
            writer.u8(5);
            writer.usize(values.len());
            for (key, value) in values {
                writer.text(key);
                hash_rule_value(writer, value);
            }
        }
    }
}

const fn country_tag(value: PlayerCountry) -> u8 {
    match value {
        PlayerCountry::Poland => 0,
        PlayerCountry::Ukraine => 1,
        PlayerCountry::Germany => 2,
        PlayerCountry::France => 3,
        PlayerCountry::UnitedKingdom => 4,
        PlayerCountry::Italy => 5,
        PlayerCountry::Spain => 6,
        PlayerCountry::Netherlands => 7,
        PlayerCountry::Sweden => 8,
        PlayerCountry::Russia => 9,
        PlayerCountry::UnitedStates => 10,
        PlayerCountry::Canada => 11,
        PlayerCountry::China => 12,
        PlayerCountry::Korea => 13,
        PlayerCountry::Japan => 14,
        PlayerCountry::Portugal => 15,
        PlayerCountry::India => 16,
        PlayerCountry::Brazil => 17,
        PlayerCountry::Indonesia => 18,
        PlayerCountry::Mexico => 19,
        PlayerCountry::Turkey => 20,
        PlayerCountry::SaudiArabia => 21,
        PlayerCountry::Egypt => 22,
        PlayerCountry::Greece => 23,
    }
}
