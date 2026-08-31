use crate::{MatchIdentity, PlayerId};

use super::{
    Diplomacy, DiplomacyStateBuildError, DiplomaticRelation, DiplomaticRelationChangeReason,
    DiplomaticRelationStatus, DiplomaticScoreChangeReason, DiplomaticScoreEntry, PlayerPair,
};

impl Diplomacy {
    /// Applies the canonical diplomatic consequences of a unit attack.
    ///
    /// # Errors
    ///
    /// Returns an error when participants or the resulting aggregate violate
    /// diplomacy invariants.
    pub fn after_unit_attack(
        &self,
        identity: &MatchIdentity,
        attacker: &PlayerId,
        defender: &PlayerId,
        turn: u32,
        attacker_unit_id: &str,
    ) -> Result<Self, DiplomacyStateBuildError> {
        self.after_attack(
            identity,
            attacker,
            defender,
            turn,
            attacker_unit_id,
            AttackDiplomacyKind::Unit,
        )
    }

    /// Applies the canonical diplomatic consequences of a city attack.
    ///
    /// City attacks escalate to war, penalize observers who know both sides,
    /// and terminate bilateral resource trades.
    ///
    /// # Errors
    ///
    /// Returns an error when participants or the resulting aggregate violate
    /// diplomacy invariants.
    pub fn after_city_attack(
        &self,
        identity: &MatchIdentity,
        attacker: &PlayerId,
        defender: &PlayerId,
        turn: u32,
        attacker_unit_id: &str,
    ) -> Result<Self, DiplomacyStateBuildError> {
        self.after_attack(
            identity,
            attacker,
            defender,
            turn,
            attacker_unit_id,
            AttackDiplomacyKind::City,
        )
    }

    fn after_attack(
        &self,
        identity: &MatchIdentity,
        attacker: &PlayerId,
        defender: &PlayerId,
        turn: u32,
        attacker_unit_id: &str,
        kind: AttackDiplomacyKind,
    ) -> Result<Self, DiplomacyStateBuildError> {
        let pair = PlayerPair::new(attacker.clone(), defender.clone())
            .ok_or_else(|| DiplomacyStateBuildError::SelfRelation(attacker.clone()))?;
        let mut contacts = self.contacts.to_vec();
        contacts.push(pair.clone());
        contacts.sort_unstable();
        contacts.dedup();

        let mut relations = self.relations.to_vec();
        let relation_index = relations
            .binary_search_by(|relation| relation.pair().cmp(&pair))
            .ok();
        let existing = relation_index.map(|index| &relations[index]);
        let current_score = existing.map_or(0, DiplomaticRelation::relation_score);
        let desired_status = kind.status();
        let replace_status = existing.is_none_or(|relation| {
            attack_status_severity(desired_status) >= attack_status_severity(relation.status())
                && (relation.status() != desired_status
                    || relation.status_expires_on_turn().is_some())
        });
        let (status, expiry, changed_turn, change_reason) = if replace_status {
            (
                desired_status,
                None,
                Some(turn),
                Some(kind.relation_reason()),
            )
        } else {
            let relation = existing.expect("an absent relation always replaces attack status");
            (
                relation.status(),
                relation.status_expires_on_turn(),
                relation.last_changed_turn(),
                relation.last_change_reason(),
            )
        };
        let score_after = current_score
            .saturating_add(kind.score_delta())
            .clamp(-100, 100);
        let next_relation = DiplomaticRelation::try_new(
            pair.clone(),
            status,
            score_after,
            expiry,
            changed_turn,
            change_reason,
        )?;
        if let Some(index) = relation_index {
            relations[index] = next_relation;
        } else {
            relations.push(next_relation);
        }

        let mut score_history = self.score_history.to_vec();
        let primary_source = unique_attack_source(
            &score_history,
            &pair,
            turn,
            kind.source_prefix(),
            attacker_unit_id,
        );
        score_history.push(DiplomaticScoreEntry::try_new(
            pair.clone(),
            turn,
            score_after - current_score,
            score_after,
            kind.score_reason(),
            primary_source,
        )?);

        if kind == AttackDiplomacyKind::City {
            apply_city_warmonger_penalties(
                &contacts,
                &mut relations,
                &mut score_history,
                attacker,
                defender,
                turn,
                attacker_unit_id,
            )?;
        }
        let trades = self.resource_trade_agreements.iter().filter(|agreement| {
            kind != AttackDiplomacyKind::City
                || PlayerPair::new(
                    agreement.exporter_player_id().clone(),
                    agreement.importer_player_id().clone(),
                )
                .is_none_or(|trade_pair| trade_pair != pair)
        });
        Self::try_new(
            identity,
            contacts,
            relations,
            self.pending_proposals.iter().cloned(),
            self.messages.iter().cloned(),
            score_history,
            trades.cloned(),
        )
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
enum AttackDiplomacyKind {
    Unit,
    City,
}

impl AttackDiplomacyKind {
    const fn status(self) -> DiplomaticRelationStatus {
        match self {
            Self::Unit => DiplomaticRelationStatus::Hostile,
            Self::City => DiplomaticRelationStatus::War,
        }
    }

    const fn score_delta(self) -> i64 {
        match self {
            Self::Unit => -10,
            Self::City => -30,
        }
    }

    const fn relation_reason(self) -> DiplomaticRelationChangeReason {
        match self {
            Self::Unit => DiplomaticRelationChangeReason::UnitAttack,
            Self::City => DiplomaticRelationChangeReason::CityAttack,
        }
    }

    const fn score_reason(self) -> DiplomaticScoreChangeReason {
        match self {
            Self::Unit => DiplomaticScoreChangeReason::UnitAttack,
            Self::City => DiplomaticScoreChangeReason::CityAttack,
        }
    }

    const fn source_prefix(self) -> &'static str {
        match self {
            Self::Unit => "unit_attack",
            Self::City => "city_attack",
        }
    }
}

pub(super) const fn attack_status_severity(status: DiplomaticRelationStatus) -> u8 {
    match status {
        DiplomaticRelationStatus::Hostile => 1,
        DiplomaticRelationStatus::War => 2,
        DiplomaticRelationStatus::Friendly
        | DiplomaticRelationStatus::Neutral
        | DiplomaticRelationStatus::Truce => 0,
    }
}

fn unique_attack_source(
    history: &[DiplomaticScoreEntry],
    pair: &PlayerPair,
    turn: u32,
    prefix: &str,
    attacker_unit_id: &str,
) -> Option<String> {
    let null_source_exists = history
        .iter()
        .any(|entry| entry.pair() == pair && entry.turn() == turn && entry.source_id().is_none());
    null_source_exists.then(|| format!("{prefix}.{turn}.{attacker_unit_id}"))
}

#[allow(clippy::too_many_arguments)]
fn apply_city_warmonger_penalties(
    contacts: &[PlayerPair],
    relations: &mut Vec<DiplomaticRelation>,
    history: &mut Vec<DiplomaticScoreEntry>,
    attacker: &PlayerId,
    defender: &PlayerId,
    turn: u32,
    attacker_unit_id: &str,
) -> Result<(), DiplomacyStateBuildError> {
    let mut observers = contacts
        .iter()
        .filter_map(|pair| {
            if pair.first() == attacker {
                Some(pair.second())
            } else if pair.second() == attacker {
                Some(pair.first())
            } else {
                None
            }
        })
        .filter(|observer| *observer != defender)
        .filter(|observer| {
            PlayerPair::new((*observer).clone(), defender.clone())
                .is_some_and(|pair| contacts.binary_search(&pair).is_ok())
        })
        .cloned()
        .collect::<Vec<_>>();
    observers.sort_unstable();
    observers.dedup();
    for observer in observers {
        let pair = PlayerPair::new(observer, attacker.clone())
            .ok_or_else(|| DiplomacyStateBuildError::SelfRelation(attacker.clone()))?;
        let index = relations
            .iter()
            .position(|relation| relation.pair() == &pair);
        let existing = index.map(|value| &relations[value]);
        let old_score = existing.map_or(0, DiplomaticRelation::relation_score);
        let next_score = old_score.saturating_sub(12).clamp(-100, 100);
        let next_relation = DiplomaticRelation::try_new(
            pair.clone(),
            existing.map_or(
                DiplomaticRelationStatus::Neutral,
                DiplomaticRelation::status,
            ),
            next_score,
            existing.and_then(DiplomaticRelation::status_expires_on_turn),
            existing.and_then(DiplomaticRelation::last_changed_turn),
            existing.and_then(DiplomaticRelation::last_change_reason),
        )?;
        if let Some(index) = index {
            relations[index] = next_relation;
        } else {
            relations.push(next_relation);
        }
        history.push(DiplomaticScoreEntry::try_new(
            pair,
            turn,
            next_score - old_score,
            next_score,
            DiplomaticScoreChangeReason::WarmongerPenalty,
            Some(format!("city_attack.{turn}.{attacker_unit_id}")),
        )?);
    }
    Ok(())
}
