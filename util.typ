#import "matrix.typ"
#import "vector.typ"

// Multiplies the vector by the transform matrix
#let apply-transform(transform, vec) = {
  matrix.mul-vec(
    transform, 
    vector.as-vec(vec, init: (0, 0, 0, 1))
  ).slice(0, 3)
}

// Reverts the transform of the given vector
#let revert-transform(transform, vec) = {
  apply-transform(matrix.inverse(transform), vec)
}

// Get point on line
//
// - a (vector): Start point
// - b (vector): End point
// - t (float):  Position on line [0, 1]
#let line-pt(a, b, t) = {
  return vector.add(a, vector.scale(vector.sub(b, a), t))
}

// First derivative of a line
#let line-dt(a, b) = {
  return vector.sub(b, a)
}

// Get tangent of a line
#let line-tangent(a, b) = {
  return vector.norm(line-dt(a, b))
}

// Get normal of a line
#let line-normal(a, b) = {
  let v = line-tangent(a, b)
  return (0 - v.at(1), v.at(0), v.at(2, default: 0))
}

// Find intersection point of two 2d lines
// L1: a*x + c
// L2: b*x + d
#let line-intersection-2d(a, c, b, d) = {
  if a - b == 0 {
    if c == d {
      return (0, c, 0)
    }
    return none
  }
  let x = (d - c)/(a - b)
  let y = a * x + c
  return (x, y, 0)
}

#let ellipse-pt(center, radius, angle) = {
  let (rx, ry) = if type(radius) == "array" {
    radius
  } else {
    (radius, radius)
  }

  let (x, y, z) = center
  return (calc.cos(angle) * rx + x, calc.sin(angle) * ry + y, z)
}

#let ellipse-tangent(center, radius, angle) = {
  let (rx, ry) = if type(radius) == "array" {
    radius
  } else {
    (radius, radius)
  }

  return vector.norm((-calc.sin(angle) * rx, calc.cos(angle) * ry, 0))
}

#let ellipse-normal(center, radius, angle) = {
  let t = ellipse-tangent(center, radius, angle)
  return (0 - t.at(1), t.at(0), t.at(2, default: 0))
}

// Calculate circle center from 3 points
//
// - a (vector): Point 1
// - b (vector): Point 2
// - c (vector): Point 3
#let calculate-circle-center-3pt(a, b, c) = {
  let m-ab = line-pt(a, b, .5)
  let m-bc = line-pt(b, c, .5)
  let m-cd = line-pt(c, a, .5)

  let args = () // a, c, b, d
  for i in range(0, 3) {
    let (p1, p2) = ((a,b,c).at(calc.rem(i,3)),
                    (b,c,a).at(calc.rem(i,3)))
    let m = line-pt(p1, p2, .5)
    let n = line-normal(p1, p2)

    // Find a line with a non upwards normal
    if n.at(0) == 0 { continue }

    let la = n.at(1) / n.at(0)
    args.push(la)
    args.push(m.at(1) - la * m.at(0))

    // We need only 2 lines
    if args.len() == 4 { break }
  }

  assert(args.len() == 4, message: "Could not find circle center")
  return line-intersection-2d(..args)
}

// Get point on quadratic bezier curve
//
// - a (vector): Start point
// - b (vector): End point
// - c (vector): Control point
// - t (float):  Position on curve [0, 1]
#let bezier-quadratic-pt(a, b, c, t) = {
  // (1-t)^2 * a + 2 * (1-t) * t * c + t^2 b
  return vector.add(
    vector.add(
      vector.scale(a, calc.pow(1-t, 2)),
      vector.scale(c, 2 * (1-t) * t)
    ),
    vector.scale(b, calc.pow(t, 2))
  )
}

// First derivative over t
#let bezier-quadratic-dt(a, b, c, t) = {
  // 2(-a(1-t) + bt - 2ct + c)
  return vector.scale(
    vector.add(
      vector.sub(
        vector.add(
          vector.scale(vector.neg(a), (1 - t)),
          vector.scale(b, t)),
        vector.scale(c, 2 * t)),
      c)
  , 2)
}

// Get tangent of quadratic bezier
#let bezier-quadratic-tangent(a, b, c, t) = {
  return vector.norm(bezier-quadratic-dt(a, b, c, t))
}

// Get normal of quadratic bezier
#let bezier-quadratic-normal(a, b, c, t) = {
  let v = bezier-quadratic-tangent(a, b, c, t)
  return (0 - v.at(1), v.at(0), v.at(2, default: 0))
}

// Get bezier curves ABC coordinates
//
// - s (vector): Curve start
// - e (vector): Curve end
// - B (vector): Point on curve
// - t (fload): Ratio on curve
// - order (int): Bezier order
//
// => (A, B, C)
#let bezier-ABC(s, e, B, t, order: 2) = {
  let tt = calc.pow(t, order)
  let u(t) = { calc.pow(1 - t, order) / (tt + calc.pow(1 - t, order)) }
  let ratio(t) = { calc.abs((tt + calc.pow(1 - t, order) - 1) /
                            (tt + calc.pow(1 - t, order))) }

  let C = vector.add(vector.scale(s, u(t)), vector.scale(e, 1 - u(t)))
  let A = vector.sub(B, vector.scale(vector.sub(C, B), 1 / ratio(t)))

  return (A, B, C)
}

// Get point on a cubic bezier curve
//
// - a (vector):  Start point
// - b (vector):  End point
// - c1 (vector): First control point
// - c2 (vector): Second control point
// - t (float):   Position on curve [0, 1]
#let bezier-cubic-pt(a, b, c1, c2, t) = {
  // (1-t)^3*a + 3*(1-t)^2*t*c1 + 3*(1-t)*t^2*c2 + t^3*b
  vector.add(
    vector.add(
      vector.scale(a, calc.pow(1-t, 3)),
      vector.scale(c1, 3 * calc.pow(1-t, 2) * t)
    ),
    vector.add(
      vector.scale(c2, 3*(1-t)*calc.pow(t,2)),
      vector.scale(b, calc.pow(t, 3))
    )
  )
}

// First derivative over t
#let bezier-cubic-dt(a, b, c1, c2, t) = {
  // -3(a(1-t)^2 + t(-2c2 - bt + 3 c2 t) + c1(-1 + 4t - 3t^2))
  vector.scale(
    vector.add(
      vector.add(
        vector.scale(a, calc.pow((1 - t), 2)),
        vector.scale(
          vector.sub(
            vector.add(
              vector.scale(b, -1 * t),
              vector.scale(c2, 3 * t)
            ),
            vector.scale(c2, 2)
          ),
          t
        )
      ),
      vector.scale(c1, -3 * calc.pow(t, 2) + 4 * t - 1)
    ),
    -3
  )
}

// Get tangent of cubic bezier
#let bezier-cubic-tangent(a, b, c1, c2, t) = {
  return vector.norm(bezier-cubic-dt(a, b, c1, c2, t))
}

// Get normal of cubic bezier
#let bezier-cubic-normal(a, b, c1, c2, t) = {
  let v = bezier-cubic-tangent(a, b, c1, c2, t)
  return (0 - v.at(1), v.at(0), v.at(2, default: 0))
}

#let resolve-number(ctx, num) = {
  if type(num) == "length" {
    if repr(num).ends-with("em") {
      float(repr(num).slice(0, -2)) * ctx.em-size.width / ctx.length
    } else {
      float(num / ctx.length)
    }
  } else {
    float(num)
  }
}

#let resolve-radius(radius) = {
  return if type(radius) == "array" {radius} else {(radius, radius)}
}

/// Find minimum value of a, ignoring `none`
#let min(..a) = {
  let a = a.pos().filter(v => v != none)
  return calc.min(..a)
}

/// Find maximum value of a, ignoring `none`
#let max(..a) = {
  let a = a.pos().filter(v => v != none)
  return calc.max(..a)
}

/// Merge dictionary a and b and return the result
/// Prefers values of b.
///
/// - a (dictionary): Dictionary a
/// - b (dictionary): Dictionary b
/// -> dictionary
#let merge-dictionary(a, b) = {
  if type(a) == "dictionary" and type(b) == "dictionary" {
    let c = a
    for (k, v) in b {
      if not k in c {
        c.insert(k, v)
      } else {
        c.at(k) = merge-dictionary(a.at(k), v)
      }
    }
    return c
  } else {
    return b
  }
}
