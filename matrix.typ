#import "vector.typ"

// Create identity matrix with dim `m`, `n`
#let ident(m: 4, n: 4, one: 1, zero: 0) = {
  ({for m in range(0, m) {
    ({for n in range(0, n) {
        if m == n { (one,) } else { (zero,) }
     }},)
    }})
}

// Return matrix dimension (m, n)
#let dim(m) = {
  return (m.len(), if m.len() > 0 {m.at(0).len()} else {0})
}

// Return 4x4 translation matrix
#let transform-translate(x, y, z) = {
  ((1, 0, 0, x),
   (0, 1, 0, y),
   (0, 0, 1, z),
   (0, 0, 0, 1))
}

// Return 4x4 z-shear matrix
#let transform-shear-z(factor) = {
  ((1, 0, factor, 0),
   (0, 1,-factor, 0),
   (0, 0, 1, 0),
   (0, 0, 0, 1))
}

// Return 4x4 scale matrix
#let transform-scale(f) = {
  let (x, y, z) = if type(f) != "dictionary" {
    (f, f, f)
  } else {
    (f.x, f.y, f.z)
  }
  return(
   (x, 0, 0, 0),
   (0, y, 0, 0),
   (0, 0, z, 0),
   (0, 0, 0, 1))
}

// Return 4x4 rotate x matrix
#let transform-rotate-x(angle) = {
  let (cos, sin) = (calc.cos, calc.sin)
  ((1, 0, 0, 0),
   (0, cos(angle), -sin(angle), 0),
   (0, sin(angle), cos(angle), 0),
   (0, 0, 0, 1))
}

// Return 4x4 rotate y matrix
#let transform-rotate-y(angle) = {
  let (cos, sin) = (calc.cos, calc.sin)
  ((cos(angle), 0, -sin(angle), 0),
   (0, 1, 0, 0),
   (sin(angle), 0, cos(angle), 0),
   (0, 0, 0, 1))
}

// Return 4x4 rotate z matrix
#let transform-rotate-z(angle) = {
  let (cos, sin) = (calc.cos, calc.sin)
  ((cos(angle), -sin(angle), 0, 0),
   (sin(angle), cos(angle), 0, 0),
   (0, 0, 1, 0),
   (0, 0, 0, 1))
}

// Return 4x4 rotate xz matrix
#let transform-rotate-xz(x, z) = {
  let (pi, cos, sin) = (calc.pi, calc.cos, calc.sin)
  ((cos(z), sin(z), 0, 0),
   (-cos(x)*sin(z), cos(x)*cos(z), -sin(x), 0),
   (sin(x)*sin(z), -sin(x)*cos(z), cos(x), 1),
   (0, 0, 0, 1))
}

// Return 4x4 rotate xyz matrix
#let transform-rotate-xyz(x, y, z) = {
  let (pi, cos, sin) = (calc.pi, calc.cos, calc.sin)
  ((cos(x)*cos(y)*cos(z)-sin(x)*sin(z),
    -cos(x)*cos(y)*sin(z)-sin(x)*cos(z),
    cos(x)*sin(y), 0),
   (sin(x)*cos(y)*cos(z)+cos(x)*sin(z),
    -sin(x)*cos(y)*sin(z)+cos(x)*cos(z),
    sin(x)*sin(y), 0),
   (-sin(y)*cos(z),
    sin(y)*sin(z),
    cos(y), 0),
    (0, 0, 0, 1))
}

// Multiply matrix with matrix
#let mul-mat(a, b) = {
  panic("Not implemented!")
}

// Multiply matrix with vector
#let mul-vec(mat, vec) = {
  if mat.len() != vector.dim(vec) {
    panic("matrix m must be equal to vector dim")
  }
  let new = (0, 0, 0, 1)
  for m in range(0, mat.len()) {
    let v = 0
    for n in range(0, vector.dim(vec)) {
      v += vec.at(n) * mat.at(m).at(n)
    }
    new.at(m) = v
  }
  return new
}
