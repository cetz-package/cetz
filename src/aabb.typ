#import "vector.typ"
#let cetz-core = plugin("../cetz-core/cetz_core.wasm")

/// Compute an axis aligned bounding box (aabb) for a list of <Type>vectors</Type>.
///
/// - pts (array): List of <Type>vector</Type>s.
/// - init (aabb): Initial aabb
/// -> aabb
#let aabb(pts, init: none) = {
  if type(pts) == array {
    let bounds = if init == none {
      if pts.len() == 0 {
        return none
      } else {
        let pt = pts.at(0)
        (low: pt, high: pt)
      }
    } else {
      init
    }
    assert(type(bounds) == dictionary, message: "Expected aabb dictionary, got: " + repr(bounds))
    assert(bounds.low.len() == 3, message: "Expected aabb dictionary with low and high keys, got: " + repr(bounds))
    assert(bounds.high.len() == 3, message: "Expected aabb dictionary with low and high keys, got: " + repr(bounds))
    assert(pts.len() > 0, message: "Expected non-empty array of vectors, got: " + repr(pts))

    for pt in pts {
      assert(type(pt) == array and pt.len() == 3, message: repr(init) + repr(pts))
    }

    let args = (bounds: bounds, points: pts)
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
