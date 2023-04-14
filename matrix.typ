#let ident(m: 4, n: 4, one: 1, zero: 0) = {
  ({for m in range(0, m) {
    ({for n in range(0, n) {
        if m == n { (one,) } else { (zero,) }
     }},)
    }})
}

#let transform-translate(x, y, z) = {
  ((1, 0, 0, x),
   (0, 1, 0, y),
   (0, 0, 1, z),
   (0, 0, 0, 1))
}

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

#let transform-rotate-x(angle) = {
  let (cos, sin) = (calc.cos, calc.sin)
  ((1, 0, 0, 0),
   (0, cos(angle), -sin(angle), 0),
   (0, sin(angle), cos(angle), 0),
   (0, 0, 0, 1))
}

#let transform-rotate-y(angle) = {
  let (cos, sin) = (calc.cos, calc.sin)
  ((cos(angle), 0, -sin(angle), 0),
   (0, 1, 0, 0),
   (sin(angle), 0, cos(angle), 0),
   (0, 0, 0, 1))
}

#let transform-rotate-z(angle) = {
  let (cos, sin) = (calc.cos, calc.sin)
  ((cos(angle), -sin(angle), 0, 0),
   (sin(angle), cos(angle), 0, 0),
   (0, 0, 1, 0),
   (0, 0, 0, 1))
}

#let transform-rotate-xz(x, z) = {
  let (pi, cos, sin) = (calc.pi, calc.cos, calc.sin)
  x = pi/180*x
  z = pi/180*z
  ((cos(z), sin(z), 0, 0),
   (-cos(x)*sin(z), cos(x)*cos(z), -sin(x), 0),
   (sin(x)*sin(z), -sin(x)*cos(z), cos(x), 1),
   (0, 0, 0, 1))
}

#let transform-rotate-xyz(x, y, z) = {
  let (pi, cos, sin) = (calc.pi, calc.cos, calc.sin)
  x = pi/180*x
  y = pi/180*y
  z = pi/180*z

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

#let transform-projection(angle) = {
  let near = 100 
  let far = -100
  let s = calc.sin(angle)
  ((1, 0, -s, 0),
   (0, 1, s, 0),
   (0, 1, 1, 0),
   (0, 0, 0, 1))
}

#let mul-mat(a, b) = {
  if a.at(0).len() != b.len() {
    panic("matrix (a) n must be equal to matrix (b) m")
  }
  let c = ident(m: a.len(), n: b.at(0).len())
  for i in range(0, a.len()) {
    for j in range(0, b.at(0).len()) {
      for k in range(0, b.len()) {
        c.at(i).at(j) += a.at(i).at(k) * b.at(k).at(i)
      }
    }
  }
  return c
}

#let mul-vec(mat, vec) = {
  if mat.len() != vec.len() {
    panic("matrix m must be equal to vector dim")
  }
  let new = (0, 0, 0, 1)
  for m in range(0, mat.len()) {
    let v = 0
    for n in range(0, vec.len()) {
      v += vec.at(n) * mat.at(m).at(n)
    }
    new.at(m) = v
  }
  return new
}
