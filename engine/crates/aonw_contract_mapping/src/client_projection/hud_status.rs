use aonw_contracts::client::{TreasuryWarningDto, VictoryStatusDto, VictoryStatusKindDto};
use aonw_engine::{TreasuryWarning, VictoryStatusKind};

pub(super) const fn treasury_warning(value: TreasuryWarning) -> TreasuryWarningDto {
    match value {
        TreasuryWarning::None => TreasuryWarningDto::None,
        TreasuryWarning::NegativeBalance => TreasuryWarningDto::NegativeBalance,
        TreasuryWarning::DeficitWithinThreeTurns => TreasuryWarningDto::DeficitWithinThreeTurns,
    }
}

pub(super) fn victory_status(value: &aonw_projection::PlayerVictoryView) -> VictoryStatusDto {
    VictoryStatusDto {
        kind: match value.status_kind() {
            VictoryStatusKind::None => VictoryStatusKindDto::None,
            VictoryStatusKind::Conquest => VictoryStatusKindDto::Conquest,
            VictoryStatusKind::Domination => VictoryStatusKindDto::Domination,
            VictoryStatusKind::Culture => VictoryStatusKindDto::Culture,
            VictoryStatusKind::Score => VictoryStatusKindDto::Score,
        },
        critical: value.status_critical(),
        leader_player_id: value
            .status_leader_player_id()
            .map(|player| player.as_str().to_owned()),
    }
}
