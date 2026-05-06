//! Path boolean operations (union, intersection, difference, xor).
//!
//! Wraps the [`linesweeper`](https://crates.io/crates/linesweeper) crate
//! behind a CBOR wire format suitable for the Typst <-> WASM boundary.

mod convert;
mod error;
mod op;
mod wire;

pub use op::path_bool;
pub use wire::PathBoolArgs;
