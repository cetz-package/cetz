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
