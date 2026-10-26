#import "vector.typ"
#import "wasm.typ": call_wasm
#let cetz-core = plugin("../cetz-core/cetz_core.wasm")

/// Compute an axis aligned bounding box (aabb) for a list of <Type>vectors</Type>.
///
/// - pts (array): List of <Type>vector</Type>s.
/// - init (aabb): Initial aabb
/// -> aabb
#let aabb(pts, init: none) = {
  // Pure Typst implementation (equivalent to the wasm `aabb_func`),
  // avoiding the CBOR encode/decode + plugin call overhead. Points are
  // normalized to three dimensions (missing components are zero, extra
  // components are ignored).
  let (lx, ly, lz, hx, hy, hz) = if init != none {
    let (low, high) = (init.low, init.high)
    (float(low.at(0, default: 0.0)), float(low.at(1, default: 0.0)), float(low.at(2, default: 0.0)),
     float(high.at(0, default: 0.0)), float(high.at(1, default: 0.0)), float(high.at(2, default: 0.0)))
  } else {
    if pts.len() == 0 {
      panic("Cannot compute AABB: Point list is empty and no initial bounds were provided.")
    }
    let p = pts.first()
    let (x, y, z) = (float(p.at(0, default: 0.0)), float(p.at(1, default: 0.0)), float(p.at(2, default: 0.0)))
    (x, y, z, x, y, z)
  }
  for pt in pts {
    let x = float(pt.at(0, default: 0.0))
    let y = float(pt.at(1, default: 0.0))
    let z = float(pt.at(2, default: 0.0))
    if x < lx { lx = x }
    if hx < x { hx = x }
    if y < ly { ly = y }
    if hy < y { hy = y }
    if z < lz { lz = z }
    if hz < z { hz = z }
  }
  return (low: (lx, ly, lz), high: (hx, hy, hz))
}

#let merge(a, b) = {
  if a == none { return b }
  if b == none { return a }

  import calc: min, max
  let (alx, aly, alz) = a.low
  let (ahx, ahy, ahz) = a.high
  let (blx, bly, blz) = b.low
  let (bhx, bhy, bhz) = b.high

  (low:  (min(alx, blx), min(aly, bly), min(alz, blz)),
   high: (max(ahx, bhx), max(ahy, bhy), max(ahz, bhz)))
}

/// Get the mid-point of an AABB as vector.
///
/// - bounds (aabb): The AABB to get the mid-point of.
/// -> vector
#let mid(bounds) = {
  return vector.scale(vector.add(bounds.low, bounds.high), .5)
}

/// Get four corner points of the AABB as vectors.
///
/// - bounds (aabb): The AABB
/// - fron (bool): Return the corner points for the high z component
/// -> array of vectors
#let corner-points(bounds, front: true) = {
  let z = if front {
    bounds.high.at(2, default: 0)
  } else {
    bounds.low.at(2, default: 0)
  }

  let (hx, hy, hz) = bounds.high
  let (lx, ly, lz) = bounds.low

  return (
    (hx, hy, z),
    (hx, ly, z),
    (lx, ly, z),
    (lx, hy, z),
  )
}

/// Get the size of an aabb as vector. This is a vector from the aabb's low to high.
///
/// - bounds (aabb): The aabb to get the size of.
/// -> vector
#let size(bounds) = {
  vector.sub(bounds.high, bounds.low).map(calc.abs)
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
