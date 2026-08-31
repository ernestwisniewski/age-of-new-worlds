use aonw_domain::{HexCoord, MovementStep, QueuedMovePath};
use sha2::{Digest, Sha256};

pub(super) struct DigestWriter(Sha256);

impl DigestWriter {
    pub(super) fn new() -> Self {
        Self(Sha256::new())
    }

    pub(super) fn finish(self) -> [u8; 32] {
        self.0.finalize().into()
    }

    pub(super) fn u8(&mut self, value: u8) {
        self.0.update([value]);
    }

    pub(super) fn u16(&mut self, value: u16) {
        self.0.update(value.to_le_bytes());
    }

    pub(super) fn u32(&mut self, value: u32) {
        self.0.update(value.to_le_bytes());
    }

    pub(super) fn u64(&mut self, value: u64) {
        self.0.update(value.to_le_bytes());
    }

    pub(super) fn i64(&mut self, value: i64) {
        self.0.update(value.to_le_bytes());
    }

    pub(super) fn usize(&mut self, value: usize) {
        self.u64(u64::try_from(value).expect("bounded length"));
    }

    pub(super) fn text(&mut self, value: &str) {
        self.usize(value.len());
        self.0.update(value.as_bytes());
    }

    pub(super) fn coordinate(&mut self, value: HexCoord) {
        self.0.update(value.col().to_le_bytes());
        self.0.update(value.row().to_le_bytes());
    }

    pub(super) fn coordinates(&mut self, values: &[HexCoord]) {
        self.usize(values.len());
        for value in values {
            self.coordinate(*value);
        }
    }

    pub(super) fn optional_coordinate(&mut self, value: Option<HexCoord>) {
        match value {
            None => self.u8(0),
            Some(value) => {
                self.u8(1);
                self.coordinate(value);
            }
        }
    }

    pub(super) fn optional_u32(&mut self, value: Option<u32>) {
        match value {
            None => self.u8(0),
            Some(value) => {
                self.u8(1);
                self.u32(value);
            }
        }
    }

    pub(super) fn optional_i64(&mut self, value: Option<i64>) {
        match value {
            None => self.u8(0),
            Some(value) => {
                self.u8(1);
                self.i64(value);
            }
        }
    }

    pub(super) fn optional_text(&mut self, value: Option<&str>) {
        match value {
            None => self.u8(0),
            Some(value) => {
                self.u8(1);
                self.text(value);
            }
        }
    }

    pub(super) fn steps(&mut self, steps: &[MovementStep]) {
        self.usize(steps.len());
        for step in steps {
            self.coordinate(step.coordinate());
            self.u32(step.enter_cost().get());
            self.u32(step.cumulative_cost().get());
        }
    }

    pub(super) fn optional_route(&mut self, route: Option<&QueuedMovePath>) {
        match route {
            None => self.u8(0),
            Some(route) => {
                self.u8(1);
                self.coordinate(route.target());
                self.steps(route.steps());
            }
        }
    }
}
