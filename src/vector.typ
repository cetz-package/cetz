/// Converts a vector to a row or column matrix.
///
/// - v (vector): The vector to convert.
/// - mode (str): The type of matrix to convert into. Must be one of `"row"` or `"column"`.
/// -> matrix
#let as-mat(v, mode: "row") = {
  if mode == "column" {
    return (v,)
  } else if mode == "row" {
    return (for c in v { (c,) },)
  } else {
    panic("Invalid mode " + mode)
  }
}

/// Ensures a vector has an exact number of components. This is done by passing another vector `init` that has the required dimension. If the original vector does not have enough dimensions, the values from `init` will be inserted. It is recommended to use a zero vector for `init`.
///
/// - v (vector): The vector to ensure.
/// - init (vector): The vector to check the dimension against.
/// -> vector
#let as-vec(v, init: (0, 0, 0)) = {
  let l = init.len()
  if l == 2 {
    return (v.at(0, default: init.at(0)), v.at(1, default: init.at(1)))
  } else if l == 3 {
    return (
      v.at(0, default: init.at(0)),
      v.at(1, default: init.at(1)),
      v.at(2, default: init.at(2)),
    )
  } else if l == 4 {
    return (
      v.at(0, default: init.at(0)),
      v.at(1, default: init.at(1)),
      v.at(2, default: init.at(2)),
      v.at(3, default: init.at(3)),
    )
  }
  let limit = calc.min(v.len(), l)
  for i in range(0, limit) {
    init.at(i) = v.at(i)
  }
  init
}


/// Return length/magnitude of a vector.
///
/// - v (vector): The vector to find the magnitude of.
/// -> float
#let len(v) = {
  let l = v.len()
  if l == 2 {
    let x = v.at(0)
    let y = v.at(1)
    return calc.sqrt(x * x + y * y)
  } else if l == 3 {
    let x = v.at(0)
    let y = v.at(1)
    let z = v.at(2)
    return calc.sqrt(x * x + y * y + z * z)
  }
  calc.sqrt(v.fold(0, (s, c) => s + c * c))
}

/// Adds two vectors of the same dimension
///
/// - v1 (vector): The vector on the left hand side.
/// - v2 (vector): The vector on the right hand side.
/// -> vector
#let add(v1, v2) = {
  let l1 = v1.len()
  let l2 = v2.len()
  let l = calc.max(l1, l2)
  if l == 2 {
    return (
      v1.at(0, default: 0) + v2.at(0, default: 0),
      v1.at(1, default: 0) + v2.at(1, default: 0),
    )
  } else if l == 3 {
    return (
      v1.at(0, default: 0) + v2.at(0, default: 0),
      v1.at(1, default: 0) + v2.at(1, default: 0),
      v1.at(2, default: 0) + v2.at(2, default: 0),
    )
  }
  range(0, l).map(i => v1.at(i, default: 0) + v2.at(i, default: 0))
}

/// Subtracts two vectors of the same dimension
///
/// - v1 (vector): The vector on the left hand side.
/// - v2 (vector): The vector on the right hand side.
/// -> vector
#let sub(v1, v2) = {
  let l1 = v1.len()
  let l2 = v2.len()
  let l = calc.max(l1, l2)
  if l == 2 {
    return (
      v1.at(0, default: 0) - v2.at(0, default: 0),
      v1.at(1, default: 0) - v2.at(1, default: 0),
    )
  } else if l == 3 {
    return (
      v1.at(0, default: 0) - v2.at(0, default: 0),
      v1.at(1, default: 0) - v2.at(1, default: 0),
      v1.at(2, default: 0) - v2.at(2, default: 0),
    )
  }
  range(0, l).map(i => v1.at(i, default: 0) - v2.at(i, default: 0))
}

/// Calculates the distance between two vectors by subtracting the length of vector `a` from vector `b`.
///
/// - a (vector): Vector a
/// - b (vector): Vector b
/// -> float
#let dist(a, b) = {
  let l = calc.max(a.len(), b.len())
  if l == 2 {
    let dx = b.at(0, default: 0) - a.at(0, default: 0)
    let dy = b.at(1, default: 0) - a.at(1, default: 0)
    return calc.sqrt(dx * dx + dy * dy)
  } else if l == 3 {
    let dx = b.at(0, default: 0) - a.at(0, default: 0)
    let dy = b.at(1, default: 0) - a.at(1, default: 0)
    let dz = b.at(2, default: 0) - a.at(2, default: 0)
    return calc.sqrt(dx * dx + dy * dy + dz * dz)
  }
  len(sub(b, a))
}

/// Multiplys a vector with scalar `x`
/// - v (vector): The vector to scale.
/// - x (float): The scale factor.
/// -> vector
#let scale(v, x) = {
  let l = v.len()
  if l == 2 {
    return (v.at(0) * x, v.at(1) * x)
  } else if l == 3 {
    return (v.at(0) * x, v.at(1) * x, v.at(2) * x)
  }
  v.map(s => s * x)
}

/// Divides a vector by scalar `x`
/// - v (vector): The vector to be divded.
/// - x (float): The inverse scale factor.
#let div(v, x) = {
  let inv = 1 / x
  let l = v.len()
  if l == 2 {
    return (v.at(0) * inv, v.at(1) * inv)
  } else if l == 3 {
    return (v.at(0) * inv, v.at(1) * inv, v.at(2) * inv)
  }
  v.map(s => s * inv)
}

/// Negates each value in a vector
/// - v (vector): The vector to negate.
/// -> vector
#let neg(v) = scale(v, -1)

/// Normalizes a vector (divide by its length)
/// - v (vector): The vector to normalize.
/// -> vector
#let norm(v) = {
  let l = v.len()
  if l == 2 {
    let x = v.at(0)
    let y = v.at(1)
    let inv = 1 / calc.sqrt(x * x + y * y)
    return (x * inv, y * inv)
  } else if l == 3 {
    let x = v.at(0)
    let y = v.at(1)
    let z = v.at(2)
    let inv = 1 / calc.sqrt(x * x + y * y + z * z)
    return (x * inv, y * inv, z * inv)
  }
  div(v, len(v))
}

/// Multiply two vectors component-wise
/// - a (vector): First vector.
/// - b (vector): Second vector.
#let element-product(a, b) = {
  let l = a.len()
  range(l).map(i => a.at(i) * b.at(i))
}

/// Calculates the dot product between two vectors.
/// - v1 (vector): The vector on the left hand side.
/// - v2 (vector): The vector on the right hand side.
/// -> float
#let dot(v1, v2) = {
  let l = v1.len()
  assert(l == v2.len())
  if l == 2 {
    return v1.at(0) * v2.at(0) + v1.at(1) * v2.at(1)
  } else if l == 3 {
    return v1.at(0) * v2.at(0) + v1.at(1) * v2.at(1) + v1.at(2) * v2.at(2)
  }
  range(l).fold(0, (s, i) => s + v1.at(i) * v2.at(i))
}

/// Calculates the cross product of two vectors with a dimension of three.
/// - v1 (vector): The vector on the left hand side.
/// - v2 (vector): The vector on the right hand side.
/// -> vector
#let cross(v1, v2) = {
  assert(v1.len() == 3 and v2.len() == 3)

  let (x1, y1, z1) = v1
  let (x2, y2, z2) = v2

  return (y1 * z2 - z1 * y2, z1 * x2 - x1 * z2, x1 * y2 - y1 * x2)
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
  assert(
    v1.len() == v2.len(),
    message: "Vectors " + repr(v1) + " and " + repr(v2) + " do not have the same dimensions.",
  )
  if v1.len() == 2 or v1.len() == 3 {
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
  let l1 = v1.len()
  let l2 = v2.len()
  let l = if l1 > l2 { l1 } else { l2 }
  if l == 2 {
    let a0 = v1.at(0, default: 0)
    let a1 = v1.at(1, default: 0)
    let b0 = v2.at(0, default: 0)
    let b1 = v2.at(1, default: 0)
    return (a0 + (b0 - a0) * t, a1 + (b1 - a1) * t)
  } else if l == 3 {
    let a0 = v1.at(0, default: 0)
    let a1 = v1.at(1, default: 0)
    let a2 = v1.at(2, default: 0)
    let b0 = v2.at(0, default: 0)
    let b1 = v2.at(1, default: 0)
    let b2 = v2.at(2, default: 0)
    return (
      a0 + (b0 - a0) * t,
      a1 + (b1 - a1) * t,
      a2 + (b2 - a2) * t,
    )
  }
  range(0, l).map(i => {
    let a = v1.at(i, default: 0)
    let b = v2.at(i, default: 0)
    a + (b - a) * t
  })
}

/// Rotates a vector of dimension 2 or 3 around the z-axis by an angle.
/// - v (vector): The vector to rotate.
/// - angle (angle): The angle to rotate by.
/// -> vector
#let rotate-z(v, angle) = {
  assert(v.len() >= 2, message: "Vector size must be >= 2")
  let (x, y, ..) = v
  let c = calc.cos(angle)
  let s = calc.sin(angle)
  v.at(0) = x * c - y * s
  v.at(1) = x * s + y * c
  return v
}
