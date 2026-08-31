use std::collections::BTreeSet;

use aonw_domain::{
    Diplomacy, DiplomaticRelationStatus, GameState, PlayerId, ResourceTradeAgreement, ResourceType,
};

use super::{
    DiplomacyError, DiplomacyMutation, OpenResourceExchangeCommand, OpenResourceTradeCommand,
    support::{mutation, validate_actor, validate_revision},
};
use crate::{
    CommandRejectionCode, DiplomacyDisclosure, DiplomacyPolicy, DiplomacyPolicyQuery,
    EngineContext, TechnologyUnlockQuery,
};

pub(crate) fn apply_open_resource_trade(
    state: &GameState,
    context: EngineContext<'_>,
    command: OpenResourceTradeCommand<'_>,
) -> Result<DiplomacyMutation, DiplomacyError> {
    validate_revision(state, command.expected_revision())?;
    let actor = context.actor_player_id();
    validate_actor(state, context, actor)?;
    let target = command.target_player_id();
    let policy = validate_target(state, actor, target)?;
    if !command.resource().is_strategic() {
        return Err(CommandRejectionCode::InvalidResourceTradeResource.into());
    }
    let duration = u32::try_from(command.duration_turns())
        .ok()
        .filter(|value| *value > 0);
    if command.gold_per_turn() < 0 || duration.is_none() {
        return Err(CommandRejectionCode::InvalidResourceTradeTerms.into());
    }
    if policy.status() == DiplomaticRelationStatus::War {
        return Err(CommandRejectionCode::ResourceTradeBlockedByWar.into());
    }
    let available_gold = state
        .economy()
        .player_gold()
        .get(actor)
        .copied()
        .unwrap_or(0);
    if available_gold < command.gold_per_turn() {
        return Err(CommandRejectionCode::ResourceTradeGoldUnavailable.into());
    }
    let agreements = state.diplomacy().resource_trade_agreements();
    if has_active_duplicate(agreements, actor, target, command.resource()) {
        return Err(CommandRejectionCode::ResourceTradeAlreadyActive.into());
    }
    validate_requested_id(agreements, command.agreement_id(), false)?;
    if export_availability(state, context, target, command.resource())? <= 0 {
        return Err(CommandRejectionCode::ResourceTradeExportUnavailable.into());
    }

    let id = match command.agreement_id() {
        Some(value) => value.to_owned(),
        None => generated_trade_id(state.diplomacy(), actor, target, command.resource())?,
    };
    let agreement = ResourceTradeAgreement::try_new(
        id,
        target.clone(),
        actor.clone(),
        command.resource(),
        command.gold_per_turn(),
        duration.expect("positive duration validated"),
        1,
        None,
    )?;
    let diplomacy = state.diplomacy().try_with_resource_trades(
        state.match_lifecycle().identity(),
        agreements
            .iter()
            .cloned()
            .chain(core::iter::once(agreement)),
    )?;
    mutation(
        state,
        diplomacy,
        state.economy().clone(),
        state.combat().clone(),
        [],
    )
}

pub(crate) fn apply_open_resource_exchange(
    state: &GameState,
    context: EngineContext<'_>,
    command: OpenResourceExchangeCommand<'_>,
) -> Result<DiplomacyMutation, DiplomacyError> {
    validate_revision(state, command.expected_revision())?;
    let actor = context.actor_player_id();
    validate_actor(state, context, actor)?;
    let target = command.target_player_id();
    let policy = validate_target(state, actor, target)?;
    if !command.offered_resource().is_strategic() || !command.requested_resource().is_strategic() {
        return Err(CommandRejectionCode::InvalidResourceTradeResource.into());
    }
    let duration = u32::try_from(command.duration_turns())
        .ok()
        .filter(|value| *value > 0);
    if command.offered_resource() == command.requested_resource() || duration.is_none() {
        return Err(CommandRejectionCode::InvalidResourceTradeTerms.into());
    }
    if policy.status() == DiplomaticRelationStatus::War {
        return Err(CommandRejectionCode::ResourceTradeBlockedByWar.into());
    }
    let agreements = state.diplomacy().resource_trade_agreements();
    if has_active_duplicate(agreements, actor, target, command.requested_resource())
        || has_active_duplicate(agreements, target, actor, command.offered_resource())
    {
        return Err(CommandRejectionCode::ResourceTradeAlreadyActive.into());
    }
    validate_requested_id(agreements, command.agreement_id(), true)?;
    if export_availability(state, context, actor, command.offered_resource())? <= 0 {
        return Err(CommandRejectionCode::ResourceTradeOfferUnavailable.into());
    }
    if export_availability(state, context, target, command.requested_resource())? <= 0 {
        return Err(CommandRejectionCode::ResourceTradeRequestUnavailable.into());
    }

    let base_id = match command.agreement_id() {
        Some(value) => value.to_owned(),
        None => generated_exchange_id(
            state.diplomacy(),
            actor,
            target,
            command.offered_resource(),
            command.requested_resource(),
        )?,
    };
    let duration = duration.expect("positive duration validated");
    let requested = ResourceTradeAgreement::try_new(
        format!("{base_id}_requested"),
        target.clone(),
        actor.clone(),
        command.requested_resource(),
        0,
        duration,
        1,
        Some(base_id.clone()),
    )?;
    let offered = ResourceTradeAgreement::try_new(
        format!("{base_id}_offered"),
        actor.clone(),
        target.clone(),
        command.offered_resource(),
        0,
        duration,
        1,
        Some(base_id),
    )?;
    let diplomacy = state.diplomacy().try_with_resource_trades(
        state.match_lifecycle().identity(),
        agreements.iter().cloned().chain([requested, offered]),
    )?;
    mutation(
        state,
        diplomacy,
        state.economy().clone(),
        state.combat().clone(),
        [],
    )
}

fn validate_target(
    state: &GameState,
    actor: &PlayerId,
    target: &PlayerId,
) -> Result<DiplomacyPolicy, DiplomacyError> {
    if actor == target {
        return Err(CommandRejectionCode::InvalidResourceTradeTarget.into());
    }
    let policy = DiplomacyPolicyQuery::between(state, actor, target)
        .map_err(|_| CommandRejectionCode::DiplomacyTargetNotDiscovered)?;
    if !matches!(policy.disclosure(), DiplomacyDisclosure::Known(_)) {
        return Err(CommandRejectionCode::DiplomacyTargetNotDiscovered.into());
    }
    Ok(policy)
}

fn has_active_duplicate(
    agreements: &[ResourceTradeAgreement],
    importer: &PlayerId,
    exporter: &PlayerId,
    resource: ResourceType,
) -> bool {
    agreements.iter().any(|agreement| {
        agreement.importer_player_id() == importer
            && agreement.exporter_player_id() == exporter
            && agreement.resource() == resource
    })
}

fn validate_requested_id(
    agreements: &[ResourceTradeAgreement],
    requested: Option<&str>,
    exchange: bool,
) -> Result<(), DiplomacyError> {
    let Some(base) = requested else {
        return Ok(());
    };
    if !valid_agreement_id(base) {
        return Err(CommandRejectionCode::InvalidResourceTradeAgreementId.into());
    }
    let requested_leg = format!("{base}_requested");
    let offered_leg = format!("{base}_offered");
    let available = if exchange {
        agreement_tokens_available(
            agreements,
            &[base, requested_leg.as_str(), offered_leg.as_str()],
        )
    } else {
        agreement_tokens_available(agreements, &[base])
    };
    if !available {
        return Err(CommandRejectionCode::ResourceTradeAgreementIdConflict.into());
    }
    Ok(())
}

fn valid_agreement_id(value: &str) -> bool {
    !value.is_empty()
        && value.len() <= 128
        && value
            .bytes()
            .all(|byte| byte.is_ascii_alphanumeric() || matches!(byte, b'.' | b'_' | b'-'))
}

fn agreement_tokens_available(agreements: &[ResourceTradeAgreement], tokens: &[&str]) -> bool {
    agreements.iter().all(|agreement| {
        !tokens.contains(&agreement.id())
            && !agreement
                .exchange_group_id()
                .is_some_and(|group| tokens.contains(&group))
    })
}

fn generated_trade_id(
    diplomacy: &Diplomacy,
    importer: &PlayerId,
    exporter: &PlayerId,
    resource: ResourceType,
) -> Result<String, DiplomacyError> {
    let mut count = diplomacy.resource_trade_agreements().len();
    loop {
        let id = format!(
            "resource_trade_{}_{}_{}_{}",
            importer.as_str(),
            exporter.as_str(),
            resource_token(resource),
            count
        );
        if agreement_tokens_available(diplomacy.resource_trade_agreements(), &[&id]) {
            return Ok(id);
        }
        count = count
            .checked_add(1)
            .ok_or_else(|| DiplomacyError::InvalidState("agreement id counter overflow".into()))?;
    }
}

fn generated_exchange_id(
    diplomacy: &Diplomacy,
    actor: &PlayerId,
    target: &PlayerId,
    offered: ResourceType,
    requested: ResourceType,
) -> Result<String, DiplomacyError> {
    let mut count = diplomacy.resource_trade_agreements().len();
    loop {
        let base = format!(
            "resource_exchange_{}_{}_{}_{}_{}",
            actor.as_str(),
            target.as_str(),
            resource_token(offered),
            resource_token(requested),
            count
        );
        let requested_leg = format!("{base}_requested");
        let offered_leg = format!("{base}_offered");
        if agreement_tokens_available(
            diplomacy.resource_trade_agreements(),
            &[&base, &requested_leg, &offered_leg],
        ) {
            return Ok(base);
        }
        count = count
            .checked_add(1)
            .ok_or_else(|| DiplomacyError::InvalidState("agreement id counter overflow".into()))?;
    }
}

fn export_availability(
    state: &GameState,
    context: EngineContext<'_>,
    exporter: &PlayerId,
    resource: ResourceType,
) -> Result<i64, DiplomacyError> {
    let output = if resource.is_stockpiled() {
        crate::economy::rules::strategic_resource_projection_for_player(state, context, exporter)
            .map_err(|error| DiplomacyError::InvalidState(error.to_string().into()))?
            .output()
            .get(&resource)
            .copied()
            .unwrap_or(0)
    } else {
        controlled_resource_count(state, context, exporter, resource)
    };
    let committed = state
        .diplomacy()
        .resource_trade_agreements()
        .iter()
        .filter(|agreement| {
            agreement.exporter_player_id() == exporter && agreement.resource() == resource
        })
        .try_fold(0_i64, |sum, agreement| {
            sum.checked_add(i64::from(agreement.amount_per_turn()))
        })
        .ok_or_else(|| DiplomacyError::InvalidState("resource commitment overflow".into()))?;
    Ok(output.saturating_sub(committed))
}

fn controlled_resource_count(
    state: &GameState,
    context: EngineContext<'_>,
    exporter: &PlayerId,
    resource: ResourceType,
) -> i64 {
    let empty_research = aonw_domain::PlayerResearchState::default();
    let research = state
        .research()
        .players()
        .get(exporter)
        .unwrap_or(&empty_research);
    if !TechnologyUnlockQuery::new(context.ruleset(), research).is_resource_revealed(resource) {
        return 0;
    }
    let mut coordinates = BTreeSet::new();
    for city in state
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == exporter)
    {
        coordinates.insert(city.center());
        coordinates.extend(city.controlled_hexes().iter().copied());
    }
    coordinates
        .into_iter()
        .filter(|coordinate| {
            crate::economy::rules::resources_at(state, context, *coordinate).contains(&resource)
        })
        .count()
        .try_into()
        .unwrap_or(i64::MAX)
}

const fn resource_token(resource: ResourceType) -> &'static str {
    match resource {
        ResourceType::Wheat => "wheat",
        ResourceType::Fish => "fish",
        ResourceType::Deer => "deer",
        ResourceType::Sheep => "sheep",
        ResourceType::Rice => "rice",
        ResourceType::Cow => "cow",
        ResourceType::Apple => "apple",
        ResourceType::Banana => "banana",
        ResourceType::Citrus => "citrus",
        ResourceType::Gold => "gold",
        ResourceType::Silver => "silver",
        ResourceType::Gems => "gems",
        ResourceType::Silk => "silk",
        ResourceType::Spices => "spices",
        ResourceType::Cotton => "cotton",
        ResourceType::Grapes => "grapes",
        ResourceType::Ivory => "ivory",
        ResourceType::Pearls => "pearls",
        ResourceType::Coffee => "coffee",
        ResourceType::Cocoa => "cocoa",
        ResourceType::Tobacco => "tobacco",
        ResourceType::Sugar => "sugar",
        ResourceType::Iron => "iron",
        ResourceType::Coal => "coal",
        ResourceType::Oil => "oil",
        ResourceType::Aluminium => "aluminium",
        ResourceType::Uranium => "uranium",
        ResourceType::Horses => "horses",
        ResourceType::Marble => "marble",
    }
}
