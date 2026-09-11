use std::collections::HashMap;
use std::ops::Range;
use std::panic::AssertUnwindSafe;

use kurbo::{
    BezPath, CubicBez, ParamCurve, ParamCurveArclen, ParamCurveExtrema, ParamCurveNearest, PathSeg,
    Point, Shape,
};
use linesweeper::curve::{self, Order};
use linesweeper::sweep;
use linesweeper::{FillRule, SegIdx, Segments};

use crate::path::clip::ClipMode;
use crate::path::convert::wire_to_closed_bez;
use crate::path::error::PathGeometryError;
use crate::path::fill::winding_inside;
use crate::path::wire::{WirePath, WireSegment, WireSubpath};

const CURVE_BOUNDARY_PROBES: usize = 8;

#[derive(Debug, Clone)]
struct SourceSubpath {
    original_idx: usize,
    closed: bool,
    segments: Vec<SourceSegment>,
}

#[derive(Debug, Clone, Copy)]
struct SourceSegment {
    segment: PathSeg,
    bounds: CurveBounds,
    implicit_close: bool,
}

#[derive(Debug, Clone, Copy)]
struct CurveBounds {
    min_x: f64,
    min_y: f64,
    max_x: f64,
    max_y: f64,
}

#[derive(Debug, Clone)]
struct BoundaryEntry {
    bounds: CurveBounds,
    proximity_probes: Vec<BoundaryProbe>,
}

#[derive(Debug, Clone, Copy)]
struct BoundaryProbe {
    segment: PathSeg,
    bounds: CurveBounds,
}

#[derive(Debug, Clone)]
struct BoundaryIndex {
    entries: Vec<BoundaryEntry>,
}

impl CurveBounds {
    fn from_segment(segment: PathSeg) -> Self {
        let bounds = ParamCurveExtrema::bounding_box(&segment);
        Self {
            min_x: bounds.min_x(),
            min_y: bounds.min_y(),
            max_x: bounds.max_x(),
            max_y: bounds.max_y(),
        }
    }

    fn from_point(p: Point, tol: f64) -> Self {
        Self {
            min_x: p.x - tol,
            min_y: p.y - tol,
            max_x: p.x + tol,
            max_y: p.y + tol,
        }
    }

    fn expand(self, tol: f64) -> Self {
        Self {
            min_x: self.min_x - tol,
            min_y: self.min_y - tol,
            max_x: self.max_x + tol,
            max_y: self.max_y + tol,
        }
    }

    fn union(self, other: Self) -> Self {
        Self {
            min_x: self.min_x.min(other.min_x),
            min_y: self.min_y.min(other.min_y),
            max_x: self.max_x.max(other.max_x),
            max_y: self.max_y.max(other.max_y),
        }
    }

    fn overlaps(self, other: Self) -> bool {
        self.min_x <= other.max_x
            && self.max_x >= other.min_x
            && self.min_y <= other.max_y
            && self.max_y >= other.min_y
    }
}

impl BoundaryIndex {
    fn new(segments: impl IntoIterator<Item = PathSeg>) -> Self {
        let mut entries: Vec<_> = segments
            .into_iter()
            .map(|segment| {
                // These remain exact curve subsegments. Their tighter boxes
                // avoid expensive `nearest` calls for points that cannot be
                // near the boundary; they are never used as output geometry.
                let probe_count = if matches!(segment, PathSeg::Line(_)) {
                    1
                } else {
                    CURVE_BOUNDARY_PROBES
                };
                BoundaryEntry {
                    bounds: CurveBounds::from_segment(segment),
                    proximity_probes: (0..probe_count)
                        .map(|index| {
                            let start = index as f64 / probe_count as f64;
                            let end = (index + 1) as f64 / probe_count as f64;
                            let segment = segment.subsegment(start..end);
                            BoundaryProbe {
                                segment,
                                bounds: CurveBounds::from_segment(segment),
                            }
                        })
                        .collect(),
                }
            })
            .collect();
        entries.sort_by(|a, b| a.bounds.min_y.total_cmp(&b.bounds.min_y));
        Self { entries }
    }

    fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }

    fn any_overlapping(&self, bounds: CurveBounds) -> bool {
        for entry in &self.entries {
            if entry.bounds.min_y > bounds.max_y {
                break;
            }
            if entry.bounds.overlaps(bounds) {
                return true;
            }
        }
        false
    }

    fn segment_may_touch_boundary(&self, segment: &SourceSegment, tol: f64) -> bool {
        self.any_overlapping(segment.bounds.expand(tol))
    }

    fn point_on_boundary(&self, p: Point, accuracy: f64, tol: f64) -> bool {
        let tol_sq = tol * tol;
        let bounds = CurveBounds::from_point(p, tol);
        for entry in &self.entries {
            if entry.bounds.min_y > bounds.max_y {
                break;
            }
            if entry.bounds.overlaps(bounds) {
                for probe in &entry.proximity_probes {
                    if probe.bounds.overlaps(bounds)
                        && probe.segment.nearest(p, accuracy).distance_sq <= tol_sq
                    {
                        return true;
                    }
                }
            }
        }
        false
    }
}

fn subpath_to_bez(subpath: &WireSubpath) -> BezPath {
    let mut bez = BezPath::new();
    bez.move_to(Point::new(subpath.origin[0], subpath.origin[1]));
    for seg in &subpath.segments {
        match seg {
            WireSegment::Line { to } => bez.line_to(Point::new(to[0], to[1])),
            WireSegment::Cubic { c1, c2, to } => bez.curve_to(
                Point::new(c1[0], c1[1]),
                Point::new(c2[0], c2[1]),
                Point::new(to[0], to[1]),
            ),
        }
    }
    if subpath.closed {
        bez.close_path();
    }
    bez
}

fn source_subpaths(path: &WirePath) -> Vec<SourceSubpath> {
    path.subpaths
        .iter()
        .enumerate()
        .map(|(original_idx, subpath)| {
            let bez = subpath_to_bez(subpath);
            let explicit_len = subpath.segments.len();
            let segments = bez
                .segments()
                .enumerate()
                .map(|(segment_idx, segment)| SourceSegment {
                    segment,
                    bounds: CurveBounds::from_segment(segment),
                    implicit_close: subpath.closed && segment_idx >= explicit_len,
                })
                .collect();
            SourceSubpath {
                original_idx,
                closed: subpath.closed,
                segments,
            }
        })
        .collect()
}

impl SourceSegment {
    fn is_point_degenerate(&self, tol: f64) -> bool {
        self.bounds.max_x - self.bounds.min_x <= tol && self.bounds.max_y - self.bounds.min_y <= tol
    }

    fn subsegment(&self, range: Range<f64>) -> PathSeg {
        let segment = self.segment.subsegment(range);
        debug_assert!(!self.implicit_close || matches!(segment, PathSeg::Line(_)));
        segment
    }
}

#[derive(Debug, Clone)]
struct SweepPiece {
    subpath_idx: usize,
    segment_idx: usize,
    range: Range<f64>,
}

#[derive(Debug, Clone)]
struct PendingSweepPiece {
    source: SweepPiece,
    source_segment: PathSeg,
    segment: PathSeg,
    bounds: CurveBounds,
}

#[derive(Clone)]
struct PreparedClipContour {
    segments: Segments,
    boundary_pieces: Vec<BoundaryPiece>,
    bounds: CurveBounds,
}

#[derive(Debug, Clone, Copy)]
struct BoundaryPiece {
    segment: PathSeg,
    bounds: CurveBounds,
}

impl PreparedClipContour {
    fn may_touch(&self, bounds: CurveBounds, tol: f64) -> bool {
        let bounds = bounds.expand(tol);
        self.bounds.expand(tol).overlaps(bounds)
            && self
                .boundary_pieces
                .iter()
                .any(|boundary| boundary.bounds.overlaps(bounds))
    }
}

#[derive(Debug, Clone, Copy)]
enum ProjectionAxis {
    X,
    Y,
}

fn axis_value(point: Point, axis: ProjectionAxis) -> f64 {
    match axis {
        ProjectionAxis::X => point.x,
        ProjectionAxis::Y => point.y,
    }
}

fn axis_span(segment: PathSeg, axis: ProjectionAxis) -> f64 {
    (axis_value(segment.end(), axis) - axis_value(segment.start(), axis)).abs()
}

fn common_projection_axis(a: PathSeg, b: PathSeg, tol: f64) -> Option<ProjectionAxis> {
    if axis_span(a, ProjectionAxis::Y) > tol && axis_span(b, ProjectionAxis::Y) > tol {
        Some(ProjectionAxis::Y)
    } else if axis_span(a, ProjectionAxis::X) > tol && axis_span(b, ProjectionAxis::X) > tol {
        Some(ProjectionAxis::X)
    } else {
        None
    }
}

fn cubic_for_projection(segment: PathSeg, axis: ProjectionAxis) -> CubicBez {
    let mut cubic = segment.to_cubic();
    if matches!(axis, ProjectionAxis::X) {
        for point in [&mut cubic.p0, &mut cubic.p1, &mut cubic.p2, &mut cubic.p3] {
            std::mem::swap(&mut point.x, &mut point.y);
        }
    }
    if cubic.p0.y <= cubic.p3.y {
        cubic
    } else {
        CubicBez::new(cubic.p3, cubic.p2, cubic.p1, cubic.p0)
    }
}

fn project_event_t(
    segment: PathSeg,
    range: &Range<f64>,
    axis: ProjectionAxis,
    coordinate: f64,
    event_point: Point,
    point_tol: f64,
) -> Option<f64> {
    if !coordinate.is_finite() || range.end - range.start <= 1e-12 {
        return None;
    }

    let start_value = axis_value(segment.eval(range.start), axis);
    let end_value = axis_value(segment.eval(range.end), axis);
    if (end_value - start_value).abs() <= point_tol {
        let piece = segment.subsegment(range.clone());
        let local_t = piece.nearest(event_point, point_tol).t.clamp(0.0, 1.0);
        return Some(range.start + local_t * (range.end - range.start));
    }

    let target = coordinate.clamp(start_value.min(end_value), start_value.max(end_value));
    if matches!(segment, PathSeg::Line(_)) {
        let local_t = (target - start_value) / (end_value - start_value);
        return Some(
            (range.start + local_t * (range.end - range.start)).clamp(range.start, range.end),
        );
    }

    let increasing = start_value <= end_value;
    let mut lo = range.start;
    let mut hi = range.end;
    for _ in 0..64 {
        let mid = (lo + hi) * 0.5;
        let value = axis_value(segment.eval(mid), axis);
        if (value - target).abs() <= point_tol || hi - lo <= 1e-12 {
            return Some(mid.clamp(range.start, range.end));
        }
        if (value < target) == increasing {
            lo = mid;
        } else {
            hi = mid;
        }
    }
    Some(((lo + hi) * 0.5).clamp(range.start, range.end))
}

fn orient_for_sweep(segment: PathSeg) -> PathSeg {
    let start = segment.start();
    let end = segment.end();
    if (start.y, start.x) <= (end.y, end.x) {
        segment
    } else {
        segment.reverse()
    }
}

fn sweep_guard_path(bounds: CurveBounds, point_tol: f64) -> Result<BezPath, String> {
    let span = (bounds.max_x - bounds.min_x)
        .max(bounds.max_y - bounds.min_y)
        .max(1.0);
    let offset = (span * 4.0).max(point_tol * 16.0);
    let size = (span * 0.01).max(point_tol * 16.0);
    let x = bounds.max_x + offset;
    let y = bounds.max_y + offset;
    if ![x, y, x + size, y + size].into_iter().all(f64::is_finite) {
        return Err("could not place the linesweeper open-path guard contour".to_string());
    }

    let mut guard = BezPath::new();
    guard.move_to((x, y));
    guard.line_to((x + size, y));
    guard.line_to((x, y + size));
    guard.close_path();
    Ok(guard)
}

fn collect_pair_split_ts(
    body: &PendingSweepPiece,
    boundary: BoundaryPiece,
    ts: &mut Vec<f64>,
    point_tol: f64,
    eps: f64,
) -> bool {
    let Some(axis) = common_projection_axis(body.segment, boundary.segment, point_tol) else {
        return false;
    };

    let tolerance = eps.abs().max(1e-12);
    let body_cubic = cubic_for_projection(body.segment, axis);
    let boundary_cubic = cubic_for_projection(boundary.segment, axis);
    let order = curve::intersect_cubics(body_cubic, boundary_cubic, tolerance, tolerance * 0.5)
        .with_y_slop(tolerance);

    for (start, end, relation) in order.iter() {
        if relation != Order::Ish {
            continue;
        }
        let coordinate = if (start - body_cubic.p0.y).abs() <= tolerance {
            body_cubic.p0.y
        } else if (end - body_cubic.p3.y).abs() <= tolerance {
            body_cubic.p3.y
        } else {
            (start + end) * 0.5
        };
        let event_point = match axis {
            ProjectionAxis::X => Point::new(coordinate, 0.0),
            ProjectionAxis::Y => Point::new(0.0, coordinate),
        };
        if let Some(t) = project_event_t(
            body.source_segment,
            &body.source.range,
            axis,
            coordinate,
            event_point,
            point_tol,
        ) {
            ts.push(t);
        }
    }
    true
}

fn segment_param_tol(segment: PathSeg, eps: f64, point_tol: f64) -> f64 {
    let safe_eps = eps.abs().max(1e-12);
    let length = segment.arclen(point_tol);
    (safe_eps / length.max(safe_eps)).clamp(1e-12, 1e-6)
}

/// Collect exact line/curve intersections without invoking the substantially
/// more expensive general cubic comparator. `PathSeg::intersect_line` solves
/// the cubic line equation directly; the returned parameter still refers to
/// the original body segment, so reconstruction remains an exact subsegment.
fn collect_line_pair_split_ts(
    body: &PendingSweepPiece,
    boundary: BoundaryPiece,
    ts: &mut Vec<f64>,
    point_tol: f64,
    eps: f64,
) -> bool {
    let param_tol = segment_param_tol(body.source_segment, eps, point_tol);
    let range = &body.source.range;
    let mut push_if_in_piece = |t: f64| {
        if t >= range.start - param_tol && t <= range.end + param_tol {
            ts.push(t.clamp(range.start, range.end));
        }
    };

    if let PathSeg::Line(body_line) = body.source_segment {
        for intersection in boundary.segment.intersect_line(body_line) {
            push_if_in_piece(intersection.line_t);
        }
        return true;
    }

    if let PathSeg::Line(boundary_line) = boundary.segment {
        for intersection in body.source_segment.intersect_line(boundary_line) {
            push_if_in_piece(intersection.segment_t);
        }
        return true;
    }

    false
}

fn collect_split_ts(
    clip_contours: &[PreparedClipContour],
    body: &[SourceSubpath],
    touch_candidates: &[Vec<bool>],
    point_tol: f64,
    boundary_tol: f64,
    eps: f64,
) -> Result<Vec<Vec<Vec<f64>>>, PathGeometryError> {
    let mut split_ts: Vec<Vec<Vec<f64>>> = body
        .iter()
        .map(|subpath| subpath.segments.iter().map(|_| vec![0.0, 1.0]).collect())
        .collect();

    if !touch_candidates
        .iter()
        .flatten()
        .any(|candidate| *candidate)
    {
        return Ok(split_ts);
    }

    let result = std::panic::catch_unwind(AssertUnwindSafe(|| {
        let mut pending = Vec::new();
        for (subpath_idx, (subpath, candidates)) in body.iter().zip(touch_candidates).enumerate() {
            for (segment_idx, (source, candidate)) in
                subpath.segments.iter().zip(candidates).enumerate()
            {
                if !candidate {
                    continue;
                }
                for range in source.segment.extrema_ranges() {
                    if range.end - range.start <= 1e-12 {
                        continue;
                    }
                    let piece = source.subsegment(range.clone());
                    let bounds = CurveBounds::from_segment(piece);
                    if bounds.max_x - bounds.min_x <= point_tol
                        && bounds.max_y - bounds.min_y <= point_tol
                    {
                        continue;
                    }
                    pending.push(PendingSweepPiece {
                        source: SweepPiece {
                            subpath_idx,
                            segment_idx,
                            range,
                        },
                        source_segment: source.segment,
                        segment: orient_for_sweep(piece),
                        bounds,
                    });
                }
            }
        }

        if pending.is_empty() {
            return Ok(());
        }

        for contour in clip_contours {
            let mut contour_pending = Vec::new();
            for piece in pending
                .iter()
                .filter(|piece| contour.may_touch(piece.bounds, boundary_tol))
            {
                let mut needs_sweep = false;
                for boundary in
                    contour.boundary_pieces.iter().copied().filter(|boundary| {
                        boundary.bounds.overlaps(piece.bounds.expand(boundary_tol))
                    })
                {
                    let ts = &mut split_ts[piece.source.subpath_idx][piece.source.segment_idx];
                    if collect_line_pair_split_ts(piece, boundary, ts, point_tol, eps) {
                        continue;
                    }
                    if !collect_pair_split_ts(piece, boundary, ts, point_tol, eps) {
                        needs_sweep = true;
                    }
                }
                if needs_sweep {
                    contour_pending.push(piece.clone());
                }
            }
            if contour_pending.is_empty() {
                continue;
            }

            // linesweeper 0.3 leaves open-subpath contour links pointing at
            // adjacent arena entries. A closed guard after the prepared clip
            // isolates the first stale link. Sweep-orienting the pieces and
            // ordering their starts from larger to smaller sweep y keeps later
            // stale links from being mistaken for real contour continuations.
            contour_pending.sort_by(|a, b| {
                let a = a.segment.start();
                let b = b.segment.start();
                b.y.total_cmp(&a.y).then_with(|| b.x.total_cmp(&a.x))
            });

            let mut body_path = BezPath::new();
            for piece in &contour_pending {
                body_path.move_to(piece.segment.start());
                body_path.push(piece.segment.as_path_el());
            }

            let combined_bounds = contour_pending
                .iter()
                .map(|piece| piece.bounds)
                .fold(contour.bounds, CurveBounds::union);
            let guard = sweep_guard_path(combined_bounds, point_tol)?;

            let mut segments = contour.segments.clone();
            segments
                .add_bez_path(&guard)
                .map_err(|err| err.to_string())?;
            let body_start = segments.len();
            segments
                .add_non_closed_bez_path(&body_path)
                .map_err(|err| err.to_string())?;

            let mut body_seg_map: HashMap<SegIdx, SweepPiece> = HashMap::new();
            let body_indices: Vec<_> = segments.indices().skip(body_start).collect();
            let mut cursor = 0;
            for piece in contour_pending {
                let expected_end = piece.segment.end();
                loop {
                    let Some(&idx) = body_indices.get(cursor) else {
                        return Err(
                            "could not map a linesweeper segment back to its source curve"
                                .to_string(),
                        );
                    };
                    cursor += 1;
                    body_seg_map.insert(idx, piece.source.clone());
                    let actual_end = segments.oriented_end(idx).to_kurbo();
                    if actual_end == expected_end {
                        break;
                    }
                }
            }

            if cursor != body_indices.len() {
                return Err("linesweeper produced an unexpected source-curve split".to_string());
            }

            sweep::sweep(&segments, eps, |y, ev| {
                if let Some(piece) = body_seg_map.get(&ev.seg_idx) {
                    let source = body[piece.subpath_idx].segments[piece.segment_idx].segment;
                    let ts = &mut split_ts[piece.subpath_idx][piece.segment_idx];
                    if segments[ev.seg_idx].is_horizontal() {
                        for x in [ev.x0, ev.x1] {
                            if let Some(t) = project_event_t(
                                source,
                                &piece.range,
                                ProjectionAxis::X,
                                x,
                                Point::new(x, y),
                                point_tol,
                            ) {
                                ts.push(t);
                            }
                        }
                    } else if let Some(t) = project_event_t(
                        source,
                        &piece.range,
                        ProjectionAxis::Y,
                        y,
                        Point::new((ev.x0 + ev.x1) * 0.5, y),
                        point_tol,
                    ) {
                        ts.push(t);
                    }
                }
            });
        }
        Ok::<(), String>(())
    }));

    match result {
        Ok(Ok(())) => Ok(split_ts),
        Ok(Err(err)) => Err(PathGeometryError::LinesweeperFailed(err)),
        Err(_) => Err(PathGeometryError::LinesweeperFailed(
            "linesweeper panicked".into(),
        )),
    }
}

fn body_touch_candidates(
    body: &[SourceSubpath],
    boundary: &BoundaryIndex,
    boundary_tol: f64,
    point_tol: f64,
) -> Vec<Vec<bool>> {
    body.iter()
        .map(|subpath| {
            subpath
                .segments
                .iter()
                .map(|segment| {
                    !segment.is_point_degenerate(point_tol)
                        && boundary.segment_may_touch_boundary(segment, boundary_tol)
                })
                .collect()
        })
        .collect()
}

fn normalize_ts(ts: &mut Vec<f64>, segment: PathSeg, eps: f64, point_tol: f64) -> f64 {
    ts.retain(|t| t.is_finite());
    ts.iter_mut().for_each(|t| *t = t.clamp(0.0, 1.0));
    ts.sort_by(f64::total_cmp);
    let tol = segment_param_tol(segment, eps, point_tol);
    ts.dedup_by(|a, b| (*a - *b).abs() <= tol);
    tol
}

fn classify_interval(
    clip_bez: &BezPath,
    boundary: &BoundaryIndex,
    fill_rule: FillRule,
    mode: ClipMode,
    p: Point,
    point_tol: f64,
    boundary_tol: f64,
) -> bool {
    let on_boundary = boundary.point_on_boundary(p, point_tol, boundary_tol);
    if on_boundary {
        return mode == ClipMode::Inside;
    }
    let inside = winding_inside(clip_bez.winding(p), fill_rule);
    match mode {
        ClipMode::Inside => inside,
        ClipMode::Outside => !inside,
    }
}

#[derive(Debug, Clone, Copy)]
struct SourcePosition {
    segment_idx: usize,
    t: f64,
}

#[derive(Debug, Clone)]
struct PathChunk {
    start: SourcePosition,
    end: SourcePosition,
    segments: Vec<PathSeg>,
}

impl PathChunk {
    fn new(start: SourcePosition, end: SourcePosition, segment: PathSeg) -> Self {
        Self {
            start,
            end,
            segments: vec![segment],
        }
    }

    fn push(&mut self, end: SourcePosition, segment: PathSeg) {
        self.end = end;
        self.segments.push(segment);
    }
}

fn append_kept_range(
    current: &mut Option<PathChunk>,
    source: &SourceSegment,
    segment_idx: usize,
    t0: f64,
    t1: f64,
) {
    let start = SourcePosition { segment_idx, t: t0 };
    let end = SourcePosition { segment_idx, t: t1 };
    let piece = source.subsegment(t0..t1);
    if let Some(chunk) = current {
        chunk.push(end, piece);
    } else {
        *current = Some(PathChunk::new(start, end, piece));
    }
}

fn position_at_path_start(
    position: SourcePosition,
    subpath: &SourceSubpath,
    point_tol: f64,
) -> bool {
    position.t == 0.0
        && subpath.segments[..position.segment_idx]
            .iter()
            .all(|segment| segment.is_point_degenerate(point_tol))
}

fn position_at_path_end(position: SourcePosition, subpath: &SourceSubpath, point_tol: f64) -> bool {
    position.t == 1.0
        && subpath.segments[position.segment_idx + 1..]
            .iter()
            .all(|segment| segment.is_point_degenerate(point_tol))
}

fn merge_closed_wraparound(chunks: &mut Vec<PathChunk>, subpath: &SourceSubpath, point_tol: f64) {
    if !subpath.closed || chunks.len() < 2 {
        return;
    }
    let joins_at_seam = position_at_path_start(chunks[0].start, subpath, point_tol)
        && position_at_path_end(chunks.last().unwrap().end, subpath, point_tol);
    if joins_at_seam {
        let first = chunks.remove(0);
        let mut last = chunks.pop().unwrap();
        last.end = first.end;
        last.segments.extend(first.segments);
        chunks.insert(0, last);
    }
}

fn path_segment_to_wire(segment: PathSeg) -> WireSegment {
    match segment {
        PathSeg::Line(line) => WireSegment::Line {
            to: [line.p1.x, line.p1.y],
        },
        PathSeg::Quad(quad) => {
            let c1 = quad.p0 + (quad.p1 - quad.p0) * (2.0 / 3.0);
            let c2 = quad.p2 + (quad.p1 - quad.p2) * (2.0 / 3.0);
            WireSegment::Cubic {
                c1: [c1.x, c1.y],
                c2: [c2.x, c2.y],
                to: [quad.p2.x, quad.p2.y],
            }
        }
        PathSeg::Cubic(cubic) => WireSegment::Cubic {
            c1: [cubic.p1.x, cubic.p1.y],
            c2: [cubic.p2.x, cubic.p2.y],
            to: [cubic.p3.x, cubic.p3.y],
        },
    }
}

fn chunks_to_wire(
    mut chunks: Vec<PathChunk>,
    source: &SourceSubpath,
    point_tol: f64,
) -> Vec<WireSubpath> {
    merge_closed_wraparound(&mut chunks, source, point_tol);
    chunks
        .into_iter()
        .filter_map(|chunk| {
            let origin = chunk.segments.first()?.start();
            let end = chunk.segments.last()?.end();
            let closed = source.closed && origin == end;
            let segments: Vec<_> = chunk
                .segments
                .into_iter()
                .map(path_segment_to_wire)
                .collect();
            if segments.is_empty() {
                return None;
            }
            Some(WireSubpath {
                origin: [origin.x, origin.y],
                closed,
                segments,
            })
        })
        .collect()
}

pub(crate) struct PreparedLineClip<'a> {
    clip_bez: &'a BezPath,
    clip_contours: Vec<PreparedClipContour>,
    boundary: BoundaryIndex,
    fill_rule: FillRule,
    mode: ClipMode,
    eps: f64,
    point_tol: f64,
    boundary_tol: f64,
    empty_clip: bool,
}

impl<'a> PreparedLineClip<'a> {
    pub(crate) fn new(
        clip_region: &WirePath,
        clip_bez: &'a BezPath,
        fill_rule: FillRule,
        mode: ClipMode,
        eps: f64,
    ) -> Result<Self, PathGeometryError> {
        let point_tol = eps.abs().max(1e-9);
        let boundary_tol = point_tol * 8.0;
        let boundary = BoundaryIndex::new(clip_bez.segments());
        let prepare_result = std::panic::catch_unwind(AssertUnwindSafe(|| {
            let mut contours = Vec::new();
            for subpath in &clip_region.subpaths {
                let path = subpath_to_bez(subpath);
                let source_segments: Vec<_> = path.segments().collect();
                let Some(bounds) = source_segments
                    .iter()
                    .copied()
                    .map(CurveBounds::from_segment)
                    .reduce(CurveBounds::union)
                else {
                    continue;
                };
                let mut segments = Segments::default();
                segments
                    .add_bez_path(&path)
                    .map_err(|err| err.to_string())?;
                if segments.len() == 0 {
                    continue;
                }
                contours.push(PreparedClipContour {
                    segments,
                    boundary_pieces: source_segments
                        .into_iter()
                        .flat_map(|segment| {
                            segment
                                .extrema_ranges()
                                .into_iter()
                                .map(move |range| segment.subsegment(range))
                        })
                        .map(|segment| BoundaryPiece {
                            segment,
                            bounds: CurveBounds::from_segment(segment),
                        })
                        .collect(),
                    bounds,
                });
            }
            Ok::<_, String>(contours)
        }));
        let clip_contours = match prepare_result {
            Ok(Ok(contours)) => contours,
            Ok(Err(err)) => return Err(PathGeometryError::LinesweeperFailed(err)),
            Err(_) => {
                return Err(PathGeometryError::LinesweeperFailed(
                    "linesweeper panicked while preparing the clip path".into(),
                ));
            }
        };
        let empty_clip = clip_region.is_empty() || boundary.is_empty() || clip_contours.is_empty();

        Ok(Self {
            clip_bez,
            clip_contours,
            boundary,
            fill_rule,
            mode,
            eps,
            point_tol,
            boundary_tol,
            empty_clip,
        })
    }

    pub(crate) fn clip_body(&self, body: &WirePath) -> Result<WirePath, PathGeometryError> {
        if self.empty_clip {
            return Ok(match self.mode {
                ClipMode::Inside => WirePath::empty(),
                ClipMode::Outside => body.clone(),
            });
        }

        let source_body = source_subpaths(body);
        if source_body.is_empty() {
            return Ok(WirePath::empty());
        }

        let touch_candidates = body_touch_candidates(
            &source_body,
            &self.boundary,
            self.boundary_tol,
            self.point_tol,
        );
        let mut split_ts = collect_split_ts(
            &self.clip_contours,
            &source_body,
            &touch_candidates,
            self.point_tol,
            self.boundary_tol,
            self.eps,
        )?;
        let mut output = WirePath::empty();

        for (subpath_idx, subpath) in source_body.iter().enumerate() {
            let may_touch_boundary = touch_candidates[subpath_idx]
                .iter()
                .any(|candidate| *candidate);
            if !may_touch_boundary {
                let p = subpath
                    .segments
                    .iter()
                    .find(|segment| !segment.is_point_degenerate(self.point_tol))
                    .map_or_else(
                        || {
                            let origin = body.subpaths[subpath.original_idx].origin;
                            Point::new(origin[0], origin[1])
                        },
                        |segment| segment.segment.eval(0.5),
                    );
                if classify_interval(
                    self.clip_bez,
                    &self.boundary,
                    self.fill_rule,
                    self.mode,
                    p,
                    self.point_tol,
                    self.boundary_tol,
                ) {
                    output
                        .subpaths
                        .push(body.subpaths[subpath.original_idx].clone());
                }
                continue;
            }

            let mut chunks = Vec::new();
            let mut current_chunk: Option<PathChunk> = None;
            let mut all_kept = true;
            let mut any_kept = false;
            let mut any_interval = false;
            for (segment_idx, source) in subpath.segments.iter().enumerate() {
                let ts = &mut split_ts[subpath_idx][segment_idx];
                let t_tol = normalize_ts(ts, source.segment, self.eps, self.point_tol);
                let mut kept_start = None;
                let mut kept_end = 0.0;
                for pair in ts.windows(2) {
                    let t0 = pair[0];
                    let t1 = pair[1];
                    if t1 - t0 <= t_tol {
                        continue;
                    }
                    let piece = source.subsegment(t0..t1);
                    let piece_bounds = CurveBounds::from_segment(piece);
                    if piece_bounds.max_x - piece_bounds.min_x <= self.point_tol
                        && piece_bounds.max_y - piece_bounds.min_y <= self.point_tol
                        || piece.arclen(self.point_tol) <= self.boundary_tol
                    {
                        continue;
                    }
                    any_interval = true;
                    let mid = source.segment.eval((t0 + t1) * 0.5);
                    if classify_interval(
                        self.clip_bez,
                        &self.boundary,
                        self.fill_rule,
                        self.mode,
                        mid,
                        self.point_tol,
                        self.boundary_tol,
                    ) {
                        any_kept = true;
                        kept_start.get_or_insert(t0);
                        kept_end = t1;
                    } else {
                        all_kept = false;
                        if let Some(start) = kept_start.take() {
                            append_kept_range(
                                &mut current_chunk,
                                source,
                                segment_idx,
                                start,
                                kept_end,
                            );
                        }
                        if let Some(chunk) = current_chunk.take() {
                            chunks.push(chunk);
                        }
                    }
                }
                if let Some(start) = kept_start.take() {
                    append_kept_range(&mut current_chunk, source, segment_idx, start, kept_end);
                }
            }
            if let Some(chunk) = current_chunk.take() {
                chunks.push(chunk);
            }

            if !any_interval {
                let origin = body.subpaths[subpath.original_idx].origin;
                let keep = classify_interval(
                    self.clip_bez,
                    &self.boundary,
                    self.fill_rule,
                    self.mode,
                    Point::new(origin[0], origin[1]),
                    self.point_tol,
                    self.boundary_tol,
                );
                if keep {
                    output
                        .subpaths
                        .push(body.subpaths[subpath.original_idx].clone());
                }
                continue;
            }

            if all_kept && any_kept {
                output
                    .subpaths
                    .push(body.subpaths[subpath.original_idx].clone());
            } else if any_kept {
                output
                    .subpaths
                    .extend(chunks_to_wire(chunks, subpath, self.point_tol));
            }
        }

        Ok(output)
    }
}

#[allow(dead_code)]
pub(crate) fn clip_line_path(
    clip_region: &WirePath,
    body: &WirePath,
    fill_rule: FillRule,
    mode: ClipMode,
    eps: f64,
) -> Result<WirePath, PathGeometryError> {
    let clip_bez = wire_to_closed_bez(clip_region)?;
    PreparedLineClip::new(clip_region, &clip_bez, fill_rule, mode, eps)?.clip_body(body)
}

#[cfg(test)]
mod tests {
    use super::*;
    use kurbo::CubicBez;

    fn rect_wire(min: (f64, f64), max: (f64, f64)) -> WirePath {
        WirePath {
            subpaths: vec![WireSubpath {
                origin: [min.0, min.1],
                closed: true,
                segments: vec![
                    WireSegment::Line { to: [max.0, min.1] },
                    WireSegment::Line { to: [max.0, max.1] },
                    WireSegment::Line { to: [min.0, max.1] },
                ],
            }],
        }
    }

    fn line_wire(a: (f64, f64), b: (f64, f64)) -> WirePath {
        WirePath {
            subpaths: vec![WireSubpath {
                origin: [a.0, a.1],
                closed: false,
                segments: vec![WireSegment::Line { to: [b.0, b.1] }],
            }],
        }
    }

    fn cubic_wire(start: (f64, f64), c1: (f64, f64), c2: (f64, f64), end: (f64, f64)) -> WirePath {
        WirePath {
            subpaths: vec![WireSubpath {
                origin: [start.0, start.1],
                closed: false,
                segments: vec![WireSegment::Cubic {
                    c1: [c1.0, c1.1],
                    c2: [c2.0, c2.1],
                    to: [end.0, end.1],
                }],
            }],
        }
    }

    fn assert_point_approx(actual: [f64; 2], expected: Point) {
        let distance = Point::new(actual[0], actual[1]).distance(expected);
        assert!(
            distance <= 2e-5,
            "point {actual:?} differs from {expected:?} by {distance}"
        );
    }

    fn assert_single_cubic(subpath: &WireSubpath, expected: CubicBez) {
        assert!(!subpath.closed);
        assert_point_approx(subpath.origin, expected.p0);
        assert_eq!(subpath.segments.len(), 1);
        let WireSegment::Cubic { c1, c2, to } = subpath.segments[0] else {
            panic!("expected a cubic segment: {subpath:?}");
        };
        assert_point_approx(c1, expected.p1);
        assert_point_approx(c2, expected.p2);
        assert_point_approx(to, expected.p3);
    }

    #[test]
    fn inside_open_line_through_rect() {
        let out = clip_line_path(
            &rect_wire((0.0, 0.0), (1.0, 1.0)),
            &line_wire((-1.0, 0.5), (2.0, 0.5)),
            FillRule::NonZero,
            ClipMode::Inside,
            1e-6,
        )
        .unwrap();
        assert_eq!(out.subpaths.len(), 1);
        assert_eq!(out.subpaths[0].origin, [0.0, 0.5]);
        assert_eq!(
            out.subpaths[0].segments,
            vec![WireSegment::Line { to: [1.0, 0.5] }]
        );
    }

    #[test]
    fn outside_open_line_through_rect() {
        let out = clip_line_path(
            &rect_wire((0.0, 0.0), (1.0, 1.0)),
            &line_wire((-1.0, 0.5), (2.0, 0.5)),
            FillRule::NonZero,
            ClipMode::Outside,
            1e-6,
        )
        .unwrap();
        assert_eq!(out.subpaths.len(), 2);
        assert_eq!(out.subpaths[0].origin, [-1.0, 0.5]);
        assert_eq!(out.subpaths[1].origin, [1.0, 0.5]);
    }

    #[test]
    fn boundary_line_inside_keeps_outside_drops() {
        let clip = rect_wire((0.0, 0.0), (1.0, 1.0));
        let body = line_wire((0.0, 0.0), (1.0, 0.0));
        let inside =
            clip_line_path(&clip, &body, FillRule::NonZero, ClipMode::Inside, 1e-6).unwrap();
        let outside =
            clip_line_path(&clip, &body, FillRule::NonZero, ClipMode::Outside, 1e-6).unwrap();
        assert_eq!(inside.subpaths.len(), 1);
        assert!(outside.subpaths.is_empty());
    }

    #[test]
    fn line_through_curved_boundary_uses_exact_intersections() {
        let arch = CubicBez::new((0.0, 0.0), (0.0, 1.0), (1.0, 1.0), (1.0, 0.0));
        let clip = WirePath {
            subpaths: vec![WireSubpath {
                origin: [arch.p0.x, arch.p0.y],
                closed: true,
                segments: vec![path_segment_to_wire(PathSeg::Cubic(arch))],
            }],
        };
        let out = clip_line_path(
            &clip,
            &line_wire((-1.0, 0.5), (2.0, 0.5)),
            FillRule::NonZero,
            ClipMode::Inside,
            1e-7,
        )
        .unwrap();

        let root_offset = 3.0_f64.sqrt();
        let start = arch.eval((3.0 - root_offset) / 6.0);
        let end = arch.eval((3.0 + root_offset) / 6.0);
        assert_eq!(out.subpaths.len(), 1, "{out:?}");
        assert_point_approx(out.subpaths[0].origin, start);
        let WireSegment::Line { to } = out.subpaths[0].segments[0] else {
            panic!("expected one retained line: {out:?}");
        };
        assert_point_approx(to, end);
    }

    #[test]
    fn clipped_closed_outline_becomes_open_piece() {
        let out = clip_line_path(
            &rect_wire((0.0, 0.0), (1.0, 1.0)),
            &rect_wire((-0.5, 0.25), (0.5, 0.75)),
            FillRule::NonZero,
            ClipMode::Inside,
            1e-6,
        )
        .unwrap();
        assert_eq!(out.subpaths.len(), 1);
        assert!(!out.subpaths[0].closed);
        assert_eq!(out.subpaths[0].origin, [0.0, 0.25]);
    }

    #[test]
    fn inside_curve_inside_rect_preserves_original_curve() {
        let body = cubic_wire((0.2, 0.2), (0.3, 0.9), (0.7, 0.1), (0.8, 0.8));
        let out = clip_line_path(
            &rect_wire((0.0, 0.0), (1.0, 1.0)),
            &body,
            FillRule::NonZero,
            ClipMode::Inside,
            1e-6,
        )
        .unwrap();
        assert_eq!(out, body);
    }

    #[test]
    fn outside_curve_outside_rect_preserves_original_curve() {
        let body = cubic_wire((2.0, 0.2), (2.3, 0.9), (2.7, 0.1), (2.8, 0.8));
        let out = clip_line_path(
            &rect_wire((0.0, 0.0), (1.0, 1.0)),
            &body,
            FillRule::NonZero,
            ClipMode::Outside,
            1e-6,
        )
        .unwrap();
        assert_eq!(out, body);
    }

    #[test]
    fn partial_cubic_inside_rect_remains_one_cubic() {
        let original = CubicBez::new((-1.0, 0.5), (0.0, 0.9), (1.0, 0.1), (2.0, 0.5));
        let body = cubic_wire((-1.0, 0.5), (0.0, 0.9), (1.0, 0.1), (2.0, 0.5));
        let out = clip_line_path(
            &rect_wire((0.0, 0.0), (1.0, 1.0)),
            &body,
            FillRule::NonZero,
            ClipMode::Inside,
            1e-7,
        )
        .unwrap();

        assert_eq!(out.subpaths.len(), 1, "{out:?}");
        assert_single_cubic(&out.subpaths[0], original.subsegment(1.0 / 3.0..2.0 / 3.0));
    }

    #[test]
    fn partial_cubic_outside_rect_remains_two_cubics() {
        let original = CubicBez::new((-1.0, 0.5), (0.0, 0.9), (1.0, 0.1), (2.0, 0.5));
        let body = cubic_wire((-1.0, 0.5), (0.0, 0.9), (1.0, 0.1), (2.0, 0.5));
        let out = clip_line_path(
            &rect_wire((0.0, 0.0), (1.0, 1.0)),
            &body,
            FillRule::NonZero,
            ClipMode::Outside,
            1e-7,
        )
        .unwrap();

        assert_eq!(out.subpaths.len(), 2, "{out:?}");
        assert_single_cubic(&out.subpaths[0], original.subsegment(0.0..1.0 / 3.0));
        assert_single_cubic(&out.subpaths[1], original.subsegment(2.0 / 3.0..1.0));
    }

    #[test]
    fn mixed_line_and_cubic_preserve_segment_kinds_and_order() {
        let body = WirePath {
            subpaths: vec![WireSubpath {
                origin: [-0.5, 0.5],
                closed: false,
                segments: vec![
                    WireSegment::Line { to: [0.25, 0.5] },
                    WireSegment::Cubic {
                        c1: [0.4, 0.9],
                        c2: [0.6, 0.1],
                        to: [0.75, 0.5],
                    },
                    WireSegment::Line { to: [1.5, 0.5] },
                ],
            }],
        };
        let out = clip_line_path(
            &rect_wire((0.0, 0.0), (1.0, 1.0)),
            &body,
            FillRule::NonZero,
            ClipMode::Inside,
            1e-7,
        )
        .unwrap();

        assert_eq!(out.subpaths.len(), 1, "{out:?}");
        assert!(matches!(
            out.subpaths[0].segments[0],
            WireSegment::Line { .. }
        ));
        assert!(matches!(
            out.subpaths[0].segments[1],
            WireSegment::Cubic { .. }
        ));
        assert!(matches!(
            out.subpaths[0].segments[2],
            WireSegment::Line { .. }
        ));
    }

    #[test]
    fn multi_crossing_cubic_produces_only_cubic_fragments() {
        let body = cubic_wire((-1.0, 0.0), (3.0, 1.0 / 3.0), (-3.0, 2.0 / 3.0), (1.0, 1.0));
        let out = clip_line_path(
            &rect_wire((0.0, -1.0), (4.0, 2.0)),
            &body,
            FillRule::NonZero,
            ClipMode::Inside,
            1e-7,
        )
        .unwrap();

        assert_eq!(out.subpaths.len(), 2, "{out:?}");
        assert!(out.subpaths.iter().all(|subpath| {
            subpath
                .segments
                .iter()
                .all(|segment| matches!(segment, WireSegment::Cubic { .. }))
        }));
    }

    #[test]
    fn horizontal_cubic_uses_x_projection_and_stays_cubic() {
        let original = CubicBez::new((-1.0, 0.5), (0.0, 0.5), (1.0, 0.5), (2.0, 0.5));
        let body = cubic_wire((-1.0, 0.5), (0.0, 0.5), (1.0, 0.5), (2.0, 0.5));
        let out = clip_line_path(
            &rect_wire((0.0, 0.0), (1.0, 1.0)),
            &body,
            FillRule::NonZero,
            ClipMode::Inside,
            1e-7,
        )
        .unwrap();

        assert_eq!(out.subpaths.len(), 1, "{out:?}");
        assert_single_cubic(&out.subpaths[0], original.subsegment(1.0 / 3.0..2.0 / 3.0));
    }

    #[test]
    fn tangent_touch_does_not_create_spurious_fragment() {
        let body = cubic_wire(
            (1.0, 0.0),
            (-1.0 / 3.0, 1.0 / 3.0),
            (-1.0 / 3.0, 2.0 / 3.0),
            (1.0, 1.0),
        );
        let clip = rect_wire((-2.0, -1.0), (0.0, 2.0));
        let inside =
            clip_line_path(&clip, &body, FillRule::NonZero, ClipMode::Inside, 1e-7).unwrap();
        let outside =
            clip_line_path(&clip, &body, FillRule::NonZero, ClipMode::Outside, 1e-7).unwrap();

        assert!(inside.subpaths.is_empty(), "{inside:?}");
        assert_eq!(outside, body);
    }

    #[test]
    fn cubic_on_curved_boundary_obeys_boundary_mode() {
        let boundary = WireSegment::Cubic {
            c1: [0.0, 1.0],
            c2: [1.0, 1.0],
            to: [1.0, 0.0],
        };
        let clip = WirePath {
            subpaths: vec![WireSubpath {
                origin: [0.0, 0.0],
                closed: true,
                segments: vec![boundary.clone()],
            }],
        };
        let body = WirePath {
            subpaths: vec![WireSubpath {
                origin: [0.0, 0.0],
                closed: false,
                segments: vec![boundary],
            }],
        };
        let inside =
            clip_line_path(&clip, &body, FillRule::NonZero, ClipMode::Inside, 1e-7).unwrap();
        let outside =
            clip_line_path(&clip, &body, FillRule::NonZero, ClipMode::Outside, 1e-7).unwrap();

        assert_eq!(inside, body);
        assert!(outside.subpaths.is_empty(), "{outside:?}");
    }

    #[test]
    fn partial_closed_curve_keeps_cubic_and_explicit_closing_line() {
        let body = WirePath {
            subpaths: vec![WireSubpath {
                origin: [-1.0, 0.5],
                closed: true,
                segments: vec![WireSegment::Cubic {
                    c1: [0.0, 0.9],
                    c2: [1.0, 0.1],
                    to: [2.0, 0.5],
                }],
            }],
        };
        let out = clip_line_path(
            &rect_wire((0.0, 0.0), (1.0, 1.0)),
            &body,
            FillRule::NonZero,
            ClipMode::Inside,
            1e-7,
        )
        .unwrap();

        assert_eq!(out.subpaths.len(), 2, "{out:?}");
        assert!(out.subpaths.iter().all(|subpath| !subpath.closed));
        assert!(out
            .subpaths
            .iter()
            .any(|subpath| matches!(subpath.segments.as_slice(), [WireSegment::Cubic { .. }])));
        assert!(out
            .subpaths
            .iter()
            .any(|subpath| matches!(subpath.segments.as_slice(), [WireSegment::Line { .. }])));
    }

    #[test]
    fn degenerate_and_self_intersecting_body_does_not_panic() {
        let body = WirePath {
            subpaths: vec![WireSubpath {
                origin: [0.5, 0.5],
                closed: false,
                segments: vec![
                    WireSegment::Line { to: [0.5, 0.5] },
                    WireSegment::Cubic {
                        c1: [2.0, -1.0],
                        c2: [-1.0, 2.0],
                        to: [0.5, 0.5],
                    },
                ],
            }],
        };
        let result = clip_line_path(
            &rect_wire((0.0, 0.0), (1.0, 1.0)),
            &body,
            FillRule::NonZero,
            ClipMode::Inside,
            1e-7,
        );
        assert!(result.is_ok());
    }

    #[test]
    fn empty_clip_outside_preserves_original_body() {
        let body = line_wire((0.0, 0.0), (1.0, 0.0));
        let out = clip_line_path(
            &WirePath::empty(),
            &body,
            FillRule::NonZero,
            ClipMode::Outside,
            1e-6,
        )
        .unwrap();
        assert_eq!(out, body);
    }

    #[test]
    fn zero_length_clip_outside_preserves_original_body() {
        let clip = WirePath {
            subpaths: vec![WireSubpath {
                origin: [0.0, 0.0],
                closed: true,
                segments: vec![WireSegment::Line { to: [0.0, 0.0] }],
            }],
        };
        let body = line_wire((0.0, 0.0), (1.0, 0.0));
        let out = clip_line_path(&clip, &body, FillRule::NonZero, ClipMode::Outside, 1e-6).unwrap();
        assert_eq!(out, body);
    }
}
