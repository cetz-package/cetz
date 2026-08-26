use serde::{Deserialize, Serialize};

use crate::path::wire::WirePath;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PathBoolArgs {
    pub a: WirePath,
    pub b: WirePath,
    pub op: String,
    /// Fill rule applied to `a`'s winding number when classifying regions.
    pub fill_rule_a: String,
    /// Fill rule applied to `b`'s winding number when classifying regions.
    pub fill_rule_b: String,
    /// `None` -> compute eps automatically from the combined bbox (mirrors
    /// linesweeper's own default in `binary_op`). `Some(eps)` -> use as-is.
    pub eps: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PathBoolOutput {
    pub path: WirePath,
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::path::wire::{WireSegment, WireSubpath};

    fn rect_wire() -> WirePath {
        WirePath {
            subpaths: vec![WireSubpath {
                origin: [0.0, 0.0],
                closed: true,
                segments: vec![
                    WireSegment::Line { to: [1.0, 0.0] },
                    WireSegment::Line { to: [1.0, 1.0] },
                    WireSegment::Line { to: [0.0, 1.0] },
                ],
            }],
        }
    }

    #[test]
    fn round_trip_rect_via_cbor() {
        let original = PathBoolArgs {
            a: rect_wire(),
            b: rect_wire(),
            op: "union".into(),
            fill_rule_a: "non-zero".into(),
            fill_rule_b: "even-odd".into(),
            eps: None,
        };

        let mut buf = Vec::new();
        ciborium::ser::into_writer(&original, &mut buf).unwrap();

        let decoded: PathBoolArgs = ciborium::de::from_reader(buf.as_slice()).unwrap();

        assert_eq!(decoded.a, original.a);
        assert_eq!(decoded.b, original.b);
        assert_eq!(decoded.op, original.op);
        assert_eq!(decoded.fill_rule_a, original.fill_rule_a);
        assert_eq!(decoded.fill_rule_b, original.fill_rule_b);
        assert_eq!(decoded.eps, original.eps);
    }
}
