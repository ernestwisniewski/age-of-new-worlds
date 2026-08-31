use aonw_domain::PlayerId;
use aonw_engine::CanonicalQueryError;

/// Rejection from changing the authenticated actor of a local hot-seat session.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ActorHandoffError {
    /// No local session is open.
    SessionNotOpen,
    /// A prior internal failure invalidated the session.
    SessionPoisoned,
    /// Actor handoff is restricted to an explicitly local hot-seat match.
    NotHotSeat,
    /// The requested actor is not a participant in the current match.
    UnknownPlayer(PlayerId),
    /// Recipient economy projection could not be rebuilt.
    Projection(CanonicalQueryError),
}

impl core::fmt::Display for ActorHandoffError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::SessionNotOpen => formatter.write_str("session is not open"),
            Self::SessionPoisoned => {
                formatter.write_str("session was invalidated by a prior internal failure")
            }
            Self::NotHotSeat => formatter.write_str("actor handoff requires a hot-seat match"),
            Self::UnknownPlayer(player) => write!(formatter, "unknown hot-seat actor: {player}"),
            Self::Projection(source) => write!(formatter, "recipient projection failed: {source}"),
        }
    }
}

impl std::error::Error for ActorHandoffError {}
