use crate::{HexCoord, PlayerId};

/// Fog visibility of one coordinate for one player.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum FogVisibility {
    Hidden,
    Discovered,
    Visible,
}

/// Immutable fog state of one player.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerFog {
    player_id: PlayerId,
    discovered_hexes: Box<[HexCoord]>,
    visible_hexes: Box<[HexCoord]>,
}

impl PlayerFog {
    /// Constructs normalized fog. Visible coordinates are always discovered.
    #[must_use]
    pub fn new(
        player_id: PlayerId,
        discovered_hexes: impl IntoIterator<Item = HexCoord>,
        visible_hexes: impl IntoIterator<Item = HexCoord>,
    ) -> Self {
        let mut visible_hexes = visible_hexes.into_iter().collect::<Vec<_>>();
        visible_hexes.sort_unstable();
        visible_hexes.dedup();
        let mut discovered_hexes = discovered_hexes.into_iter().collect::<Vec<_>>();
        discovered_hexes.extend_from_slice(&visible_hexes);
        discovered_hexes.sort_unstable();
        discovered_hexes.dedup();
        Self {
            player_id,
            discovered_hexes: discovered_hexes.into_boxed_slice(),
            visible_hexes: visible_hexes.into_boxed_slice(),
        }
    }

    /// Returns the player identifier.
    #[must_use]
    pub const fn player_id(&self) -> &PlayerId {
        &self.player_id
    }

    /// Returns discovered coordinates in deterministic order.
    #[must_use]
    pub const fn discovered_hexes(&self) -> &[HexCoord] {
        &self.discovered_hexes
    }

    /// Returns currently visible coordinates in deterministic order.
    #[must_use]
    pub const fn visible_hexes(&self) -> &[HexCoord] {
        &self.visible_hexes
    }

    /// Returns visibility using binary lookup over normalized coordinates.
    #[must_use]
    pub fn visibility(&self, coordinate: HexCoord) -> FogVisibility {
        if self.visible_hexes.binary_search(&coordinate).is_ok() {
            FogVisibility::Visible
        } else if self.discovered_hexes.binary_search(&coordinate).is_ok() {
            FogVisibility::Discovered
        } else {
            FogVisibility::Hidden
        }
    }

    /// Replaces visible coordinates and retains all prior discoveries.
    #[must_use]
    pub fn with_visible_hexes(&self, visible_hexes: impl IntoIterator<Item = HexCoord>) -> Self {
        Self::new(
            self.player_id.clone(),
            self.discovered_hexes.iter().copied(),
            visible_hexes,
        )
    }
}

/// Canonical fog state sorted by player identifier.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct FogOfWar {
    players: Box<[PlayerFog]>,
}

impl FogOfWar {
    /// Normalizes player entries and rejects duplicate identifiers.
    ///
    /// # Errors
    ///
    /// Returns the duplicated player identifier.
    pub fn try_new(players: impl IntoIterator<Item = PlayerFog>) -> Result<Self, PlayerId> {
        let mut players = players.into_iter().collect::<Vec<_>>();
        players.sort_unstable_by(|left, right| left.player_id().cmp(right.player_id()));
        if let Some(pair) = players
            .windows(2)
            .find(|pair| pair[0].player_id() == pair[1].player_id())
        {
            return Err(pair[0].player_id().clone());
        }
        Ok(Self {
            players: players.into_boxed_slice(),
        })
    }

    /// Returns whether this state tracks a player and therefore enables fog.
    #[must_use]
    pub fn tracks(&self, player_id: &PlayerId) -> bool {
        self.player(player_id).is_some()
    }

    /// Returns one player's fog state.
    #[must_use]
    pub fn player(&self, player_id: &PlayerId) -> Option<&PlayerFog> {
        self.players
            .binary_search_by(|fog| fog.player_id().cmp(player_id))
            .ok()
            .map(|index| &self.players[index])
    }

    /// Returns all player fog entries in identifier order.
    #[must_use]
    pub const fn players(&self) -> &[PlayerFog] {
        &self.players
    }

    /// Returns one coordinate's visibility, or visible when fog is disabled.
    #[must_use]
    pub fn visibility(&self, player_id: &PlayerId, coordinate: HexCoord) -> FogVisibility {
        self.player(player_id)
            .map_or(FogVisibility::Visible, |fog| fog.visibility(coordinate))
    }

    /// Replaces or inserts one player's fog while preserving sorted storage.
    #[must_use]
    pub fn updating_player(&self, player: PlayerFog) -> Self {
        let mut players = self.players.to_vec();
        match players.binary_search_by(|fog| fog.player_id().cmp(player.player_id())) {
            Ok(index) => players[index] = player,
            Err(index) => players.insert(index, player),
        }
        Self {
            players: players.into_boxed_slice(),
        }
    }
}
