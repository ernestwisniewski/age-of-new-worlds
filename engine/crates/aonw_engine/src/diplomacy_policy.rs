use aonw_domain::{
    Diplomacy, DiplomaticRelationStatus, GameState, MatchIdentity, PlayerId, PlayerPair,
};

/// Recipient-safe visibility of one bilateral diplomatic relation.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum DiplomacyDisclosure {
    /// Both identities refer to the same participant.
    Own,
    /// The participants have contact, so the relation may be disclosed.
    Known(DiplomaticRelationStatus),
    /// No contact exists; the effective default relation must not be disclosed.
    Hidden,
}

/// Role of an invalid participant in diplomacy-policy input validation.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum DiplomacyPolicyPlayerRole {
    /// The actor whose policy is being evaluated.
    Actor,
    /// The other participant affected by the policy.
    Counterparty,
}

/// Fail-closed diplomacy-policy input error.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomacyPolicyError {
    role: DiplomacyPolicyPlayerRole,
    player_id: PlayerId,
}

impl DiplomacyPolicyError {
    /// Returns which input failed validation.
    #[must_use]
    pub const fn role(&self) -> DiplomacyPolicyPlayerRole {
        self.role
    }

    /// Returns the unknown participant identity.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }
}

impl core::fmt::Display for DiplomacyPolicyError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        write!(
            formatter,
            "diplomacy policy {:?} is not a match participant: {}",
            self.role, self.player_id
        )
    }
}

impl std::error::Error for DiplomacyPolicyError {}

/// Complete read-only policy result for one ordered actor/counterparty pair.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct DiplomacyPolicy {
    same_player: bool,
    status: DiplomaticRelationStatus,
    status_expires_on_turn: Option<u32>,
    disclosure: DiplomacyDisclosure,
}

impl DiplomacyPolicy {
    /// Returns the effective current status used by authoritative rules.
    ///
    /// This value is internal rule input. Use [`Self::disclosure`] for recipient
    /// output so an undiscovered default-neutral relation is not leaked.
    #[must_use]
    pub const fn status(self) -> DiplomaticRelationStatus {
        self.status
    }

    /// Returns the authoritative expiry of a temporary relation status.
    #[must_use]
    pub const fn status_expires_on_turn(self) -> Option<u32> {
        self.status_expires_on_turn
    }

    /// Returns the recipient-safe relation disclosure.
    #[must_use]
    pub const fn disclosure(self) -> DiplomacyDisclosure {
        self.disclosure
    }

    /// Returns whether the counterparty is hostile for threat and AI policy.
    #[must_use]
    pub const fn is_hostile(self) -> bool {
        matches!(
            self.status,
            DiplomaticRelationStatus::Hostile | DiplomaticRelationStatus::War
        )
    }

    /// Returns whether the actor may enter the counterparty's city center.
    #[must_use]
    pub const fn can_enter_city_center(self) -> bool {
        self.same_player
    }

    /// Returns whether the actor may traverse the counterparty's territory.
    #[must_use]
    pub const fn can_enter_territory(self) -> bool {
        self.same_player || matches!(self.status, DiplomaticRelationStatus::Friendly)
    }

    /// Returns whether an attack may target the counterparty.
    #[must_use]
    pub const fn can_attack(self) -> bool {
        !self.same_player
            && !matches!(
                self.status,
                DiplomaticRelationStatus::Friendly | DiplomaticRelationStatus::Truce
            )
    }

    /// Returns whether automated movement may enter the counterparty's territory.
    #[must_use]
    pub const fn automation_eligible(self) -> bool {
        self.can_enter_territory()
    }

    /// Returns whether bilateral trade may be initiated.
    #[must_use]
    pub const fn trade_eligible(self) -> bool {
        !self.same_player && !matches!(self.status, DiplomaticRelationStatus::War)
    }
}

/// Single authoritative read-only diplomacy-policy entry point.
#[derive(Clone, Copy, Debug, Default)]
pub struct DiplomacyPolicyQuery;

impl DiplomacyPolicyQuery {
    /// Evaluates all bilateral policies with actor-first validation precedence.
    ///
    /// # Errors
    ///
    /// Returns the first unknown participant, validating the actor before the
    /// counterparty. A missing stored relation is the current neutral default.
    pub fn between(
        state: &GameState,
        actor_player_id: &PlayerId,
        counterparty_player_id: &PlayerId,
    ) -> Result<DiplomacyPolicy, DiplomacyPolicyError> {
        Self::between_parts(
            state.match_lifecycle().identity(),
            state.diplomacy(),
            actor_player_id,
            counterparty_player_id,
        )
    }

    pub(crate) fn between_parts(
        identity: &MatchIdentity,
        diplomacy: &Diplomacy,
        actor_player_id: &PlayerId,
        counterparty_player_id: &PlayerId,
    ) -> Result<DiplomacyPolicy, DiplomacyPolicyError> {
        validate_player(identity, actor_player_id, DiplomacyPolicyPlayerRole::Actor)?;
        validate_player(
            identity,
            counterparty_player_id,
            DiplomacyPolicyPlayerRole::Counterparty,
        )?;
        if actor_player_id == counterparty_player_id {
            return Ok(DiplomacyPolicy {
                same_player: true,
                status: DiplomaticRelationStatus::Neutral,
                status_expires_on_turn: None,
                disclosure: DiplomacyDisclosure::Own,
            });
        }

        let Some(pair) = PlayerPair::new(actor_player_id.clone(), counterparty_player_id.clone())
        else {
            return Ok(DiplomacyPolicy {
                same_player: true,
                status: DiplomaticRelationStatus::Neutral,
                status_expires_on_turn: None,
                disclosure: DiplomacyDisclosure::Own,
            });
        };
        let relation = diplomacy
            .relations()
            .binary_search_by(|relation| relation.pair().cmp(&pair))
            .ok()
            .map(|index| &diplomacy.relations()[index]);
        let status = relation.map_or(
            DiplomaticRelationStatus::Neutral,
            aonw_domain::DiplomaticRelation::status,
        );
        let status_expires_on_turn =
            relation.and_then(aonw_domain::DiplomaticRelation::status_expires_on_turn);
        let disclosure = if diplomacy.has_contact(actor_player_id, counterparty_player_id) {
            DiplomacyDisclosure::Known(status)
        } else {
            DiplomacyDisclosure::Hidden
        };
        Ok(DiplomacyPolicy {
            same_player: false,
            status,
            status_expires_on_turn,
            disclosure,
        })
    }
}

fn validate_player(
    identity: &MatchIdentity,
    player_id: &PlayerId,
    role: DiplomacyPolicyPlayerRole,
) -> Result<(), DiplomacyPolicyError> {
    if identity.contains(player_id) {
        Ok(())
    } else {
        Err(DiplomacyPolicyError {
            role,
            player_id: player_id.clone(),
        })
    }
}
