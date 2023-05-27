#import "matrix.typ"
#import "vector.typ"

// Apply all transformation matrices `queue` in order on `vec`.
#let apply-transform(queue, vec) = {
  vec = vector.as-vec(vec, init: (0, 0, 0, 1))
  for m in queue.do {
    if m != none {
      vec = matrix.mul-vec(m, vec)
    }
  }
  return vec.slice(0, 3)
}

// Revert all transformation matrices `queue` in
// reverse order on `vec`.
#let revert-transform(queue, vec) = {
  vec = vector.as-vec(vec, init: (0, 0, 0, 1))
  for m in queue.undo.rev() {
    if m != none {
      vec = matrix.mul-vec(m, vec)
    }
  }
  return vec.slice(0, 3)
}

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