use std::{cmp::Ordering, collections::BTreeMap};

const MAX_RULE_NUMBER_BYTES: usize = 128;

/// Exact finite JSON number used by immutable rule configuration.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct RuleNumber {
    source: Box<str>,
    magnitude: DecimalMagnitude,
}

#[derive(Clone, Debug, Eq, PartialEq)]
struct DecimalMagnitude {
    negative: bool,
    digits: Box<[u8]>,
    power_of_ten: i32,
}

/// Failure raised for a non-JSON numeric representation.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct RuleNumberError;

impl core::fmt::Display for RuleNumberError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        write!(
            formatter,
            "rule number must be an exact JSON number of at most {MAX_RULE_NUMBER_BYTES} bytes with a bounded exponent"
        )
    }
}

impl std::error::Error for RuleNumberError {}

impl RuleNumber {
    /// Preserves an exact JSON number after lexical validation.
    ///
    /// # Errors
    ///
    /// Returns [`RuleNumberError`] when the value is not a JSON number.
    pub fn new(value: impl Into<Box<str>>) -> Result<Self, RuleNumberError> {
        let value = value.into();
        let magnitude = parse_json_number(&value)?;
        Ok(Self {
            source: value,
            magnitude,
        })
    }

    /// Returns the exact JSON representation.
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.source
    }

    /// Returns whether this value is strictly positive and no greater than an
    /// unsigned integer, using exact decimal comparison.
    #[must_use]
    pub fn is_positive_and_at_most_integer(&self, maximum: u32) -> bool {
        !self.magnitude.negative
            && !self.magnitude.is_zero()
            && self
                .magnitude
                .compare_positive(&DecimalMagnitude::from_u64(u64::from(maximum)))
                != Ordering::Greater
    }

    /// Compares an exact percentage threshold with one integer part/whole
    /// ratio without converting either side to floating point.
    #[must_use]
    pub fn percent_requirement_met(&self, part: u32, whole: u32) -> bool {
        if whole == 0 || self.magnitude.negative || self.magnitude.is_zero() {
            return false;
        }
        let left = DecimalMagnitude::from_u64(u64::from(part) * 100);
        let right = self.magnitude.multiplied_by(whole);
        left.compare_positive(&right) != Ordering::Less
    }
}

/// Typed recursive value used by the open-ended match balance object.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum RuleValue {
    /// JSON null.
    Null,
    /// JSON boolean.
    Bool(bool),
    /// Exact JSON number.
    Number(RuleNumber),
    /// JSON string.
    String(Box<str>),
    /// Ordered JSON array.
    Array(Box<[Self]>),
    /// Key-sorted JSON object.
    Object(BTreeMap<Box<str>, Self>),
}

fn parse_json_number(value: &str) -> Result<DecimalMagnitude, RuleNumberError> {
    if value.len() > MAX_RULE_NUMBER_BYTES {
        return Err(RuleNumberError);
    }
    let bytes = value.as_bytes();
    let negative = bytes.first() == Some(&b'-');
    let mut index = usize::from(negative);
    if index == bytes.len() {
        return Err(RuleNumberError);
    }
    let integer_start = index;
    match bytes[index] {
        b'0' => index += 1,
        b'1'..=b'9' => {
            index += 1;
            while bytes.get(index).is_some_and(u8::is_ascii_digit) {
                index += 1;
            }
        }
        _ => return Err(RuleNumberError),
    }
    let integer_end = index;
    let mut fraction_start = index;
    let mut fraction_end = index;
    if bytes.get(index) == Some(&b'.') {
        index += 1;
        fraction_start = index;
        while bytes.get(index).is_some_and(u8::is_ascii_digit) {
            index += 1;
        }
        if fraction_start == index {
            return Err(RuleNumberError);
        }
        fraction_end = index;
    }
    let mut exponent = 0_i32;
    if matches!(bytes.get(index), Some(b'e' | b'E')) {
        index += 1;
        let exponent_negative = bytes.get(index) == Some(&b'-');
        if matches!(bytes.get(index), Some(b'+' | b'-')) {
            index += 1;
        }
        let start = index;
        while bytes.get(index).is_some_and(u8::is_ascii_digit) {
            exponent = exponent
                .checked_mul(10)
                .and_then(|value| value.checked_add(i32::from(bytes[index] - b'0')))
                .ok_or(RuleNumberError)?;
            index += 1;
        }
        if start == index {
            return Err(RuleNumberError);
        }
        if exponent_negative {
            exponent = exponent.checked_neg().ok_or(RuleNumberError)?;
        }
    }
    if index != bytes.len() {
        return Err(RuleNumberError);
    }
    let mut digits = bytes[integer_start..integer_end]
        .iter()
        .chain(&bytes[fraction_start..fraction_end])
        .map(|byte| byte - b'0')
        .collect::<Vec<_>>();
    let first_non_zero = digits.iter().position(|digit| *digit != 0);
    if let Some(first_non_zero) = first_non_zero {
        digits.drain(..first_non_zero);
    } else {
        digits.clear();
        digits.push(0);
    }
    let fraction_digits =
        i32::try_from(fraction_end.saturating_sub(fraction_start)).map_err(|_| RuleNumberError)?;
    let mut power_of_ten = exponent
        .checked_sub(fraction_digits)
        .ok_or(RuleNumberError)?;
    while digits.len() > 1 && digits.last() == Some(&0) {
        digits.pop();
        power_of_ten = power_of_ten.checked_add(1).ok_or(RuleNumberError)?;
    }
    Ok(DecimalMagnitude {
        negative: negative && digits != [0],
        digits: digits.into_boxed_slice(),
        power_of_ten,
    })
}

impl DecimalMagnitude {
    fn from_u64(value: u64) -> Self {
        let mut digits = value
            .to_string()
            .bytes()
            .map(|byte| byte - b'0')
            .collect::<Vec<_>>();
        let mut power_of_ten = 0_i32;
        while digits.len() > 1 && digits.last() == Some(&0) {
            digits.pop();
            power_of_ten += 1;
        }
        Self {
            negative: false,
            digits: digits.into_boxed_slice(),
            power_of_ten,
        }
    }

    fn is_zero(&self) -> bool {
        self.digits.as_ref() == [0]
    }

    fn multiplied_by(&self, factor: u32) -> Self {
        if factor == 0 || self.is_zero() {
            return Self::from_u64(0);
        }
        let mut carry = 0_u64;
        let mut reversed = Vec::with_capacity(self.digits.len() + 10);
        for digit in self.digits.iter().rev() {
            let value = u64::from(*digit) * u64::from(factor) + carry;
            reversed.push(u8::try_from(value % 10).unwrap_or_default());
            carry = value / 10;
        }
        while carry > 0 {
            reversed.push(u8::try_from(carry % 10).unwrap_or_default());
            carry /= 10;
        }
        reversed.reverse();
        let mut result = Self {
            negative: self.negative,
            digits: reversed.into_boxed_slice(),
            power_of_ten: self.power_of_ten,
        };
        let mut digits = result.digits.into_vec();
        while digits.len() > 1 && digits.last() == Some(&0) {
            digits.pop();
            result.power_of_ten = result.power_of_ten.saturating_add(1);
        }
        result.digits = digits.into_boxed_slice();
        result
    }

    fn compare_positive(&self, other: &Self) -> Ordering {
        if self.is_zero() || other.is_zero() {
            return self.is_zero().cmp(&other.is_zero()).reverse();
        }
        let self_magnitude =
            i64::try_from(self.digits.len()).unwrap_or(i64::MAX) + i64::from(self.power_of_ten);
        let other_magnitude =
            i64::try_from(other.digits.len()).unwrap_or(i64::MAX) + i64::from(other.power_of_ten);
        match self_magnitude.cmp(&other_magnitude) {
            Ordering::Equal => {
                let compared_digits = self.digits.len().max(other.digits.len());
                (0..compared_digits)
                    .map(|index| {
                        self.digits
                            .get(index)
                            .copied()
                            .unwrap_or_default()
                            .cmp(&other.digits.get(index).copied().unwrap_or_default())
                    })
                    .find(|ordering| *ordering != Ordering::Equal)
                    .unwrap_or(Ordering::Equal)
            }
            ordering => ordering,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{RuleNumber, RuleNumberError};

    #[test]
    fn exact_json_numbers_are_validated_without_float_rounding() {
        assert_eq!(
            RuleNumber::new("12345678901234567890.125e-7")
                .expect("valid")
                .as_str(),
            "12345678901234567890.125e-7"
        );
        assert_eq!(RuleNumber::new("01"), Err(RuleNumberError));
        assert_eq!(RuleNumber::new("NaN"), Err(RuleNumberError));
    }
}
