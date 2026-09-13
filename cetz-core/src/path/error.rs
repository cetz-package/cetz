//! Errors produced by path conversion and geometry engines.

use std::fmt;

#[derive(Debug)]
pub enum PathGeometryError {
    OpenSubpath,
    /// MalformedPath refers to a path element that appeared without a preceding `MoveTo`.
    MalformedPath,
    /// Wraps any failure (or panic) from inside `linesweeper`.
    LinesweeperFailed(String),
}

impl fmt::Display for PathGeometryError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            PathGeometryError::OpenSubpath => {
                write!(f, "path operation wasm: every subpath should be closed")
            }
            PathGeometryError::MalformedPath => {
                write!(f, "path operation wasm: found a malformed path which has a segment without preceding move-to")
            }
            PathGeometryError::LinesweeperFailed(msg) => {
                write!(f, "path operation wasm: linesweeper failed: {msg}")
            }
        }
    }
}

impl std::error::Error for PathGeometryError {}
