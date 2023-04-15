/// Return a new vector of dimension `dim` with all fields
/// set to `init` (defaults to 0).
#let new(dim, init: 0) = {
  return range(0, dim).map(x => init)
}

/// Return dimension of vector v
#let dim(v) = { assert(type(v) == "array"); return v.len() }

/// Return length of vector v
#let len(v) = {
  return calc.sqrt(v.fold(0, (s, c) => s + c * c))
}

/// Add two vectors of the same dimension
#let add(v1, v2) = {
  assert(dim(v1) == dim(v2))
  return v1.enumerate().map(t => t.at(1) + v2.at(t.at(0)))
}

/// Substract two vectors of the same dimension
#let sub(v1, v2) = {
  assert(dim(v1) == dim(v2))
  return v1.enumerate().map(t => t.at(1) - v2.at(t.at(0)))
}

/// Multiply each vector field with number `x`
#let mul(v, x) = {
  return v.map(c => c * x)
}

/// Divide each vector field by number `x`
#let div(v, x) = {
  return v.map(c => c / x)
}

/// Negate each vector field
#let neg(v) = {
  return mul(v, -1)
}

/// Normalize vector (divide by its length)
#let norm(v) = {
  return div(v, len(v))
}

/// Calculate dot product between two vectors `v1` and `v2`
#let dot(v1, v2) = {
  assert(dim(v1) == dim(v2))
  return v1.enumerate().fold(0, (s, t) => s + t.at(1) * v2.at(t.at(0)))
}

/// Calculate cross product of two vectors of dim 3
#let cross(v1, v2) = {
  assert(dim(v1) == 3 and dim(v2) == 3)
  let x = v1.at(1) * v2.at(2) - v1.at(2) * v1.at(1)
  let y = v1.at(2) * v2.at(0) - v1.at(0) * v1.at(2)
  let z = v1.at(0) * v2.at(1) - v1.at(1) * v1.at(0)
  return (x, y, z)
}

/// Calculate angle between two vectors of dim 2 or dim 3
#let angle(v1, v2) = {
  assert(dim(v1) == dim(v2))
  if dim(v1) == 2 {
    let n = calc.max(-1, calc.min(1, (dot(v1, v2) / (len(v1) * len(v2)))))
    // FIXME: Bug
    return calc.acos(n)
  } else if dim(v1) == 3 {
    panic("TODO")
    //return calc.asin(cross(v1, v2) / (len(v1) * len(v2)))
  } else {
    panic("Invalid vector dimension")
  }
}

/// Convert vector `v` to row or column matrix
#let as-mat(v, mode: "row") = {
  if mode == "column" {
    return (v,)
  } else if mode == "row" {
    return (for c in v { (c,) }, )
  } else {
    panic("Invalid mode " + mode)
  }
}

/// Convert vector to vector of different dimension
/// with missing fields of `v` set to fields of vector `init`
#let as-vec(v, init: (0, 0, 0, 1)) = {
  for i in range(0, calc.min(dim(v), dim(init))) {
    init.at(i) = v.at(i)
  }
  return init
}
