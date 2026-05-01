//! Wire format used to ferry paths and boolean-op requests between Typst
//! and the WASM module via CBOR.
//!
//! The Typst side flattens its 3D path representation to 2D wire segments and
//! is responsible for re-applying the z component on the way back; the wire
//! types here are strictly 2D.

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct WirePath {
    pub subpaths: Vec<WireSubpath>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct WireSubpath {
    pub origin: [f64; 2],
    pub closed: bool,
    pub segments: Vec<WireSegment>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(tag = "kind")]
pub enum WireSegment {
    #[serde(rename = "l")]
    Line { to: [f64; 2] },
    #[serde(rename = "c")]
    Cubic {
        c1: [f64; 2],
        c2: [f64; 2],
        to: [f64; 2],
    },
}

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

    #[test]
    fn round_trip_cubic_segment() {
        let path = WirePath {
            subpaths: vec![WireSubpath {
                origin: [0.0, 0.0],
                closed: true,
                segments: vec![WireSegment::Cubic {
                    c1: [0.5, 0.0],
                    c2: [1.0, 0.5],
                    to: [1.0, 1.0],
                }],
            }],
        };
        let mut buf = Vec::new();
        ciborium::ser::into_writer(&path, &mut buf).unwrap();
        let decoded: WirePath = ciborium::de::from_reader(buf.as_slice()).unwrap();
        assert_eq!(decoded, path);
    }
}
