use serde::{Deserialize, Serialize};

use crate::path::wire::WirePath;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClipPathBatchBody {
    pub body: WirePath,
    pub body_fill_rule: String,
    pub need_line: bool,
    pub need_area: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClipPathBatchArgs {
    pub clip_region: WirePath,
    pub bodies: Vec<ClipPathBatchBody>,
    pub mode: String,
    pub clip_fill_rule: String,
    pub eps: Option<f64>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ClipPathOutput {
    pub line_path: Option<WirePath>,
    pub area_path: Option<WirePath>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ClipPathBatchOutput {
    pub outputs: Vec<ClipPathOutput>,
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::path::wire::{WireSegment, WireSubpath};

    #[test]
    fn round_trip_batch_args_via_cbor() {
        let path = WirePath {
            subpaths: vec![WireSubpath {
                origin: [0.0, 0.0],
                closed: false,
                segments: vec![WireSegment::Line { to: [1.0, 0.0] }],
            }],
        };
        let args = ClipPathBatchArgs {
            clip_region: path.clone(),
            bodies: vec![ClipPathBatchBody {
                body: path,
                body_fill_rule: "even-odd".into(),
                need_line: true,
                need_area: false,
            }],
            mode: "inside".into(),
            clip_fill_rule: "non-zero".into(),
            eps: None,
        };

        let mut buf = Vec::new();
        ciborium::ser::into_writer(&args, &mut buf).unwrap();
        let decoded: ClipPathBatchArgs = ciborium::de::from_reader(buf.as_slice()).unwrap();

        assert_eq!(decoded.mode, args.mode);
        assert_eq!(decoded.clip_fill_rule, args.clip_fill_rule);
        assert_eq!(decoded.eps, args.eps);
        assert_eq!(decoded.bodies.len(), 1);
        assert_eq!(decoded.bodies[0].body_fill_rule, "even-odd");
        assert!(decoded.bodies[0].need_line);
        assert!(!decoded.bodies[0].need_area);
    }
}
