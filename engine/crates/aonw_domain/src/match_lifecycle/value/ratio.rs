use std::cmp::Ordering;

use super::{DecimalMagnitude, MAX_RULE_NUMBER_BYTES};

// A bounded JSON coefficient times a u64 adds at most 20 decimal digits.
const PRODUCT_DIGITS: usize = MAX_RULE_NUMBER_BYTES + 20;

pub(super) fn integer_reaches_scaled_decimal(
    integer: u64,
    decimal: &DecimalMagnitude,
    factor: u64,
) -> bool {
    if factor == 0 || decimal.is_zero() {
        return true;
    }
    if integer == 0 {
        return false;
    }
    let mut product = [0_u8; PRODUCT_DIGITS];
    let digits = multiply_digits(&decimal.digits, factor, &mut product);
    let mut integer_digits = [0_u8; PRODUCT_DIGITS];
    let left = multiply_digits(&[1], integer, &mut integer_digits);
    let left_magnitude = i64::try_from(left.len()).unwrap_or(i64::MAX);
    let right_magnitude =
        i64::try_from(digits.len()).unwrap_or(i64::MAX) + i64::from(decimal.power_of_ten);
    match left_magnitude.cmp(&right_magnitude) {
        Ordering::Less => false,
        Ordering::Greater => true,
        Ordering::Equal => {
            (0..left.len().max(digits.len()))
                .map(|index| {
                    left.get(index)
                        .copied()
                        .unwrap_or_default()
                        .cmp(&digits.get(index).copied().unwrap_or_default())
                })
                .find(|ordering| *ordering != Ordering::Equal)
                .unwrap_or(Ordering::Equal)
                != Ordering::Less
        }
    }
}

fn multiply_digits<'a>(
    digits: &[u8],
    factor: u64,
    output: &'a mut [u8; PRODUCT_DIGITS],
) -> &'a [u8] {
    let mut cursor = output.len();
    let mut carry = 0_u128;
    for digit in digits.iter().rev() {
        let value = u128::from(*digit) * u128::from(factor) + carry;
        cursor -= 1;
        output[cursor] = u8::try_from(value % 10).unwrap_or_default();
        carry = value / 10;
    }
    while carry > 0 {
        cursor -= 1;
        output[cursor] = u8::try_from(carry % 10).unwrap_or_default();
        carry /= 10;
    }
    &output[cursor..]
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::RuleNumber;

    #[test]
    fn fixed_storage_matches_exact_decimal_arithmetic_at_boundaries() {
        for source in [
            "1e-2147483647",
            "1e2147483647",
            "60",
            "60.00000000000000000001",
            "59.99999999999999999999",
            "0.001",
            "100",
            "255",
            "9999999999999999999999999999999999999999999999999999999999999999",
        ] {
            let threshold = RuleNumber::new(source).unwrap();
            for (part, whole) in [
                (0, 1),
                (53, 100),
                (54, 100),
                (57, 100),
                (1, 3),
                (u32::MAX - 1, u32::MAX),
                (u32::MAX, 1),
                (u32::MAX, u32::MAX),
            ] {
                for percent in [0, 1, 90, 95, 100, 255] {
                    let left = DecimalMagnitude::from_u64(u64::from(part) * 10_000);
                    let right = threshold
                        .magnitude
                        .multiplied_by(whole)
                        .multiplied_by(u32::from(percent));
                    assert_eq!(
                        threshold.percent_requirement_fraction_met(part, whole, percent),
                        left.compare_positive(&right) != Ordering::Less,
                        "{source}, {part}/{whole}, {percent}"
                    );
                }
            }
        }
    }
}
