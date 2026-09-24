use std::fmt;

use crate::path::boolean::protocol::{PathBoolArgs, PathBoolOutput};
use crate::path::boolean::{boolean_bez_paths, BoolOp};
use crate::path::convert::wire_to_closed_bez;
use crate::path::error::PathGeometryError;
use crate::path::fill::parse_fill_rule;
use crate::path::tolerance::auto_eps;

#[derive(Debug)]
pub(crate) enum PathBooleanError {
    InvalidOp(String),
    InvalidFillRule(String),
    Geometry(PathGeometryError),
}

impl From<PathGeometryError> for PathBooleanError {
    fn from(error: PathGeometryError) -> Self {
        Self::Geometry(error)
    }
}

impl fmt::Display for PathBooleanError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidOp(op) => write!(f, "invalid boolean op: {op:?}"),
            Self::InvalidFillRule(rule) => write!(f, "invalid fill-rule: {rule:?}"),
            Self::Geometry(error) => error.fmt(f),
        }
    }
}

impl std::error::Error for PathBooleanError {}

fn parse_bool_op(op: &str) -> Result<BoolOp, PathBooleanError> {
    match op {
        "union" => Ok(BoolOp::Union),
        "intersection" => Ok(BoolOp::Intersection),
        "difference" => Ok(BoolOp::Difference),
        "xor" => Ok(BoolOp::Xor),
        _ => Err(PathBooleanError::InvalidOp(op.to_string())),
    }
}

pub(crate) fn path_bool(args: PathBoolArgs) -> Result<PathBoolOutput, PathBooleanError> {
    let op = parse_bool_op(&args.op)?;
    let fill_rule_a = parse_fill_rule(&args.fill_rule_a)
        .ok_or_else(|| PathBooleanError::InvalidFillRule(args.fill_rule_a.clone()))?;
    let fill_rule_b = parse_fill_rule(&args.fill_rule_b)
        .ok_or_else(|| PathBooleanError::InvalidFillRule(args.fill_rule_b.clone()))?;
    let a = wire_to_closed_bez(&args.a)?;
    let b = wire_to_closed_bez(&args.b)?;
    let eps = match args.eps {
        Some(eps) => eps,
        None => auto_eps(&[&a, &b])?,
    };

    let path = boolean_bez_paths(&a, &b, op, fill_rule_a, fill_rule_b, eps)?;

    Ok(PathBoolOutput { path })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_op_all_valid() {
        assert_eq!(parse_bool_op("union").unwrap(), BoolOp::Union);
        assert_eq!(parse_bool_op("intersection").unwrap(), BoolOp::Intersection);
        assert_eq!(parse_bool_op("difference").unwrap(), BoolOp::Difference);
        assert_eq!(parse_bool_op("xor").unwrap(), BoolOp::Xor);
    }

    #[test]
    fn parse_op_invalid() {
        assert!(matches!(
            parse_bool_op("subtract"),
            Err(PathBooleanError::InvalidOp(_))
        ));
        assert!(matches!(
            parse_bool_op(""),
            Err(PathBooleanError::InvalidOp(_))
        ));
    }
}
