#import "vector.typ"

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

/// Create identity matrix with dimensions $m \times n$
///
/// - m (int): The number of rows
/// - n (int): The number of columns
/// - one (float): Value to set as $1$
/// - zero (float): Value to set as $0$
/// -> matrix
#let ident(m: 4, n: 4, one: 1, zero: 0) = {
  ({for m in range(0, m) {
    ({for n in range(0, n) {
        if m == n { (one,) } else { (zero,) }
     }},)
    }})
}

/// Returns the dimension of the given matrix as `(m, n)`
/// - m (matrix): The matrix
/// -> array
#let dim(m) = {
  return (m.len(), if m.len() > 0 {m.at(0).len()} else {0})
}

/// Returns the nth column of a matrix as a {{vector}}
/// - mat (matrix): Input matrix
/// - n (int): The column's index
/// -> vector
#let column(mat, n) = {
  range(0, mat.len()).map(m => mat.at(m).at(n))
}

/// Replaces the nth column of a matrix with the given vector.
/// - mat (matrix): Input matrix.
/// - n (int): The index of the column to replace
/// - vec (vector): The column data to insert.
/// -> matrix
#let set-column(mat, n, vec) = {
  assert(vec.len() == matrix.len())
  for m in range(0, mat.len()) {
    mat.at(m).at(n) = vec.at(n)
  }
}

/// Rounds each value in the matrix to a precision.
/// - mat (matrix): Input matrix
/// - precision (int) = 8: Rounding precision (digits)
/// -> matrix
#let round(mat, precision: precision) = {
  mat.map(r => r.map(v => _round(v, digits: precision)))
}

/// Returns a $4 \times 4$ translation matrix
/// - x (float): The translation in the $x$ direction.
/// - y (float): The translation in the $y$ direction.
/// - z (float): The translation in the $x$ direction.
/// -> matrix
#let transform-translate(x, y, z) = {
  ((1, 0, 0, x),
   (0, 1, 0, y),
   (0, 0, 1, z),
   (0, 0, 0, 1))
}

/// Returns a $4 \times 4$ x-shear matrix
/// - factor (float): The shear in the $x$ direction.
/// -> matrix
#let transform-shear-x(factor) = {
  ((1, factor, 0, 0),
   (0, 1, 0, 0),
   (0, 0, 1, 0),
   (0, 0, 0, 1))
}


/// Returns a $4 \times 4$ z-shear matrix
/// - factor (float): The shear in the $z$ direction.
/// -> matrix
#let transform-shear-z(factor) = {
  ((1, 0, factor, 0),
   (0, 1,-factor, 0),
   (0, 0, 1, 0),
   (0, 0, 0, 1))
}

/// Returns a $4 \times 4$ scale matrix
/// - f (float,array,dictionary): The scale factor(s) of the matrix. An {{array}} of at least 3 {{float}}s sets the x, y and z scale factors. A {{dictionary}} sets the scale in the direction of the corresponding x, y and z keys. A single {{float}} sets the scale for all directions.
/// -> matrix
#let transform-scale(f) = {
  let (x, y, z) = if type(f) == array {
    vector.as-vec(f, init: (1, 1, 1))
  } else if type(f) == dictionary {
    (f.at("x", default: 1),
     f.at("y", default: 1),
     f.at("z", default: 1))
  } else {
    (f, f, f)
  }
  return(
   (x, 0, 0, 0),
   (0, y, 0, 0),
   (0, 0, z, 0),
   (0, 0, 0, 1))
}

/// Returns a $4 \times 4$ rotation xyz matrix for a direction and up vector
/// - dir (vector): idk
/// - up (vector): idk
/// -> matrix
#let transform-rotate-dir(dir, up) = {
  dir = vector.norm(dir)
  up = vector.norm(up)

  let (dx, dy, dz) = dir
  let (ux, uy, uz) = up
  let (rx, ry, rz) = vector.norm(vector.cross(dir, up))

  ((rx, dx, ux, 0),
   (ry, dy, uy, 0),
   (rz, dz, uz, 0),
   (0,   0,  0, 1))
}

// Return 4x4 rotate x matrix
/// Returns a $4 \times 4$ $x$ rotation matrix
/// - angle (angle): The angle to rotate around the $x$ axis
/// -> matrix
#let transform-rotate-x(angle) = {
  ((1, 0, 0, 0),
   (0, cos(angle), -sin(angle), 0),
   (0, sin(angle), cos(angle), 0),
   (0, 0, 0, 1))
}

// Return 4x4 rotate y matrix
/// Returns a $4 \times 4$ $y$ rotation matrix
/// - angle (angle): The angle to rotate around the $y$ axis
/// -> matrix
#let transform-rotate-y(angle) = {
  ((cos(angle), 0, -sin(angle), 0),
   (0, 1, 0, 0),
   (sin(angle), 0, cos(angle), 0),
   (0, 0, 0, 1))
}

// Return 4x4 rotate z matrix
/// Returns a $4 \times 4$ $z$ rotation matrix
/// - angle (angle): The angle to rotate around the $z$ axis
/// -> matrix
#let transform-rotate-z(angle) = {
  ((cos(angle), -sin(angle), 0, 0),
   (sin(angle), cos(angle), 0, 0),
   (0, 0, 1, 0),
   (0, 0, 0, 1))
}

// Return 4x4 rotate xz matrix
/// Returns a $4 \times 4$ $x z$ rotation matrix
/// - x (angle): The angle to rotate around the $x$ axis
/// - z (angle): The angle to rotate around the $z$ axis
/// -> matrix
#let transform-rotate-xz(x, z) = {
  ((cos(z), sin(z), 0, 0),
   (-cos(x)*sin(z), cos(x)*cos(z), -sin(x), 0),
   (sin(x)*sin(z), -sin(x)*cos(z), cos(x), 1),
   (0, 0, 0, 1))
}

/// Returns a $4 \times 4$ rotation matrix - yaw-pitch-roll
///
/// Calculates the product of the three rotation matrices
/// $R = Rz(a) Ry(b) Rx(c)$
///
/// - a (angle): Yaw
/// - b (angle): Pitch
/// - c (angle): Roll
/// -> matrix
#let transform-rotate-ypr(a, b, c) = {
  ((cos(a)*cos(b), cos(a)*sin(b)*sin(c) - sin(a)*cos(c), cos(a)*sin(b)*cos(c) + sin(a)*sin(c), 0),
   (sin(a)*cos(b), sin(a)*sin(b)*sin(c) + cos(a)*cos(c), sin(a)*sin(b)*cos(c) - cos(a)*sin(c), 0),
   (-sin(b), cos(b)*sin(c), cos(b)*cos(c), 1),
   (0,0,0,1))
}

/// Returns a $4 \times 4$ rotation matrix - euler angles
///
/// Calculates the product of the three rotation matrices
/// $R = Rz(z) Ry(y) Rx(x)$
///
/// - x (angle): Rotation about x
/// - y (angle): Rotation about y
/// - z (angle): Rotation about z
/// -> matrix
#let transform-rotate-xyz(x, y, z) = {
  ((cos(y)*cos(z), sin(x)*sin(y)*cos(z) - cos(x)*sin(z), cos(x)*sin(y)*cos(z) + sin(x)*sin(z), 0),
   (cos(y)*sin(z), sin(x)*sin(y)*sin(z) + cos(x)*cos(z), cos(x)*sin(y)*sin(z) - sin(x)*cos(z), 0),
   (-sin(y), sin(x)*cos(y), cos(x)*cos(y), 0),
   (0,0,0,1))
}

/// Multiplies matrices on top of each other.
/// - ..matrices (matrix): The matrices to multiply from left to right.
/// -> matrix
#let mul-mat(..matrices) = {
  matrices = matrices.pos()
  let out = matrices.remove(0)
  for matrix in matrices {
    let (m, n, p) = (
      ..dim(out),
      dim(matrix).last()
    )
    out = (
      for i in range(m) {
        (
          for j in range(p) {
            (_round(range(n).map(k => out.at(i).at(k) * matrix.at(k).at(j)).sum(), digits: precision),)
          }
        ,)
      }
    )
  }
  return out
}

// Multiply 4x4 matrix with vector of size 3 or 4.
// The value of vec_4 defaults to w (1).
//
// The resulting vector is of dimension 3
/// Multiplies a $4 \times 4$ matrix with a vector of size 3 or 4. The resulting is three dimensional
/// - mat (matrix): The matrix to multiply
/// - vec (vector): The vector to multiply
/// - w (float): The default value for the fourth element of the vector if it is three dimensional.
/// -> vector
#let mul4x4-vec3(mat, vec, w: 1) = {
  assert(vec.len() <= 4)

  let x = vec.at(0)
  let y = vec.at(1)
  let z = vec.at(2, default: 0)
  let w = vec.at(3, default: w)

  let ((a1,a2,a3,a4), (b1,b2,b3,b4), (c1,c2,c3,c4), _) = mat
  return (
    a1 * x + a2 * y + a3 * z + a4 * w,
    b1 * x + b2 * y + b3 * z + b4 * w,
    c1 * x + c2 * y + c3 * z + c4 * w)
}

// Multiply matrix with vector
/// Multiplies an $m \times n$ matrix with an $m$th dimensional vector where $m \lte 4$. Prefer the use of `mul4x4-vec3` when possible as it does not use loops.
/// - mat (matrix): The matrix to multiply
/// - vec (vector): The vector to multiply
/// -> vector
#let mul-vec(mat, vec) = {
  let m = mat.len()
  let n = mat.at(0).len()
  assert(n == vec.len(), message: "Matrix columns must be equal to vector rows")

  let new = (0,) * m
  for i in range(0, m) {
    for j in range(0, n) {
      new.at(i) = new.at(i) + mat.at(i).at(j) * vec.at(j)
    }
  }
  return new
}

/// Calculates the inverse matrix of any size.
/// - matrix (matrix): The matrix to inverse.
/// -> matrix
#let inverse(matrix) = {
  let n = {
    let size = dim(matrix)
    assert.eq(size.first(), size.last(), message: "Matrix must be square to perform inversion.")
    size.first()
  }

  let N = range(n)
  let inverted = ident(m: n, n: n)
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

/// Swaps the a-th column with the b-th column.
///
/// - mat (matrix): Matrix
/// - a (int): The index of column a.
/// - b (int): The index of column b.
/// -> matrix
#let swap-cols(mat, a, b) = {
  let new = mat
  for m in range(mat.len()) {
    new.at(m).at(a) = mat.at(m).at(b)
    new.at(m).at(b) = mat.at(m).at(a)
  }
  return new
}

/// Translates a matrix by a vector.
/// - mat (matrix): The matrix to translate
/// - vec (vector): The vector to translate by.
#let translate(mat, vec) = {
  return mul-mat(
    mat,
    transform-translate(
      vec.at(0),
      -vec.at(1),
      vec.at(2),
    ),
  )
}
