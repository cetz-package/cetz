//! Error type for path boolean operations.

use std::fmt;

#[derive(Debug)]
pub enum PathBoolErr {
    InvalidOp(String),
    InvalidFillRule(String),
    OpenSubpath,
    /// MalformedPath refers to a path element that appeared without a preceding `MoveTo`.
    MalformedPath,
    /// Wraps any failure (or panic) from inside `linesweeper`.
    LinesweeperFailed(String),
}

impl fmt::Display for PathBoolErr {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            PathBoolErr::InvalidOp(op) => write!(f, "invalid path-bool op: {op:?}"),
            PathBoolErr::InvalidFillRule(rule) => write!(f, "invalid fill-rule: {rule:?}"),
            PathBoolErr::OpenSubpath => {
                write!(f, "path-bool wasm: every subpath should be closed")
            }
            PathBoolErr::MalformedPath => {
                write!(f, "path-bool wasm: found a malformed path which has a segment without preceding move-to")
            }
            PathBoolErr::LinesweeperFailed(msg) => {
                write!(f, "path-bool wasm: linesweeper failed: {msg}")
            }
        }
    }
}

impl std::error::Error for PathBoolErr {}
