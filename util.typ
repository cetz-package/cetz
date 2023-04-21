#import "matrix.typ"
#import "vector.typ"

// Apply all transformation matrices `queue` in order on `vec`.
#let apply-transform(queue, vec) = {
  vec = vector.as-vec(vec, init: (0,0,0,1))
  for (_, m) in queue {
    if m != none {
      vec = matrix.mul-vec(m, vec)
    }
  }
  return vec.slice(0, 3)
}

// Convert absolute, relative or anchor coordinate to absolute coordinate
#let abs-coordinate(ctx, c, relaxed: false) = {
  // Format: () -- Current coordinates
  if c == () {
    return ctx.prev.pt
  }

  // Format: <anchor-name> -- Anchor coordinates
  if type(c) == "string" {
    let parts = c.split(".")
    if parts.len() == 1 {
      c = (node: parts.at(0))
    } else {
      c = (node: parts.slice(0, -1).join("."), at: parts.at(-1))
    }
  }

  if type(c) == "dictionary" {
    if "node" in c {
      assert(c.node in ctx.anchors,
             message: "Unknown node '" + c.node + "' in nodes " + repr(ctx.anchors))

      let node = ctx.anchors.at(c.node)
      let anchor = none
      if "at" in c {
        assert(c.at in node,
               message: "Unknown anchor '" + c.at + "' of " + repr(node))
        
        anchor = node.at(c.at)
      } else {
        anchor = node.default
      }

      return anchor
    }

    // Add relative positions to previous position
    if "rel" in c {
      return vector.add(ctx.prev.pt, vector.as-vec(c.rel))
    }

    panic("Invalid coordiantes: " + repr(c))
  }

  if type(c) == "array" {
    let t = c.at(0)

    // Format: (<angle>, <length>)
    if t == "angle" {
      assert(c.len() == 2,
             message: "Expected position of format (<angle>, <length>), got: " + repr(c))

      let (angle, length) = c
      return (vec: (calc.cos(angle) * length,
                    calc.sin(angle) * length, 0))
    }

    // Format: (<function>, <coordinate or value>, ...)
    if t == "function" {
      assert(c.len() >= 2,
             message: "Expected position of format (<function>, <position>, ...), got: " + repr(c))

      let fn = c.at(0)
      let rest = c.slice(1).map(x => {
        let vec = abs-coordinate(x, ctx, relaxed: true)
        if type(vec) == "dictionary" and "vec" in vec {
          return vec.vec
        }
        return vec  
      })

      return (vec: fn(..rest))
    }

    // Format: (x, y[, z])
    assert(c.len() >= 2 and c.len() <= 3,
           message: "Expected coordinates, got: " + repr(c))
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

  if not relaxed {
    panic("Invalid coordinates: " + repr(c))
  }

  return c
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
