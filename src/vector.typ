/// Return a new vector of dimension `dim` with all fields
/// set to `init` (defaults to 0).
#let new(dim, init: 0) = {
  return range(0, dim).map(x => init)
}

/// Return dimension of vector v
#let dim(v) = { assert(type(v) == "array", message: "Expected vector to be of array type, got: " + repr(v)); return v.len() }


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
#let as-vec(v, init: (0, 0, 0)) = {
  for i in range(0, calc.min(dim(v), dim(init))) {
    init.at(i) = v.at(i)
  }
  return init
}


/// Return length of vector v
#let len(v) = {
  return calc.sqrt(v.fold(0, (s, c) => s + c * c))
}

/// Add two vectors of the same dimension
#let add(v1, v2) = {
  if dim(v1) != dim(v2) {
    v1 = as-vec(v1)
    v2 = as-vec(v2)
  }
  assert(dim(v1) == dim(v2), message: "Cannot add vectors, " + repr(v1) + " and " + repr(v2) + " are not of the same dimensions.")
  return v1.zip(v2).map(((a, b)) => a + b)
}

/// Subtract two vectors of the same dimension
#let sub(v1, v2) = {
  if dim(v1) != dim(v2) {
    v1 = as-vec(v1)
    v2 = as-vec(v2)
  }
  assert(dim(v1) == dim(v2), message: "Cannot subtract vectors, " + repr(v1) + " and " + repr(v2) + " are not of the same dimensions.")
  return v1.zip(v2).map(((a, b)) => a - b)
}

/// Return distance of vector a and b
/// - a (vector): Vector a
/// - b (vector): Vector b
#let dist(a, b) = len(sub(b, a))

/// Multiply each vector field with number `x`
#let scale(v, x) = v.map(s => s * x)

/// Divide each vector field by number `x`
#let div(v, x) = v.map(s => s / x)

/// Negate each vector field
#let neg(v) = scale(v, -1)

/// Normalize vector (divide by its length)
#let norm(v) = div(v, len(v))

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

/// Calculate angle between two points and the x-axis in 2d space
#let angle2(a, b) = {
  return calc.atan2(a.at(1) - b.at(1), a.at(0) - b.at(0)) + 90deg
}

/// Calculate angle between three points 
#let angle(v1, c, v2) = {
  assert(dim(v1) == dim(v2), message: "Vectors " + repr(v1) + " and " + repr(v2) + " do not have the same dimensions.")
  if dim(v1) == 2 or dim(v1) == 3 {
    v1 = sub(v1, c)
    v2 = sub(v2, c)
    return calc.acos(dot(norm(v1), norm(v2)))
  } else {
    panic("Invalid vector dimension")
  }
}

/// Linear interpolation
#let lerp(v1, v2, t) = {
  return add(
    v1,
    scale(
      sub(
        v2,
        v1
      ),
      t,
    )
  )
}
