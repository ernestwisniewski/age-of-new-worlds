use crate::{CityId, HexCoord, PlayerId};

/// Persisted transport segment identity.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum TransportKind {
    Road,
}

/// Current condition of a road.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum TransportCondition {
    Operational,
    Pillaged,
}

/// One road segment occupying a coordinate.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TransportSegment {
    coordinate: HexCoord,
    kind: TransportKind,
    condition: TransportCondition,
    built_by_player_id: PlayerId,
    built_by_city_id: Option<CityId>,
}

impl TransportSegment {
    /// Constructs a road segment.
    #[must_use]
    pub const fn road(
        coordinate: HexCoord,
        condition: TransportCondition,
        built_by_player_id: PlayerId,
        built_by_city_id: Option<CityId>,
    ) -> Self {
        Self {
            coordinate,
            kind: TransportKind::Road,
            condition,
            built_by_player_id,
            built_by_city_id,
        }
    }

    /// Returns the segment coordinate.
    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }

    /// Returns the persisted transport segment identity.
    #[must_use]
    pub const fn kind(&self) -> TransportKind {
        self.kind
    }

    /// Returns whether the road can reduce movement cost.
    #[must_use]
    pub const fn is_operational(&self) -> bool {
        matches!(self.condition, TransportCondition::Operational)
    }

    /// Returns the segment condition.
    #[must_use]
    pub const fn condition(&self) -> TransportCondition {
        self.condition
    }

    /// Returns the builder player.
    #[must_use]
    pub const fn built_by_player_id(&self) -> &PlayerId {
        &self.built_by_player_id
    }

    /// Returns the owning builder city when present.
    #[must_use]
    pub const fn built_by_city_id(&self) -> Option<&CityId> {
        self.built_by_city_id.as_ref()
    }
}

/// Immutable road network sorted by coordinate.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct TransportNetwork {
    segments: Box<[TransportSegment]>,
    routing_fingerprint: Box<str>,
}

impl TransportNetwork {
    /// Normalizes segments and rejects duplicate coordinates.
    ///
    /// # Errors
    ///
    /// Returns the duplicated coordinate.
    pub fn try_new(segments: impl IntoIterator<Item = TransportSegment>) -> Result<Self, HexCoord> {
        let mut segments = segments.into_iter().collect::<Vec<_>>();
        if !segments
            .windows(2)
            .all(|pair| pair[0].coordinate() <= pair[1].coordinate())
        {
            segments.sort_unstable_by_key(TransportSegment::coordinate);
        }
        if let Some(pair) = segments
            .windows(2)
            .find(|pair| pair[0].coordinate() == pair[1].coordinate())
        {
            return Err(pair[0].coordinate());
        }
        let routing_fingerprint = routing_fingerprint(&segments);
        Ok(Self {
            segments: segments.into_boxed_slice(),
            routing_fingerprint,
        })
    }

    /// Returns the segment at a coordinate.
    #[must_use]
    pub fn at(&self, coordinate: HexCoord) -> Option<&TransportSegment> {
        self.segments
            .binary_search_by_key(&coordinate, TransportSegment::coordinate)
            .ok()
            .map(|index| &self.segments[index])
    }

    /// Returns segments in coordinate order.
    #[must_use]
    pub const fn segments(&self) -> &[TransportSegment] {
        &self.segments
    }

    /// Returns the compact deterministic identity used by persisted routes.
    #[must_use]
    pub fn routing_fingerprint(&self) -> &str {
        &self.routing_fingerprint
    }
}

fn routing_fingerprint(segments: &[TransportSegment]) -> Box<str> {
    if segments.is_empty() {
        return "".into();
    }
    let mut first = 0x811c_9dc5_u32;
    let mut second = 0x9e37_79b9_u32;
    for segment in segments {
        for value in [
            segment.coordinate().col().to_string(),
            segment.coordinate().row().to_string(),
            "road".to_owned(),
            match segment.condition() {
                TransportCondition::Operational => "operational".to_owned(),
                TransportCondition::Pillaged => "pillaged".to_owned(),
            },
            segment.built_by_player_id().as_str().to_owned(),
            segment
                .built_by_city_id()
                .map_or_else(String::new, |city| city.as_str().to_owned()),
        ] {
            for code_unit in value.encode_utf16() {
                first = (first ^ u32::from(code_unit)).wrapping_mul(0x0100_0193);
                second = (second ^ u32::from(code_unit)).wrapping_mul(0x85eb_ca6b);
            }
            first = (first ^ 0xff).wrapping_mul(0x0100_0193);
            second = (second ^ 0xff).wrapping_mul(0x85eb_ca6b);
        }
    }
    format!("{first:08x}{second:08x}").into()
}

#[cfg(test)]
mod tests {
    use crate::{
        CityId, HexCoord, PlayerId, TransportCondition, TransportNetwork, TransportSegment,
    };

    #[test]
    fn routing_fingerprint_is_empty_or_stable_after_normalization() {
        assert_eq!(TransportNetwork::default().routing_fingerprint(), "");
        let player = PlayerId::new("player-1").expect("player");
        let city = CityId::new("city-1").expect("city");
        let first = TransportSegment::road(
            HexCoord::new(2, 1),
            TransportCondition::Pillaged,
            player.clone(),
            None,
        );
        let second = TransportSegment::road(
            HexCoord::new(0, 0),
            TransportCondition::Operational,
            player,
            Some(city),
        );
        let forward = TransportNetwork::try_new([first.clone(), second.clone()]).expect("network");
        let reverse = TransportNetwork::try_new([second, first]).expect("network");

        assert_eq!(forward.routing_fingerprint(), reverse.routing_fingerprint());
        assert_eq!(forward.routing_fingerprint().len(), 16);
    }
}
