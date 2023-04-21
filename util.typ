#import "matrix.typ"
#import "vector.typ"

// Apply all transformation matrices `queue` in order on `vec`.
#let apply-transform(queue, vec) = {
  for (_, m) in queue {
    if m != none {
      vec = matrix.mul-vec(m, vector.as-vec(
        vec, init: (0, 0, 0, 1)))
    }
  }
  return vec.slice(0, 2)
}

// Convert absolute, relative or anchor coordinate to absolute coordinate
#let abs-coordinate(ctx, c) = {
  // Use previous position
  if c == () {
    return ctx.prev.pt
  }

  // Allow strings as shorthand for anchors
  if type(c) == "string" {
        // assert(c != "g2.in 2", message: repr(ctx))

      let parts = c.split(".")
      if parts.len() == 1 {
        c = (node: parts.at(0))
      } else {
        c = (node: parts.slice(0, -1).join("."), at: parts.at(-1))
      }
  }

  if type(c) == "dictionary" {
    if "node" in c {
      assert(c.node in ctx.anchors, message: "Unknown node '" + c.node + "' in nodes " + repr(ctx.anchors))
      let node = ctx.anchors.at(c.node)
      if "at" in c {
        assert( c.at in node, message: "Unknown anchor '" + c.at + "' of " + repr(node))
        return node.at(c.at)
      }
      return node.default
    }

    // Add relative positions to previous position
    if "rel" in c {
      return vector.add(ctx.prev.pt, c.rel)
    }

    panic("Not implemented")
  }

  // Transform lengths with unit to canvas lenght
  return apply-transform(ctx.transform, c.map(x => if type(x) == "length" {
    // HACK ALERT!
    if repr(x).ends-with("em") {
      float(repr(x).slice(0, -2)) * em-size.width / ctx.length
    } else {
      float(x / ctx.length)
    }
  } else {
    float(x)
  }))
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
