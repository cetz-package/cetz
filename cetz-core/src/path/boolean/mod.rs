//! Closed-area boolean operations and their Typst/WASM adapter.

mod api;
mod engine;
mod protocol;

pub(crate) use api::path_bool;
pub(crate) use engine::{boolean_bez_paths, BoolOp};
pub(crate) use protocol::PathBoolArgs;
