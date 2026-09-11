use kurbo::{BezPath, Shape};

use crate::path::error::PathGeometryError;

/// Replicates the eps formula from `linesweeper::binary_op`.
pub(crate) fn auto_eps(paths: &[&BezPath]) -> Result<f64, PathGeometryError> {
    let Some((first, rest)) = paths.split_first() else {
        return Ok(1e-6);
    };

    let mut bbox = first.bounding_box();
    for path in rest {
        bbox = bbox.union(path.bounding_box());
    }

    let min = bbox.min_x().min(bbox.min_y());
    let max = bbox.max_x().max(bbox.max_y());
    if min.is_nan() || max.is_nan() {
        return Err(PathGeometryError::LinesweeperFailed(
            "NaN coordinate in input".into(),
        ));
    }
    if min.is_infinite() || max.is_infinite() {
        return Err(PathGeometryError::LinesweeperFailed(
            "infinite coordinate in input".into(),
        ));
    }
    let m = min.abs().max(max.abs());
    let eps = (m * (f64::EPSILON * 64.0)).max(1e-6);
    debug_assert!(eps.is_finite());
    Ok(eps)
}

#[cfg(test)]
mod tests {
    use super::*;

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
            auto_eps(&[&inf_path, &normal]),
            Err(PathGeometryError::LinesweeperFailed(_))
        ));
    }
}
