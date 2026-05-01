//! Conversion between the wire format and `kurbo::BezPath` (the path type
//! that `linesweeper` operates on).

use kurbo::{BezPath, PathEl, Point};

use crate::path_bool::error::PathBoolErr;
use crate::path_bool::wire::{WirePath, WireSegment, WireSubpath};

/// Convert a [`WirePath`] to a [`kurbo::BezPath`]. Open subpaths are rejected.
pub fn wire_to_bez(path: &WirePath) -> Result<BezPath, PathBoolErr> {
    let mut bez = BezPath::new();
    for subpath in &path.subpaths {
        if !subpath.closed {
            return Err(PathBoolErr::OpenSubpath);
        }
        bez.move_to(Point::new(subpath.origin[0], subpath.origin[1]));
        for seg in &subpath.segments {
            match seg {
                WireSegment::Line { to } => {
                    bez.line_to(Point::new(to[0], to[1]));
                }
                WireSegment::Cubic { c1, c2, to } => {
                    bez.curve_to(
                        Point::new(c1[0], c1[1]),
                        Point::new(c2[0], c2[1]),
                        Point::new(to[0], to[1]),
                    );
                }
            }
        }
        bez.close_path();
    }
    Ok(bez)
}

/// Convert a [`kurbo::BezPath`] back to the wire format. `QuadTo` segments
/// (which CeTZ does not natively support) are elevated to cubic.
pub fn bez_to_wire(path: &BezPath) -> Result<WirePath, PathBoolErr> {
    let mut subpaths: Vec<WireSubpath> = Vec::new();
    let mut current: Option<WireSubpath> = None;
    let mut current_pt: Option<Point> = None;

    fn last_subpath_mut(
        current: &mut Option<WireSubpath>,
    ) -> Result<&mut WireSubpath, PathBoolErr> {
        current.as_mut().ok_or(PathBoolErr::MalformedPath)
    }

    for el in path.iter() {
        match el {
            PathEl::MoveTo(p) => {
                if let Some(sp) = current.take() {
                    subpaths.push(sp);
                }
                current = Some(WireSubpath {
                    origin: [p.x, p.y],
                    closed: false,
                    segments: Vec::new(),
                });
                current_pt = Some(p);
            }
            PathEl::LineTo(p) => {
                let sp = last_subpath_mut(&mut current)?;
                sp.segments.push(WireSegment::Line { to: [p.x, p.y] });
                current_pt = Some(p);
            }
            PathEl::QuadTo(q, p) => {
                let p0 = current_pt.ok_or(PathBoolErr::MalformedPath)?;
                let sp = last_subpath_mut(&mut current)?;
                // Quadratic -> cubic elevation:
                //   C1 = P0 + 2/3 (Q - P0)
                //   C2 = P  + 2/3 (Q - P)
                let c1 = Point::new(
                    p0.x + 2.0 / 3.0 * (q.x - p0.x),
                    p0.y + 2.0 / 3.0 * (q.y - p0.y),
                );
                let c2 = Point::new(p.x + 2.0 / 3.0 * (q.x - p.x), p.y + 2.0 / 3.0 * (q.y - p.y));
                sp.segments.push(WireSegment::Cubic {
                    c1: [c1.x, c1.y],
                    c2: [c2.x, c2.y],
                    to: [p.x, p.y],
                });
                current_pt = Some(p);
            }
            PathEl::CurveTo(c1, c2, p) => {
                let sp = last_subpath_mut(&mut current)?;
                sp.segments.push(WireSegment::Cubic {
                    c1: [c1.x, c1.y],
                    c2: [c2.x, c2.y],
                    to: [p.x, p.y],
                });
                current_pt = Some(p);
            }
            PathEl::ClosePath => {
                let sp = last_subpath_mut(&mut current)?;
                sp.closed = true;
            }
        }
    }
    if let Some(sp) = current.take() {
        subpaths.push(sp);
    }
    Ok(WirePath { subpaths })
}

#[cfg(test)]
mod tests {
    use super::*;
    use kurbo::Shape;

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

    fn approx_eq(a: f64, b: f64) -> bool {
        (a - b).abs() < 1e-9
    }

    fn paths_equal(a: &WirePath, b: &WirePath) -> bool {
        if a.subpaths.len() != b.subpaths.len() {
            return false;
        }
        for (sa, sb) in a.subpaths.iter().zip(&b.subpaths) {
            if sa.closed != sb.closed
                || !approx_eq(sa.origin[0], sb.origin[0])
                || !approx_eq(sa.origin[1], sb.origin[1])
                || sa.segments.len() != sb.segments.len()
            {
                return false;
            }
            for (xa, xb) in sa.segments.iter().zip(&sb.segments) {
                match (xa, xb) {
                    (WireSegment::Line { to: ta }, WireSegment::Line { to: tb }) => {
                        if !approx_eq(ta[0], tb[0]) || !approx_eq(ta[1], tb[1]) {
                            return false;
                        }
                    }
                    (
                        WireSegment::Cubic {
                            c1: ca1,
                            c2: ca2,
                            to: ta,
                        },
                        WireSegment::Cubic {
                            c1: cb1,
                            c2: cb2,
                            to: tb,
                        },
                    ) => {
                        for (x, y) in [
                            (ca1[0], cb1[0]),
                            (ca1[1], cb1[1]),
                            (ca2[0], cb2[0]),
                            (ca2[1], cb2[1]),
                            (ta[0], tb[0]),
                            (ta[1], tb[1]),
                        ] {
                            if !approx_eq(x, y) {
                                return false;
                            }
                        }
                    }
                    _ => return false,
                }
            }
        }
        true
    }

    #[test]
    fn round_trip_rect() {
        let wire = rect_wire();
        let bez = wire_to_bez(&wire).unwrap();
        let back = bez_to_wire(&bez).unwrap();
        assert!(paths_equal(&wire, &back), "round-trip mismatch: {back:?}");
    }

    #[test]
    fn round_trip_unit_circle_via_kurbo() {
        // kurbo's Circle::to_path emits cubics
        let circ = kurbo::Circle::new((0.0, 0.0), 1.0);
        let bez = circ.to_path(0.1);
        let wire = bez_to_wire(&bez).unwrap();
        let bez2 = wire_to_bez(&wire).unwrap();
        let wire2 = bez_to_wire(&bez2).unwrap();
        assert!(paths_equal(&wire, &wire2));
        // kurbo approximates a circle with 4 cubics
        assert!(
            wire.subpaths[0].segments.len() >= 1,
            "expected at least one segment"
        );
        assert!(wire.subpaths[0].closed);
    }

    #[test]
    fn quad_elevation_to_cubic() {
        // P0=(0,0), Q=(1,2), P=(2,0)  ->  C1=(2/3, 4/3), C2=(4/3, 4/3)
        let mut bez = BezPath::new();
        bez.move_to(Point::new(0.0, 0.0));
        bez.quad_to(Point::new(1.0, 2.0), Point::new(2.0, 0.0));
        bez.line_to(Point::new(0.0, 0.0));
        bez.close_path();
        let wire = bez_to_wire(&bez).unwrap();
        assert_eq!(wire.subpaths.len(), 1);
        assert_eq!(wire.subpaths[0].segments.len(), 2);
        match &wire.subpaths[0].segments[0] {
            WireSegment::Cubic { c1, c2, to } => {
                assert!(approx_eq(c1[0], 2.0 / 3.0));
                assert!(approx_eq(c1[1], 4.0 / 3.0));
                assert!(approx_eq(c2[0], 4.0 / 3.0));
                assert!(approx_eq(c2[1], 4.0 / 3.0));
                assert!(approx_eq(to[0], 2.0));
                assert!(approx_eq(to[1], 0.0));
            }
            other => panic!("expected cubic, got {other:?}"),
        }
    }

    #[test]
    fn open_subpath_is_rejected() {
        let mut wire = rect_wire();
        wire.subpaths[0].closed = false;
        let err = wire_to_bez(&wire).unwrap_err();
        assert!(matches!(err, PathBoolErr::OpenSubpath));
    }
}
