use std::collections::BTreeMap;

use aonw_content::RulesetDefinition;
use aonw_domain::{
    Diplomacy, DiplomaticRelationStatus, EconomyAccountChange, EconomyState, GameState, PlayerId,
    PlayerPair, ResourceTradeAgreement, ResourceType,
};

use crate::DiplomacyError;
use crate::diplomacy::support::effective_relation;

pub(super) fn settle_resource_trades(
    state: &GameState,
    ruleset: &RulesetDefinition,
    diplomacy: Diplomacy,
    scope: &[PlayerId],
) -> Result<(EconomyState, Diplomacy), DiplomacyError> {
    if scope.is_empty() || diplomacy.resource_trade_agreements().is_empty() {
        return Ok((state.economy().clone(), diplomacy));
    }
    let mut groups = BTreeMap::<String, Vec<ResourceTradeAgreement>>::new();
    for agreement in diplomacy.resource_trade_agreements() {
        let key = agreement
            .exchange_group_id()
            .map_or_else(|| format!("single:{}", agreement.id()), str::to_owned);
        groups.entry(key).or_default().push(agreement.clone());
    }
    let mut economy = state.economy().clone();
    let mut retained = Vec::new();
    for group in groups.values_mut() {
        group.sort_unstable_by(|left, right| left.id().cmp(right.id()));
        if !group_is_due(group, scope) {
            retained.extend(group.iter().cloned());
            continue;
        }
        if !has_gold_for_every_leg(&economy, group)? {
            continue;
        }
        if !routes_allow_every_leg(&diplomacy, group) || !has_stock_for_every_leg(&economy, group)?
        {
            age_group(group, &mut retained)?;
            continue;
        }
        economy = transfer_group(state, ruleset, &diplomacy, &economy, group)?;
        age_group(group, &mut retained)?;
    }
    let diplomacy = diplomacy
        .try_with_resource_trades(state.match_lifecycle().identity(), retained)
        .map_err(DiplomacyError::from)?;
    Ok((economy, diplomacy))
}

fn group_is_due(group: &[ResourceTradeAgreement], scope: &[PlayerId]) -> bool {
    group
        .iter()
        .map(ResourceTradeAgreement::importer_player_id)
        .min()
        .is_some_and(|settlement_player| scope.contains(settlement_player))
}

fn has_gold_for_every_leg(
    economy: &EconomyState,
    group: &[ResourceTradeAgreement],
) -> Result<bool, DiplomacyError> {
    let mut required = BTreeMap::<PlayerId, i64>::new();
    for agreement in group {
        let total = required
            .get(agreement.importer_player_id())
            .copied()
            .unwrap_or(0)
            .checked_add(agreement.gold_per_turn())
            .ok_or_else(|| {
                DiplomacyError::InvalidState("trade gold requirement overflow".into())
            })?;
        required.insert(agreement.importer_player_id().clone(), total);
    }
    Ok(required
        .into_iter()
        .all(|(player, amount)| economy.player_gold().get(&player).copied().unwrap_or(0) >= amount))
}

fn routes_allow_every_leg(diplomacy: &Diplomacy, group: &[ResourceTradeAgreement]) -> bool {
    group.iter().all(|agreement| {
        PlayerPair::new(
            agreement.exporter_player_id().clone(),
            agreement.importer_player_id().clone(),
        )
        .is_some_and(|pair| effective_relation(diplomacy, &pair).0 != DiplomaticRelationStatus::War)
    })
}

fn has_stock_for_every_leg(
    economy: &EconomyState,
    group: &[ResourceTradeAgreement],
) -> Result<bool, DiplomacyError> {
    let mut required = BTreeMap::<(PlayerId, ResourceType), i64>::new();
    for agreement in group
        .iter()
        .filter(|value| value.resource().is_stockpiled())
    {
        let key = (agreement.exporter_player_id().clone(), agreement.resource());
        let amount = i64::from(agreement.amount_per_turn());
        let total = required
            .get(&key)
            .copied()
            .unwrap_or(0)
            .checked_add(amount)
            .ok_or_else(|| {
                DiplomacyError::InvalidState("trade resource requirement overflow".into())
            })?;
        required.insert(key, total);
    }
    Ok(required.into_iter().all(|((player, resource), amount)| {
        economy
            .strategic_resources()
            .get(&player)
            .and_then(|stockpile| stockpile.amounts().get(&resource))
            .copied()
            .unwrap_or(0)
            >= amount
    }))
}

fn transfer_group(
    state: &GameState,
    ruleset: &RulesetDefinition,
    diplomacy: &Diplomacy,
    economy: &EconomyState,
    group: &[ResourceTradeAgreement],
) -> Result<EconomyState, DiplomacyError> {
    let mut changes = Vec::new();
    for agreement in group
        .iter()
        .filter(|value| value.resource().is_stockpiled())
    {
        let amount = i64::from(agreement.amount_per_turn());
        changes.push(EconomyAccountChange::StrategicResource {
            player: agreement.exporter_player_id().clone(),
            resource: agreement.resource(),
            delta: -amount,
        });
        changes.push(EconomyAccountChange::StrategicResource {
            player: agreement.importer_player_id().clone(),
            resource: agreement.resource(),
            delta: amount,
        });
    }
    for agreement in group {
        if agreement.gold_per_turn() == 0 {
            continue;
        }
        let pair = PlayerPair::new(
            agreement.exporter_player_id().clone(),
            agreement.importer_player_id().clone(),
        )
        .ok_or_else(|| DiplomacyError::InvalidState("trade self relation".into()))?;
        let bonus = if effective_relation(diplomacy, &pair).0 == DiplomaticRelationStatus::Friendly
        {
            ruleset.diplomacy().friendly_resource_trade_gold_bonus()
        } else {
            0
        };
        let exporter_credit = agreement
            .gold_per_turn()
            .checked_add(bonus)
            .ok_or_else(|| DiplomacyError::InvalidState("trade gold credit overflow".into()))?;
        changes.push(EconomyAccountChange::Gold {
            player: agreement.importer_player_id().clone(),
            delta: -agreement.gold_per_turn(),
        });
        changes.push(EconomyAccountChange::Gold {
            player: agreement.exporter_player_id().clone(),
            delta: exporter_credit,
        });
    }
    Ok(economy.try_after_changes(state.match_lifecycle().identity(), state.bounds(), changes)?)
}

fn age_group(
    group: &[ResourceTradeAgreement],
    retained: &mut Vec<ResourceTradeAgreement>,
) -> Result<(), DiplomacyError> {
    for agreement in group {
        if agreement.remaining_turns() > 1 {
            retained.push(agreement.try_with_remaining_turns(agreement.remaining_turns() - 1)?);
        }
    }
    Ok(())
}
