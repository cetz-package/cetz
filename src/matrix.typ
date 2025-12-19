#import "vector.typ"
#import "wasm.typ": call_wasm
#let cetz-core = plugin("../cetz-core/cetz_core.wasm")

// Global rounding precision
#let precision = 8

#let _round = calc.round.with(digits: precision)

#let cos(x) = {
  _round(calc.cos(x))
}

#let sin(x) = {
  _round(calc.sin(x))
}

#let pi = calc.pi

// List of identity matrices of dimension 1 x 1 to 4 x 4
#let _ident = (
  ((1.0),),
  ((1.0, 0.0), (0.0, 1.0)),
  ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0)),
  ((1.0, 0.0, 0.0, 0.0), (0.0, 1.0, 0.0, 0.0), (0.0, 0.0, 1.0, 0.0), (0.0, 0.0, 0.0, 1.0)),
)

/// Create a (square) identity matrix with dimensions $"size" times "size"$
///
/// - size (int): Size of the matrix
/// -> matrix
#let ident(size) = {
  assert(size >= 1, message: "Invalid dimension")
  return _ident.at(size - 1, default:
    range(0, size).map(j => range(0, size).map(k => {
      if j == k { 1.0 } else { 0.0 }
    })))
}

/// Create a square matrix with the diagonal set to the
/// given values
///
/// - ..diag (float): Diagonal values
/// -> matrix
#let diag(..diag) = {
  assert(diag.pos().len() >= 1, message: "Invalid dimension")
  assert.eq(diag.named(), (), messaged: "Unexpected named argument")

  let diag = diag.pos()
  range(0, diag.len()).map(m => range(0, diag.len()).map(n => {
    if n == m { diag.at(m) } else { 0.0 }
  }))
}

/// Returns the dimension of the given matrix as `(m, n)`
/// - m (matrix): The matrix
/// -> array
#let dim(m) = {
  return (m.len(), if m.len() > 0 { m.at(0).len() } else { 0 })
}

/// Returns the n-th column of a matrix as a {{vector}}
/// - mat (matrix): Input matrix
/// - n (int): The column's index
/// -> vector
#let column(mat, n) = {
  range(0, mat.len()).map(m => mat.at(m).at(n))
}

/// Rounds each value in the matrix to a precision.
/// - mat (matrix): Input matrix
/// - precision (int) = 8: Rounding precision (digits)
/// -> matrix
#let round(mat, precision: precision) = {
  mat.map(r => r.map(v => _round(v, digits: precision)))
}

/// Returns a $4 times 4$ translation matrix
/// - x (float): The translation in the $x$ direction.
/// - y (float): The translation in the $y$ direction.
/// - z (float): The translation in the $x$ direction.
/// -> matrix
#let transform-translate(x, y, z) = {
  ((1, 0, 0, x), (0, 1, 0, y), (0, 0, 1, z), (0, 0, 0, 1))
}

/// Returns a $4 times 4$ x-shear matrix
/// - factor (float): The shear in the $x$ direction.
/// -> matrix
#let transform-shear-x(factor) = {
  ((1, factor, 0, 0), (0, 1, 0, 0), (0, 0, 1, 0), (0, 0, 0, 1))
}


/// Returns a $4 times 4$ z-shear matrix
/// - factor (float): The shear in the $z$ direction.
/// -> matrix
#let transform-shear-z(factor) = {
  ((1, 0, factor, 0), (0, 1, -factor, 0), (0, 0, 1, 0), (0, 0, 0, 1))
}

/// Returns a $4 times 4$ scale matrix
/// - f (float,array,dictionary): The scale factor(s) of the matrix. An {{array}} of at least 3 {{float}}s sets the x, y and z scale factors. A {{dictionary}} sets the scale in the direction of the corresponding x, y and z keys. A single {{float}} sets the scale for all directions.
/// -> matrix
#let transform-scale(f) = {
  let (x, y, z) = if type(f) == array {
    vector.as-vec(f, init: (1, 1, 1))
  } else if type(f) == dictionary {
    (f.at("x", default: 1), f.at("y", default: 1), f.at("z", default: 1))
  } else {
    (f, f, f)
  }
  return (
    (x, 0, 0, 0),
    (0, y, 0, 0),
    (0, 0, z, 0),
    (0, 0, 0, 1),
  )
}

/// Returns a $4 times 4$ rotation xyz matrix for a direction and up vector
/// - dir (vector): idk
/// - up (vector): idk
/// -> matrix
#let transform-rotate-dir(dir, up) = {
  dir = vector.norm(dir.slice(0, 3))
  up = vector.norm(up.slice(0, 3))

  let (dx, dy, dz) = dir
  let (ux, uy, uz) = up
  let (rx, ry, rz) = vector.norm(vector.cross(dir, up))

  ((rx, dx, ux, 0), (ry, dy, uy, 0), (rz, dz, uz, 0), (0, 0, 0, 1))
}

// Return 4x4 rotate x matrix
/// Returns a $4 times 4$ $x$ rotation matrix
/// - angle (angle): The angle to rotate around the $x$ axis
/// -> matrix
#let transform-rotate-x(angle) = {
  ((1, 0, 0, 0), (0, cos(angle), -sin(angle), 0), (0, sin(angle), cos(angle), 0), (0, 0, 0, 1))
}

// Return 4x4 rotate y matrix
/// Returns a $4 times 4$ $y$ rotation matrix
/// - angle (angle): The angle to rotate around the $y$ axis
/// -> matrix
#let transform-rotate-y(angle) = {
  ((cos(angle), 0, -sin(angle), 0), (0, 1, 0, 0), (sin(angle), 0, cos(angle), 0), (0, 0, 0, 1))
}

// Return 4x4 rotate z matrix
/// Returns a $4 times 4$ $z$ rotation matrix
/// - angle (angle): The angle to rotate around the $z$ axis
/// -> matrix
#let transform-rotate-z(angle) = {
  ((cos(angle), -sin(angle), 0, 0), (sin(angle), cos(angle), 0, 0), (0, 0, 1, 0), (0, 0, 0, 1))
}

// Return 4x4 rotate xz matrix
/// Returns a $4 times 4$ $x z$ rotation matrix
/// - x (angle): The angle to rotate around the $x$ axis
/// - z (angle): The angle to rotate around the $z$ axis
/// -> matrix
#let transform-rotate-xz(x, z) = {
  (
    (cos(z), sin(z), 0, 0),
    (-cos(x) * sin(z), cos(x) * cos(z), -sin(x), 0),
    (sin(x) * sin(z), -sin(x) * cos(z), cos(x), 1),
    (0, 0, 0, 1),
  )
}

/// Returns a $4 times 4$ rotation matrix - yaw-pitch-roll
///
/// - a (angle): Yaw
/// - b (angle): Pitch
/// - c (angle): Roll
/// -> matrix
#let transform-rotate-ypr(a, b, c) = {
  (
    (cos(a) * cos(b), cos(a) * sin(b) * sin(c) - sin(a) * cos(c), cos(a) * sin(b) * cos(c) + sin(a) * sin(c), 0),
    (sin(a) * cos(b), sin(a) * sin(b) * sin(c) + cos(a) * cos(c), sin(a) * sin(b) * cos(c) - cos(a) * sin(c), 0),
    (-sin(b), cos(b) * sin(c), cos(b) * cos(c), 1),
    (0, 0, 0, 1),
  )
}

/// Returns a $4 times 4$ rotation matrix - euler angles
///
/// Calculates the product of the three rotation matrices
/// $R = R_z(z) R_y(y) R_x(x)$
///
/// - x (angle): Rotation about x
/// - y (angle): Rotation about y
/// - z (angle): Rotation about z
/// -> matrix
#let transform-rotate-xyz(x, y, z) = {
  (
    (cos(y) * cos(z), sin(x) * sin(y) * cos(z) - cos(x) * sin(z), cos(x) * sin(y) * cos(z) + sin(x) * sin(z), 0),
    (cos(y) * sin(z), sin(x) * sin(y) * sin(z) + cos(x) * cos(z), cos(x) * sin(y) * sin(z) - sin(x) * cos(z), 0),
    (-sin(y), sin(x) * cos(y), cos(x) * cos(y), 0),
    (0, 0, 0, 1),
  )
}

/// Multiplies matrices on top of each other.
/// - ..matrices (matrix): The matrices to multiply from left to right.
/// -> matrix
#let mul-mat(..matrices) = {
  matrices = matrices.pos()
  let out = matrices.first()
  for i in range(1, matrices.len()) {
    let matrix = matrices.at(i)

    // Short circuit multiplication with the neutral element
    if out in _ident {
      out = matrix
      continue
    } else if matrix in _ident {
      continue
    }

    let m = out.len()
    let n = out.at(0).len()
    let p = matrix.at(0).len()
    if m == 4 and n == 4 and matrix.len() == 4 and p == 4 {
      let ((a1, a2, a3, a4), (a5, a6, a7, a8), (a9, a10, a11, a12), (a13, a14, a15, a16)) = out
      let ((b1, b2, b3, b4), (b5, b6, b7, b8), (b9, b10, b11, b12), (b13, b14, b15, b16)) = matrix
      out = (
        (
          _round(a1 * b1 + a2 * b5 + a3 * b9 + a4 * b13),
          _round(a1 * b2 + a2 * b6 + a3 * b10 + a4 * b14),
          _round(a1 * b3 + a2 * b7 + a3 * b11 + a4 * b15),
          _round(a1 * b4 + a2 * b8 + a3 * b12 + a4 * b16),
        ),
        (
          _round(a5 * b1 + a6 * b5 + a7 * b9 + a8 * b13),
          _round(a5 * b2 + a6 * b6 + a7 * b10 + a8 * b14),
          _round(a5 * b3 + a6 * b7 + a7 * b11 + a8 * b15),
          _round(a5 * b4 + a6 * b8 + a7 * b12 + a8 * b16),
        ),
        (
          _round(a9 * b1 + a10 * b5 + a11 * b9 + a12 * b13),
          _round(a9 * b2 + a10 * b6 + a11 * b10 + a12 * b14),
          _round(a9 * b3 + a10 * b7 + a11 * b11 + a12 * b15),
          _round(a9 * b4 + a10 * b8 + a11 * b12 + a12 * b16),
        ),
        (
          _round(a13 * b1 + a14 * b5 + a15 * b9 + a16 * b13),
          _round(a13 * b2 + a14 * b6 + a15 * b10 + a16 * b14),
          _round(a13 * b3 + a14 * b7 + a15 * b11 + a16 * b15),
          _round(a13 * b4 + a14 * b8 + a15 * b12 + a16 * b16),
        ),
      )
    } else {
      out = (
        for i in range(m) {
          (
            for j in range(p) {
              let sum = 0
              for k in range(n) {
                sum += out.at(i).at(k) * matrix.at(k).at(j)
              }
              (_round(sum),)
            },
          )
        }
      )
    }
  }
  return out
}

// Multiply 4x4 matrix with vector of size 3 or 4.
// The value of vec_4 defaults to w (1).
//
// The resulting vector is of dimension 3
/// Multiplies a $4 times 4$ matrix with a vector of size 3 or 4. The resulting is three dimensional
/// - mat (matrix): The matrix to multiply
/// - vec (vector): The vector to multiply
/// - w (float): The default value for the fourth element of the vector if it is three dimensional.
/// -> vector
#let mul4x4-vec3(mat, vec, w: 1.0) = {
  assert(vec.len() <= 4)

  // Short circuit the neutral element
  if mat == _ident.at(3) {
    return (if vec.len() == 2 {
      (..vec, 0.0)
    } else {
      vec
    }).map(float)
  }

  let x = vec.at(0)
  let y = vec.at(1)
  let z = vec.at(2, default: 0)
  let w = vec.at(3, default: w)

  let ((a1, a2, a3, a4), (b1, b2, b3, b4), (c1, c2, c3, c4), _) = mat
  return (
    a1 * x + a2 * y + a3 * z + a4 * w,
    b1 * x + b2 * y + b3 * z + b4 * w,
    c1 * x + c2 * y + c3 * z + c4 * w,
  )
}

// Multiply matrix with vector
/// Multiplies an $m times n$ matrix with an $m$th dimensional vector where $m <= 4$. Prefer the use of `mul4x4-vec3` when possible as it does not use loops.
/// - mat (matrix): The matrix to multiply
/// - vec (vector): The vector to multiply
/// -> vector
#let mul-vec(mat, vec) = {
  let m = mat.len()
  let n = mat.at(0).len()
  assert(n == vec.len(), message: "Matrix columns must be equal to vector rows")
  if m == 2 and n == 2 {
    let ((a1, a2), (b1, b2)) = mat
    let x = vec.at(0)
    let y = vec.at(1)
    return (a1 * x + a2 * y, b1 * x + b2 * y)
  } else if m == 3 and n == 3 {
    let ((a1, a2, a3), (b1, b2, b3), (c1, c2, c3)) = mat
    let x = vec.at(0)
    let y = vec.at(1)
    let z = vec.at(2)
    return (
      a1 * x + a2 * y + a3 * z,
      b1 * x + b2 * y + b3 * z,
      c1 * x + c2 * y + c3 * z,
    )
  } else if m == 4 and n == 4 {
    let ((a1, a2, a3, a4), (b1, b2, b3, b4), (c1, c2, c3, c4), (d1, d2, d3, d4)) = mat
    let x = vec.at(0)
    let y = vec.at(1)
    let z = vec.at(2)
    let w = vec.at(3)
    return (
      a1 * x + a2 * y + a3 * z + a4 * w,
      b1 * x + b2 * y + b3 * z + b4 * w,
      c1 * x + c2 * y + c3 * z + c4 * w,
      d1 * x + d2 * y + d3 * z + d4 * w,
    )
  }

  // Short circuit the neutral element
  if mat in _ident { return vec }

  let new = (0,) * m
  for i in range(0, m) {
    let row = mat.at(i)
    let acc = 0
    for j in range(0, n) {
      acc += row.at(j) * vec.at(j)
    }
    new.at(i) = acc
  }
  return new
}

/// Calculates the inverse matrix of any size.
/// - matrix (matrix): The matrix to inverse.
/// -> matrix
#let inverse(matrix) = {
  // The identity is self inverse
  if matrix in _ident {
    return matrix
  }

  let n = {
    let size = dim(matrix)
    assert.eq(size.first(), size.last(), message: "Matrix must be square to perform inversion.")
    size.first()
  }

  let N = range(n)
  let inverted = ident(n)
  let p
  for j in N {
    for i in range(j, n) {
      if matrix.at(i).at(j) != 0 {
        (matrix.at(j), matrix.at(i)) = (matrix.at(i), matrix.at(j))
        (inverted.at(j), inverted.at(i)) = (inverted.at(i), inverted.at(j))

        p = 1 / matrix.at(j).at(j)
        for k in N {
          matrix.at(j).at(k) *= p
          inverted.at(j).at(k) *= p
        }

        for L in N {
          if L != j {
            p = -matrix.at(L).at(j)
            for k in N {
              matrix.at(L).at(k) += _round(p * matrix.at(j).at(k))
              inverted.at(L).at(k) += _round(p * inverted.at(j).at(k))
            }
          }
        }
      }
    }
  }

  return inverted
}
