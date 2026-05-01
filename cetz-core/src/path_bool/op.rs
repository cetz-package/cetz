use std::panic::AssertUnwindSafe;

use kurbo::{BezPath, Shape};
use linesweeper::topology::{BinaryWindingNumber, Topology};
use linesweeper::{BinaryOp, FillRule};

use crate::path_bool::convert::{bez_to_wire, wire_to_bez};
use crate::path_bool::error::PathBoolErr;
use crate::path_bool::wire::{PathBoolArgs, PathBoolOutput, WirePath};

fn parse_op(op: &str) -> Result<BinaryOp, PathBoolErr> {
    match op {
        "union" => Ok(BinaryOp::Union),
        "intersection" => Ok(BinaryOp::Intersection),
        "difference" => Ok(BinaryOp::Difference),
        "xor" => Ok(BinaryOp::Xor),
        _ => Err(PathBoolErr::InvalidOp(op.to_string())),
    }
}

fn parse_fill_rule(rule: &str) -> Result<FillRule, PathBoolErr> {
    match rule {
        "non-zero" => Ok(FillRule::NonZero),
        "even-odd" => Ok(FillRule::EvenOdd),
        _ => Err(PathBoolErr::InvalidFillRule(rule.to_string())),
    }
}

/// Replicates the eps formula from `linesweeper::binary_op`.
fn auto_eps(a: &BezPath, b: &BezPath) -> Result<f64, PathBoolErr> {
    let bbox = a.bounding_box().union(b.bounding_box());
    let min = bbox.min_x().min(bbox.min_y());
    let max = bbox.max_x().max(bbox.max_y());
    if min.is_nan() || max.is_nan() {
        return Err(PathBoolErr::LinesweeperFailed(
            "NaN coordinate in input".into(),
        ));
    }
    if min.is_infinite() || max.is_infinite() {
        return Err(PathBoolErr::LinesweeperFailed(
            "infinite coordinate in input".into(),
        ));
    }
    let m = min.abs().max(max.abs());
    let eps = (m * (f64::EPSILON * 64.0)).max(1e-6);
    debug_assert!(eps.is_finite());
    Ok(eps)
}

fn winding_inside(winding: i32, fill_rule: FillRule) -> bool {
    match fill_rule {
        FillRule::EvenOdd => winding % 2 != 0,
        FillRule::NonZero => winding != 0,
    }
}

pub fn path_bool(args: PathBoolArgs) -> Result<PathBoolOutput, PathBoolErr> {
    let op = parse_op(&args.op)?;
    let fill_rule_a = parse_fill_rule(&args.fill_rule_a)?;
    let fill_rule_b = parse_fill_rule(&args.fill_rule_b)?;
    let a = wire_to_bez(&args.a)?;
    let b = wire_to_bez(&args.b)?;

    let eps = match args.eps {
        Some(eps) => eps,
        None => auto_eps(&a, &b)?,
    };

    // catch_unwind so a panic inside linesweeper turns into a recoverable
    // error rather than aborting the WASM module.
    let result = std::panic::catch_unwind(AssertUnwindSafe(|| {
        // We drive `Topology` directly instead of `linesweeper::binary_op` because
        // the latter accepts only a single global `FillRule`; we need one per operand.
        let topology = Topology::from_paths_binary(&a, &b, eps).map_err(|e| e.to_string())?;
        let inside = |w: &BinaryWindingNumber| {
            let ia = winding_inside(w.shape_a, fill_rule_a);
            let ib = winding_inside(w.shape_b, fill_rule_b);
            match op {
                BinaryOp::Union => ia || ib,
                BinaryOp::Intersection => ia && ib,
                BinaryOp::Xor => ia != ib,
                BinaryOp::Difference => ia && !ib,
            }
        };
        Ok::<_, String>(topology.contours(inside))
    }));

    let contours = match result {
        Ok(Ok(c)) => c,
        Ok(Err(msg)) => return Err(PathBoolErr::LinesweeperFailed(msg)),
        Err(_) => {
            return Err(PathBoolErr::LinesweeperFailed(
                "linesweeper panicked".into(),
            ));
        }
    };

    let mut combined = WirePath {
        subpaths: Vec::new(),
    };
    for contour in contours.contours() {
        let mut wire = bez_to_wire(&contour.path)?;
        combined.subpaths.append(&mut wire.subpaths);
    }
    Ok(PathBoolOutput { path: combined })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_op_all_valid() {
        assert!(matches!(parse_op("union"), Ok(BinaryOp::Union)));
        assert!(matches!(parse_op("intersection"), Ok(BinaryOp::Intersection)));
        assert!(matches!(parse_op("difference"), Ok(BinaryOp::Difference)));
        assert!(matches!(parse_op("xor"), Ok(BinaryOp::Xor)));
    }

    #[test]
    fn parse_op_invalid() {
        assert!(matches!(parse_op("subtract"), Err(PathBoolErr::InvalidOp(_))));
        assert!(matches!(parse_op(""), Err(PathBoolErr::InvalidOp(_))));
    }

    #[test]
    fn parse_fill_rule_all_valid() {
        assert!(matches!(parse_fill_rule("non-zero"), Ok(FillRule::NonZero)));
        assert!(matches!(parse_fill_rule("even-odd"), Ok(FillRule::EvenOdd)));
    }

    #[test]
    fn parse_fill_rule_invalid() {
        assert!(matches!(
            parse_fill_rule("evenodd"),
            Err(PathBoolErr::InvalidFillRule(_))
        ));
        assert!(matches!(
            parse_fill_rule("nonzero"),
            Err(PathBoolErr::InvalidFillRule(_))
        ));
    }

    #[test]
    fn winding_inside_non_zero() {
        assert!(!winding_inside(0, FillRule::NonZero));
        assert!(winding_inside(1, FillRule::NonZero));
        assert!(winding_inside(-1, FillRule::NonZero));
        assert!(winding_inside(2, FillRule::NonZero));
    }

    #[test]
    fn winding_inside_even_odd() {
        assert!(!winding_inside(0, FillRule::EvenOdd));
        assert!(winding_inside(1, FillRule::EvenOdd));
        assert!(!winding_inside(2, FillRule::EvenOdd));
        assert!(winding_inside(3, FillRule::EvenOdd));
        assert!(!winding_inside(-2, FillRule::EvenOdd));
    }

    #[test]
    fn auto_eps_rejects_inf() {
        let mut inf_path = BezPath::new();
        inf_path.move_to((f64::INFINITY, 0.0));
        inf_path.line_to((1.0, 1.0));
        inf_path.close_path();
        let normal = {
            let mut p = BezPath::new();
            p.move_to((0.0, 0.0));
            p.line_to((1.0, 0.0));
            p.line_to((1.0, 1.0));
            p.close_path();
            p
        };
        assert!(matches!(
            auto_eps(&inf_path, &normal),
            Err(PathBoolErr::LinesweeperFailed(_))
        ));
    }
}
