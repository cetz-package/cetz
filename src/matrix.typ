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

/// Create identity matrix with dimensions $m times n$
///
/// - m (int): Rows
/// - n (int): Columns
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

/// Return matrix dimensions (m, n)
/// -> tuple
#let dim(m) = {
  return (m.len(), if m.len() > 0 {m.at(0).len()} else {0})
}

/// Get matrix column n as vector
/// - mat (matrix): Input matrix
/// - n (int): Column
/// -> vector
#let column(mat, n) = {
  range(0, mat.len()).map(m => mat.at(m).at(n))
}

/// Return copy matrix with column n set to vector
/// - mat (matrix): Input matrix
/// - n (int): Column
/// - vec (vector): Column vector
/// -> matrix
#let set-column(mat, n, vec) = {
  assert(vec.len() == matrix.len())
  for m in range(0, mat.len()) {
    mat.at(m).at(n) = vec.at(n)
  }
}

/// Round matrix by rounding all cells
/// applying rounding
/// - mat (matrix): Input matrix
/// - precision (int): Rounding precision (digits)
/// -> matrix
#let round(mat, precision: precision) = {
  mat.map(r => r.map(v => _round(v, digits: precision)))
}

/// Return a $4 times 4$ translation matrix
#let transform-translate(x, y, z) = {
  ((1, 0, 0, x),
   (0, 1, 0, y),
   (0, 0, 1, z),
   (0, 0, 0, 1))
}

// Return 4x4 x-shear matrix
#let transform-shear-x(factor) = {
  ((1, factor, 0, 0),
   (0, 1, 0, 0),
   (0, 0, 1, 0),
   (0, 0, 0, 1))
}

/// Return a $4 times 4$ z-shear matrix
#let transform-shear-z(factor) = {
  ((1, 0, factor, 0),
   (0, 1,-factor, 0),
   (0, 0, 1, 0),
   (0, 0, 0, 1))
}

// Return 4x4 scale matrix
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

// Return 4x4 rotate xyz matrix for direction and up vector
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
#let transform-rotate-x(angle) = {
  ((1, 0, 0, 0),
   (0, cos(angle), -sin(angle), 0),
   (0, sin(angle), cos(angle), 0),
   (0, 0, 0, 1))
}

// Return 4x4 rotate y matrix
#let transform-rotate-y(angle) = {
  ((cos(angle), 0, -sin(angle), 0),
   (0, 1, 0, 0),
   (sin(angle), 0, cos(angle), 0),
   (0, 0, 0, 1))
}

// Return 4x4 rotate z matrix
#let transform-rotate-z(angle) = {
  ((cos(angle), -sin(angle), 0, 0),
   (sin(angle), cos(angle), 0, 0),
   (0, 0, 1, 0),
   (0, 0, 0, 1))
}

// Return 4x4 rotate xz matrix
#let transform-rotate-xz(x, z) = {
  ((cos(z), sin(z), 0, 0),
   (-cos(x)*sin(z), cos(x)*cos(z), -sin(x), 0),
   (sin(x)*sin(z), -sin(x)*cos(z), cos(x), 1),
   (0, 0, 0, 1))
}

/// Return 4x4 rotation matrix - yaw-pitch-roll
///
/// Calculates the product of the three rotation matrices
/// R = Rz(a) Ry(b) Rx(c)
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

/// Return 4x4 rotation matrix - euler angles
///
/// Calculates the product of the three rotation matrices
/// R = Rz(z) Ry(y) Rx(x)
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

/// Multiply matrices on top of each other.
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
#let mul4x4-vec3(mat, vec, w: 1) = {
  assert(vec.len() <= 4)
  let out = (0, 0, 0)
  for m in range(0, 3) {
    let v = (mat.at(m).at(0) * vec.at(0, default: 0)
           + mat.at(m).at(1) * vec.at(1, default: 0)
           + mat.at(m).at(2) * vec.at(2, default: 0)
           + mat.at(m).at(3) * vec.at(3, default: w))
    out.at(m) = v
  }
  return out
}

// Multiply matrix with vector
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

/// Swap column a with column b
///
/// - mat (matrix): Matrix
/// - a (int): Column a
/// - b (int): Column b
/// -> matrix New matrix
#let swap-cols(mat, a, b) = {
  let new = mat
  for m in range(mat.len()) {
    new.at(m).at(a) = mat.at(m).at(b)
    new.at(m).at(b) = mat.at(m).at(a)
  }
  return new
}

// Translate the matrix by the vector
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
