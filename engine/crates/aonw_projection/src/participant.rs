use aonw_domain::{Participant, PlayerCountry, PlayerId, PlayerKind};

/// Public immutable participant identity available to every match recipient.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerParticipantView {
    id: PlayerId,
    name: Box<str>,
    color_value: u32,
    country: PlayerCountry,
    kind: PlayerKind,
}

impl PlayerParticipantView {
    pub(crate) fn from_participant(value: &Participant) -> Self {
        Self {
            id: value.id().clone(),
            name: value.name().into(),
            color_value: value.color_value(),
            country: value.country(),
            kind: value.kind(),
        }
    }

    /// Returns the stable participant identifier.
    #[must_use]
    pub const fn id(&self) -> &PlayerId {
        &self.id
    }
    /// Returns the persisted participant display name.
    #[must_use]
    pub const fn name(&self) -> &str {
        &self.name
    }
    /// Returns the persisted participant ARGB color.
    #[must_use]
    pub const fn color_value(&self) -> u32 {
        self.color_value
    }
    /// Returns the participant country identity.
    #[must_use]
    pub const fn country(&self) -> PlayerCountry {
        self.country
    }
    /// Returns whether the participant is human- or engine-controlled.
    #[must_use]
    pub const fn kind(&self) -> PlayerKind {
        self.kind
    }
}
