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
  return vector.scale(vector.sub(b, a), t)
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
