#import "vector.typ"
#let cetz-core = plugin("../cetz-core/cetz_core.wasm")

/// Compute an axis aligned bounding box (aabb) for a list of <Type>vectors</Type>.
///
/// - pts (array): List of <Type>vector</Type>s or dictionary with keys low and high.
/// - init (aabb): Initial aabb
/// -> aabb
#let aabb(pts, init: none) = {
  if type(pts) == array {
    let args = (points: pts, init: init)
    let encoded = cbor.encode(args)
    let bounds = cbor(cetz-core.aabb_func(encoded))
    return bounds
  } else if type(pts) == dictionary {
    if init == none {
      return pts
    } else {
      return aabb((pts.low, pts.high,), init: init)
    }
  }

  panic("Expected array of vectors or bbox dictionary, got: " + repr(pts))
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
