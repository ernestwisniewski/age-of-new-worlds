use serde::Serialize;

use aonw_domain::DiplomaticMessageResponse;

/// Immutable proposal and truce balance for the standard ruleset.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DiplomacyBalance {
    proposal_duration_turns: u32,
    message_duration_turns: u32,
    message_cooldown_turns: u32,
    promise_duration_turns: u32,
    truce_duration_turns: u32,
    friendship_accept_score_delta: i64,
    truce_accept_score_delta: i64,
    proposal_reject_score_delta: i64,
    war_declaration_score_delta: i64,
    war_declaration_observer_score_delta: i64,
    gold_gift_minimum_amount: i64,
    gold_gift_cooldown_turns: u32,
    gold_gift_max_score_delta: i64,
    promise_broken_score_delta: i64,
    friendly_resource_trade_gold_bonus: i64,
}

impl DiplomacyBalance {
    pub(super) const STANDARD: Self = Self {
        proposal_duration_turns: 5,
        message_duration_turns: 5,
        message_cooldown_turns: 5,
        promise_duration_turns: 3,
        truce_duration_turns: 10,
        friendship_accept_score_delta: 18,
        truce_accept_score_delta: 10,
        proposal_reject_score_delta: -6,
        war_declaration_score_delta: -25,
        war_declaration_observer_score_delta: -8,
        gold_gift_minimum_amount: 5,
        gold_gift_cooldown_turns: 5,
        gold_gift_max_score_delta: 12,
        promise_broken_score_delta: -15,
        friendly_resource_trade_gold_bonus: 1,
    };

    /// Returns how long a pending proposal remains actionable.
    #[must_use]
    pub const fn proposal_duration_turns(self) -> u32 {
        self.proposal_duration_turns
    }

    /// Returns how long an unanswered message remains actionable.
    #[must_use]
    pub const fn message_duration_turns(self) -> u32 {
        self.message_duration_turns
    }

    /// Returns the cooldown for another message in the same category.
    #[must_use]
    pub const fn message_cooldown_turns(self) -> u32 {
        self.message_cooldown_turns
    }

    /// Returns how long a conciliatory withdrawal promise remains active.
    #[must_use]
    pub const fn promise_duration_turns(self) -> u32 {
        self.promise_duration_turns
    }

    /// Returns how long an accepted truce protects both participants.
    #[must_use]
    pub const fn truce_duration_turns(self) -> u32 {
        self.truce_duration_turns
    }

    /// Returns the relation-score reward for accepted friendship.
    #[must_use]
    pub const fn friendship_accept_score_delta(self) -> i64 {
        self.friendship_accept_score_delta
    }

    /// Returns the relation-score reward for accepted truce.
    #[must_use]
    pub const fn truce_accept_score_delta(self) -> i64 {
        self.truce_accept_score_delta
    }

    /// Returns the relation-score penalty for rejecting a proposal.
    #[must_use]
    pub const fn proposal_reject_score_delta(self) -> i64 {
        self.proposal_reject_score_delta
    }

    /// Returns the direct relation-score penalty for declaring war.
    #[must_use]
    pub const fn war_declaration_score_delta(self) -> i64 {
        self.war_declaration_score_delta
    }

    /// Returns the reputation penalty applied by observers who know both sides.
    #[must_use]
    pub const fn war_declaration_observer_score_delta(self) -> i64 {
        self.war_declaration_observer_score_delta
    }

    /// Returns the smallest gift that can improve a relation.
    #[must_use]
    pub const fn gold_gift_minimum_amount(self) -> i64 {
        self.gold_gift_minimum_amount
    }

    /// Returns the cooldown between gifts for the same bilateral relation.
    #[must_use]
    pub const fn gold_gift_cooldown_turns(self) -> u32 {
        self.gold_gift_cooldown_turns
    }

    /// Returns the bounded score reward for one positive gold gift.
    #[must_use]
    pub const fn gold_gift_score_delta(self, amount: i64) -> i64 {
        if amount < self.gold_gift_minimum_amount {
            0
        } else {
            let scaled = amount / self.gold_gift_minimum_amount;
            if scaled > self.gold_gift_max_score_delta {
                self.gold_gift_max_score_delta
            } else {
                scaled
            }
        }
    }

    /// Returns the relation-score penalty when a withdrawal promise is broken.
    #[must_use]
    pub const fn promise_broken_score_delta(self) -> i64 {
        self.promise_broken_score_delta
    }

    /// Returns the exporter bonus for a positive trade between friendly players.
    #[must_use]
    pub const fn friendly_resource_trade_gold_bonus(self) -> i64 {
        self.friendly_resource_trade_gold_bonus
    }

    /// Returns the base relation-score effect of a message response tone.
    #[must_use]
    pub const fn message_response_score_delta(self, response: DiplomaticMessageResponse) -> i64 {
        match response {
            DiplomaticMessageResponse::Conciliatory => 12,
            DiplomaticMessageResponse::Neutral => 2,
            DiplomaticMessageResponse::Evasive => -8,
            DiplomaticMessageResponse::Aggressive => -18,
        }
    }

    /// Returns the extra response score for cooperation against a shared enemy.
    #[must_use]
    pub const fn common_enemy_cooperation_bonus(self, response: DiplomaticMessageResponse) -> i64 {
        match response {
            DiplomaticMessageResponse::Conciliatory => 8,
            DiplomaticMessageResponse::Neutral => 4,
            DiplomaticMessageResponse::Evasive | DiplomaticMessageResponse::Aggressive => 0,
        }
    }
}
