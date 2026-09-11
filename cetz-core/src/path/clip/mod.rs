//! Path clipping operations.

mod api;
mod line;
mod protocol;

pub(crate) use api::clip_path_batch;
pub(crate) use protocol::ClipPathBatchArgs;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub(crate) enum ClipMode {
    Inside,
    Outside,
}
