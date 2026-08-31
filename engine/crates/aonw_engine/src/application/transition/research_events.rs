use aonw_domain::PlayerId;

/// Accepted fact that one participant produced positive science this turn.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ResearchPointsGainedEvent {
    player_id: PlayerId,
    points: i64,
}

impl ResearchPointsGainedEvent {
    pub(crate) const fn new(player_id: PlayerId, points: i64) -> Self {
        Self { player_id, points }
    }

    /// Returns the research owner.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }

    /// Returns the exact positive science total.
    #[must_use]
    pub const fn points(&self) -> i64 {
        self.points
    }
}

#[cfg(test)]
mod tests {
    use aonw_domain::PlayerId;

    use super::ResearchPointsGainedEvent;

    #[test]
    fn event_exposes_every_authoritative_field() {
        let player = PlayerId::new("player").expect("player");
        let event = ResearchPointsGainedEvent::new(player.clone(), 7);
        assert_eq!(event.player_id(), &player);
        assert_eq!(event.points(), 7);
    }
}
