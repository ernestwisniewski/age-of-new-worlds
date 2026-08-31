use serde_json::{Map, Value};

const MAX_DIFFERENCES: usize = 64;
const MAX_RENDERED_VALUE_BYTES: usize = 256;

/// Classification of one structural JSON mismatch.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum DifferenceKind {
    /// Expected data is absent from the implementation output.
    Missing,
    /// Implementation output contains data absent from the expected result.
    Unexpected,
    /// Both sides have values at the path, but the values differ.
    ValueMismatch,
}

/// One bounded, human-readable structural difference.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct JsonDifference {
    path: Box<str>,
    kind: DifferenceKind,
    expected: Option<Box<str>>,
    actual: Option<Box<str>>,
}

impl JsonDifference {
    /// Returns the JSONPath-like location of the mismatch.
    #[must_use]
    pub fn path(&self) -> &str {
        &self.path
    }

    /// Returns the mismatch classification.
    #[must_use]
    pub const fn kind(&self) -> DifferenceKind {
        self.kind
    }

    /// Returns the bounded expected-value rendering.
    #[must_use]
    pub fn expected(&self) -> Option<&str> {
        self.expected.as_deref()
    }

    /// Returns the bounded implementation-value rendering.
    #[must_use]
    pub fn actual(&self) -> Option<&str> {
        self.actual.as_deref()
    }
}

/// Structurally compares JSON values.
///
/// Object key order is ignored because `serde_json` objects are maps. Array
/// order is retained and therefore detects reordered domain events.
#[must_use]
pub fn compare_json(expected: &Value, actual: &Value) -> Vec<JsonDifference> {
    let mut output = Vec::new();
    collect_differences("$", expected, actual, &mut output);
    output
}

fn collect_differences(
    path: &str,
    expected: &Value,
    actual: &Value,
    output: &mut Vec<JsonDifference>,
) {
    if output.len() >= MAX_DIFFERENCES || expected == actual {
        return;
    }

    match (expected, actual) {
        (Value::Object(expected), Value::Object(actual)) => {
            collect_object_differences(path, expected, actual, output);
        }
        (Value::Array(expected), Value::Array(actual)) => {
            let common_length = expected.len().min(actual.len());
            for index in 0..common_length {
                if output.len() >= MAX_DIFFERENCES {
                    break;
                }
                collect_differences(
                    &format!("{path}[{index}]"),
                    &expected[index],
                    &actual[index],
                    output,
                );
            }
            for (index, expected) in expected.iter().enumerate().skip(common_length) {
                if output.len() >= MAX_DIFFERENCES {
                    break;
                }
                output.push(difference(
                    format!("{path}[{index}]"),
                    DifferenceKind::Missing,
                    Some(expected),
                    None,
                ));
            }
            for (index, actual) in actual.iter().enumerate().skip(common_length) {
                if output.len() >= MAX_DIFFERENCES {
                    break;
                }
                output.push(difference(
                    format!("{path}[{index}]"),
                    DifferenceKind::Unexpected,
                    None,
                    Some(actual),
                ));
            }
        }
        _ => output.push(difference(
            path.to_owned(),
            DifferenceKind::ValueMismatch,
            Some(expected),
            Some(actual),
        )),
    }
}

fn collect_object_differences(
    path: &str,
    expected: &Map<String, Value>,
    actual: &Map<String, Value>,
    output: &mut Vec<JsonDifference>,
) {
    for (key, expected_value) in expected {
        if output.len() >= MAX_DIFFERENCES {
            break;
        }
        let child_path = object_path(path, key);
        if let Some(actual_value) = actual.get(key) {
            collect_differences(&child_path, expected_value, actual_value, output);
        } else {
            output.push(difference(
                child_path,
                DifferenceKind::Missing,
                Some(expected_value),
                None,
            ));
        }
    }
    for (key, actual_value) in actual {
        if output.len() >= MAX_DIFFERENCES {
            break;
        }
        if !expected.contains_key(key) {
            output.push(difference(
                object_path(path, key),
                DifferenceKind::Unexpected,
                None,
                Some(actual_value),
            ));
        }
    }
}

fn difference(
    path: String,
    kind: DifferenceKind,
    expected: Option<&Value>,
    actual: Option<&Value>,
) -> JsonDifference {
    JsonDifference {
        path: path.into_boxed_str(),
        kind,
        expected: expected.map(render_value),
        actual: actual.map(render_value),
    }
}

fn object_path(parent: &str, key: &str) -> String {
    if key
        .chars()
        .all(|character| character.is_ascii_alphanumeric() || character == '_')
    {
        format!("{parent}.{key}")
    } else {
        format!(
            "{parent}[{}]",
            serde_json::to_string(key).expect("string encoding is infallible")
        )
    }
}

fn render_value(value: &Value) -> Box<str> {
    match value {
        Value::Array(values) => format!("array(len={})", values.len()).into_boxed_str(),
        Value::Object(values) => format!("object(len={})", values.len()).into_boxed_str(),
        Value::String(value) => render_string(value),
        _ => value.to_string().into_boxed_str(),
    }
}

fn render_string(value: &str) -> Box<str> {
    if value.len() <= MAX_RENDERED_VALUE_BYTES {
        return serde_json::to_string(value)
            .expect("string encoding is infallible")
            .into_boxed_str();
    }
    let mut boundary = MAX_RENDERED_VALUE_BYTES;
    while !value.is_char_boundary(boundary) {
        boundary -= 1;
    }
    format!("{:?}…", &value[..boundary]).into_boxed_str()
}

#[cfg(test)]
mod tests {
    use serde_json::json;

    use super::{DifferenceKind, compare_json};

    #[test]
    fn object_order_is_irrelevant() {
        let expected = serde_json::from_str(r#"{"a":1,"b":2}"#).expect("valid json");
        let actual = serde_json::from_str(r#"{"b":2,"a":1}"#).expect("valid json");

        assert!(compare_json(&expected, &actual).is_empty());
    }

    #[test]
    fn array_order_remains_observable() {
        let differences = compare_json(&json!(["first", "second"]), &json!(["second", "first"]));

        assert_eq!(differences.len(), 2);
        assert_eq!(differences[0].path(), "$[0]");
        assert_eq!(differences[0].kind(), DifferenceKind::ValueMismatch);
    }

    #[test]
    fn missing_and_unexpected_fields_have_precise_paths() {
        let differences = compare_json(
            &json!({"state": {"turn": 2}}),
            &json!({"state": {"offset": 7}}),
        );

        assert_eq!(differences.len(), 2);
        assert_eq!(differences[0].path(), "$.state.turn");
        assert_eq!(differences[0].kind(), DifferenceKind::Missing);
        assert_eq!(differences[1].path(), "$.state.offset");
        assert_eq!(differences[1].kind(), DifferenceKind::Unexpected);
    }

    #[test]
    fn reported_differences_are_bounded() {
        let expected = json!((0..100).collect::<Vec<_>>());
        let actual = json!((100..200).collect::<Vec<_>>());

        assert_eq!(compare_json(&expected, &actual).len(), 64);
    }
}
