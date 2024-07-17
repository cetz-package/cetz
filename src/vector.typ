/// Returns a new vector of dimension `dim` with all fields set to `init` (defaults to 0).
///
/// - dim (int): Vector dimension
/// - init (float): Initial value of all fields
/// -> vector
#let new(dim, init: 0) = {
  return range(0, dim).map(x => init)
}

/// Returns the dimension of a vector. 
///
/// - v (vector): The vector to find the dimension of.
/// -> int
#let dim(v) = {
  assert(
    type(v) == array,
    message: "Expected vector to be of array type, got: " + repr(v)
  )
  return v.len() 
}


/// Converts a vector to a row or column matrix.
///
/// - v (vector): The vector to convert.
/// - mode (str): The type of matrix to convert into. Must be one of `"row"` or `"column"`.
/// -> matrix
#let as-mat(v, mode: "row") = {
  if mode == "column" {
    return (v,)
  } else if mode == "row" {
    return (for c in v { (c,) }, )
  } else {
    panic("Invalid mode " + mode)
  }
}

/// Ensures a vector has an exact dimension. This is done by passing another vector `init` that has the required dimension. If the original vector does not have enough dimensions, the values from `init` will be inserted. It is recommended to use a zero vector for `init`.
///
/// - v (vector): The vector to ensure.
/// - init (vector): The vector to check the dimension against.
/// -> vector
#let as-vec(v, init: (0, 0, 0)) = {
  for i in range(0, calc.min(dim(v), dim(init))) {
    init.at(i) = v.at(i)
  }
  return init
}


/// Return length/magnitude of a vector.
///
/// - v (vector): The vector to find the magnitude of.
/// -> float
#let len(v) = {
  return calc.sqrt(v.fold(0, (s, c) => s + c * c))
}

/// Adds two vectors of the same dimension
///
/// - v1 (vector): The vector on the left hand side.
/// - v2 (vector): The vector on the right hand side.
/// -> vector
#let add(v1, v2) = {
  if dim(v1) != dim(v2) {
    v1 = as-vec(v1)
    v2 = as-vec(v2)
  }
  assert(dim(v1) == dim(v2), message: "Cannot add vectors, " + repr(v1) + " and " + repr(v2) + " are not of the same dimensions.")
  return v1.zip(v2).map(((a, b)) => a + b)
}

/// Subtracts two vectors of the same dimension
///
/// - v1 (vector): The vector on the left hand side.
/// - v2 (vector): The vector on the right hand side.
/// -> vector
#let sub(v1, v2) = {
  if dim(v1) != dim(v2) {
    v1 = as-vec(v1)
    v2 = as-vec(v2)
  }
  assert(dim(v1) == dim(v2), message: "Cannot subtract vectors, " + repr(v1) + " and " + repr(v2) + " are not of the same dimensions.")
  return v1.zip(v2).map(((a, b)) => a - b)
}

/// Calculates the distance between two vectors by subtracting the length of vector `a` from vector `b`.
///
/// - a (vector): Vector a
/// - b (vector): Vector b
/// -> float
#let dist(a, b) = len(sub(b, a))

/// Multiplys a vector with scalar `x`
/// - v (vector): The vector to scale.
/// - x (float): The scale factor.
/// -> vector
#let scale(v, x) = v.map(s => s * x)

/// Divides a vector by scalar `x`
/// - v (vector): The vector to be divded.
/// - x (float): The inverse scale factor.
#let div(v, x) = v.map(s => s / x)

/// Negates each value in a vector
/// - v (vector): The vector to negate.
/// -> vector
#let neg(v) = scale(v, -1)

/// Normalizes a vector (divide by its length)
/// - v (vector): The vector to normalize.
/// -> vector
#let norm(v) = div(v, len(v))

/// Calculates the dot product between two vectors.
/// - v1 (vector): The vector on the left hand side.
/// - v2 (vector): The vector on the right hand side.
/// -> float
#let dot(v1, v2) = {
  assert(dim(v1) == dim(v2))
  return v1.enumerate().fold(0, (s, t) => s + t.at(1) * v2.at(t.at(0)))
}

/// Calculates the cross product of two vectors with a dimension of three.
/// - v1 (vector): The vector on the left hand side.
/// - v2 (vector): The vector on the right hand side.
/// -> vector
#let cross(v1, v2) = {
  assert(dim(v1) == 3 and dim(v2) == 3)
  let x = v1.at(1) * v2.at(2) - v1.at(2) * v2.at(1)
  let y = v1.at(2) * v2.at(0) - v1.at(0) * v2.at(2)
  let z = v1.at(0) * v2.at(1) - v1.at(1) * v2.at(0)
  return (x, y, z)
}

/// Calculates the angle between two vectors and the x-axis in 2d space
/// - a (vector): The vector to measure the angle from.
/// - b (vector): The vector to measure the angle to.
/// -> angle
#let angle2(a, b) = {
  // Typst's atan2 is (x, y) order, not (y, x)
  return calc.atan2(b.at(0) - a.at(0), b.at(1) - a.at(1))
}

/// Calculates the angle between three vectors
/// - v1 (vector): The vector to measure the angle from.
/// - c (vector): The vector to measure the angle at.
/// - v2 (vector): The vector to measure the angle to.
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

/// Linear interpolation between two vectors.
/// - v1 (vector): The vector to interpolate from.
/// - v2 (vector): The vector to interpolate to.
/// - t (float): The factor to interpolate by. A value of `0` is `v1` and a value of `1` is `v2`.
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

/// Rotates a vector of dimension 2 or 3 around the z-axis by an angle.
/// - v (vector): The vector to rotate.
/// - angle (angle): The angle to rotate by.
/// -> vector
#let rotate-z(v, angle) = {
  assert(v.len() >= 2,
    message: "Vector size must be >= 2")
  let (x, y, ..) = v
  v.at(0) = x * calc.cos(angle) - y * calc.sin(angle)
  v.at(1) = x * calc.sin(angle) + y * calc.cos(angle)
  return v
}