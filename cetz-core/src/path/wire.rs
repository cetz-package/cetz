//! Wire format used to ferry paths between Typst and the WASM module via CBOR.
//!
//! The Typst side flattens its 3D path representation to 2D wire segments and
//! is responsible for re-applying the z component on the way back; the wire
//! types here are strictly 2D.

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct WirePath {
    pub subpaths: Vec<WireSubpath>,
}

impl WirePath {
    pub(crate) fn empty() -> Self {
        Self {
            subpaths: Vec::new(),
        }
    }

    pub(crate) fn is_empty(&self) -> bool {
        self.subpaths.is_empty()
    }
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

#[cfg(test)]
mod tests {
    use super::*;

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
