/// Tile-indexed movement rules prepared once for one unit and world view.
#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct MovementAccess {
    tile_flags: Box<[u8]>,
}

impl MovementAccess {
    pub(crate) fn empty(tile_count: usize) -> Self {
        Self {
            tile_flags: vec![0; tile_count].into_boxed_slice(),
        }
    }

    pub(crate) fn block(&mut self, index: usize) {
        if let Some(flags) = self.tile_flags.get_mut(index) {
            *flags |= BLOCKED;
        }
    }

    pub(crate) fn reveal_city_center(&mut self, index: usize) {
        if let Some(flags) = self.tile_flags.get_mut(index) {
            *flags |= KNOWN_CITY_CENTER;
        }
    }

    pub(crate) fn reveal_operational_road(&mut self, index: usize) {
        if let Some(flags) = self.tile_flags.get_mut(index) {
            *flags |= KNOWN_OPERATIONAL_ROAD;
        }
    }

    pub(crate) fn blocks(&self, index: usize) -> bool {
        self.has_flag(index, BLOCKED).unwrap_or(true)
    }

    pub(crate) fn has_known_city_center(&self, index: usize) -> bool {
        self.has_flag(index, KNOWN_CITY_CENTER).unwrap_or(false)
    }

    pub(crate) fn has_known_operational_road(&self, index: usize) -> bool {
        self.has_flag(index, KNOWN_OPERATIONAL_ROAD)
            .unwrap_or(false)
    }

    fn has_flag(&self, index: usize, flag: u8) -> Option<bool> {
        self.tile_flags.get(index).map(|flags| flags & flag != 0)
    }
}

const BLOCKED: u8 = 1 << 0;
const KNOWN_CITY_CENTER: u8 = 1 << 1;
const KNOWN_OPERATIONAL_ROAD: u8 = 1 << 2;
