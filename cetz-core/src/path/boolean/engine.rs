use std::panic::AssertUnwindSafe;

use kurbo::BezPath;
use linesweeper::topology::{BinaryWindingNumber, Topology};
use linesweeper::FillRule;

use crate::path::convert::bez_to_wire;
use crate::path::error::PathGeometryError;
use crate::path::fill::winding_inside;
use crate::path::wire::{WirePath, WireSubpath};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum BoolOp {
    Union,
    Intersection,
    Difference,
    Xor,
}

pub(crate) fn boolean_bez_paths(
    a: &BezPath,
    b: &BezPath,
    op: BoolOp,
    fill_rule_a: FillRule,
    fill_rule_b: FillRule,
    eps: f64,
) -> Result<WirePath, PathGeometryError> {
    // catch_unwind so a panic inside linesweeper turns into a recoverable
    // error rather than aborting the WASM module.
    let result = std::panic::catch_unwind(AssertUnwindSafe(|| {
        // We drive `Topology` directly instead of `linesweeper::binary_op` because
        // the latter accepts only a single global `FillRule`; we need one per operand.
        let topology = Topology::from_paths_binary(a, b, eps).map_err(|e| e.to_string())?;
        let inside = |w: &BinaryWindingNumber| {
            let ia = winding_inside(w.shape_a, fill_rule_a);
            let ib = winding_inside(w.shape_b, fill_rule_b);
            match op {
                BoolOp::Union => ia || ib,
                BoolOp::Intersection => ia && ib,
                BoolOp::Xor => ia != ib,
                BoolOp::Difference => ia && !ib,
            }
        };
        Ok::<_, String>(topology.contours(inside))
    }));

    let contours = match result {
        Ok(Ok(c)) => c,
        Ok(Err(msg)) => return Err(PathGeometryError::LinesweeperFailed(msg)),
        Err(_) => {
            return Err(PathGeometryError::LinesweeperFailed(
                "linesweeper panicked".into(),
            ));
        }
    };

    let mut combined_subpaths: Vec<WireSubpath> = Vec::new();
    for contour in contours.contours() {
        let mut wire = bez_to_wire(&contour.path)?;
        combined_subpaths.append(&mut wire.subpaths);
    }
    Ok(WirePath {
        subpaths: combined_subpaths,
    })
}
