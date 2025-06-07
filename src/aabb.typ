#import "vector.typ"
#import "wasm.typ": call_wasm
#let cetz-core = plugin("../cetz-core/cetz_core.wasm")

/// Compute an axis aligned bounding box (aabb) for a list of <Type>vectors</Type>.
///
/// - pts (array): List of <Type>vector</Type>s.
/// - init (aabb): Initial aabb
/// -> aabb
#let aabb(pts, init: none) = {
  return call_wasm(cetz-core.aabb_func, (pts: pts, init: init))
}

/// Get the mid-point of an AABB as vector.
///
/// - bounds (aabb): The AABB to get the mid-point of.
/// -> vector
#let mid(bounds) = {
  return vector.scale(vector.add(bounds.low, bounds.high), .5)
}

/// Get the size of an aabb as vector. This is a vector from the aabb's low to high.
///
/// - bounds (aabb): The aabb to get the size of.
/// -> vector
#let size(bounds) = {
  return vector.sub(bounds.high, bounds.low)
}

/// Pad AABB with padding from dictionary with keys top, left, right and bottom.
///
/// - bounds (aabb): The AABB to pad.
/// - padding (none, dictionary): Padding values
///
/// -> aabb
#let padded(bounds, padding) = {
  if padding != none {
    bounds.low.at(0)  -= padding.at("left", default: 0)
    bounds.low.at(1)  -= padding.at("top", default: 0)
    bounds.high.at(0) += padding.at("right", default: 0)
    bounds.high.at(1) += padding.at("bottom", default: 0)
  }
  return bounds
}
