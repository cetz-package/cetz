#import "./vector.typ"
#import "./util.typ"


#let resolve-xyz(c) = {
  // (x: <number> or <none>, y: <number> or <none>, z: <number> or <none>)
  // (x, y)
  // (x, y, z)
  
  return if type(c) == "array" {
    vector.as-vec(c)
  } else {
     (
      c.at("x", default: 0),
      c.at("y", default: 0),
      c.at("z", default: 0),
    )
  }
}


#let resolve-polar(c) = {
  // (angle: <angle>, radius: <number>)
  // (angle: <angle>, radius: (x, y))
  // (angle, radius)
  // (angle, (x-radius, y-radius))

  let (angle, xr, yr) = if type(c) == "array" {
    (
      c.first(),
      ..if type(c.last()) == "array" {
        c.last()
      } else {
        (c.last(), c.last())
      }
    )
  } else {
    (
      c.angle,
      ..if type(c.radius) == "array" {
        c.radius
      } else {
        (c.radius, c.radius)
      }
    )
  }
  return (
    xr * calc.cos(angle),
    yr * calc.sin(angle),
    0
  )
}


#let resolve-anchor(ctx, c) = {
  // (name: <string>, anchor: <string> or <none>)
  // "name.anchor"
  // "name"

  let (name, anchor) = if type(c) == "string" {
    let parts = c.split(".")
    if parts.len() == 1 {
      (parts.first(), "default")
    } else {
      (parts.slice(0, -1).join("."), parts.last())
    }
  } else {
    (c.name, c.at("anchor", default: "default"))
  }

  // Check if node is known
  assert(name in ctx.nodes, message: "Unknown element '" + name + "' in elements " + repr(ctx.nodes.keys()))
  let node = ctx.nodes.at(name)
  // Check if anchor is known
  assert(anchor in node.anchors, message: "Unknown anchor '" + anchor + "' in anchors " + repr(node.anchors.keys()) + " for node " + name)

  return util.revert-transform(
    ctx.transform,
    if anchor != none {
      node.anchors.at(anchor)
    } else {
      node.anchors.default
    }
  )
}

#let resolve-barycentric(ctx, c) = {
  // dictionary of numbers
  return vector.scale(
    c.bary.pairs().fold(
      vector.new(3),
      (vec, (k, v)) => {
          vector.add(
            vec,
            vector.scale(
              resolve-anchor(ctx, k),
              v
            )
          )
        }
      ),
    1 / c.bary.values().sum()
    )
}

#let resolve-relative(resolve, ctx, c) = {
  // (rel: <coordinate>, update: <bool> or <none>, to: <coordinate>)
  let update = c.at("update", default: true)
  c = vector.add(
    resolve(ctx, c.rel), 
    if "to" in c {
      resolve(ctx, c.to)
    } else {
      ctx.prev.pt
    }
  )
  if not update {
    c.insert(0, false)
  }
  return c
}

#let resolve-tangent(resolve, ctx, c) = {
  // (element: <string>, point: <coordinate>, solution: <integer>)

  // https://stackoverflow.com/a/69641745/7142815
  let (C, P) = (resolve-anchor(ctx, c.element), resolve(ctx, c.point))
  // Radius
  let r = vector.len(vector.sub(resolve-anchor(ctx, c.element + ".top"), C))
  // Vector between C and P
  let D = vector.sub(P, C) // C - P
  // Distance between C and P
  let pc = vector.len(D)
  if pc < r {
    panic("No tangent solution for element " + c.element + " and point " + repr(c.point))
  }
  // Distance between P and X0
  let d = r*r / pc
  // Distance between X0 and X1(X2)
  let h = calc.sqrt(r*r - d*d)

  return if c.solution == 1 {
    (
      C.at(0) + (D.at(0) * d - D.at(1) * h) / pc,
      C.at(1) + (D.at(1) * d + D.at(0) * h) / pc,
      0
    )
  } else {
    (
      C.at(0) + (D.at(0) * d + D.at(1) * h) / pc,
      C.at(1) + (D.at(1) * d - D.at(0) * h) / pc,
      0
    )
  }
}

#let resolve-perpendicular(resolve, ctx, c) = {
  // (horizontal: <coordinate>, vertical: <coordinate>)
  // (horizontal, "-|", vertical)
  // (vertical, "|-", horizontal)

  let (horizontal, vertical) = if type(c) == "array" {
    if c.at(1) == "|-" {
      (c.first(), c.last())
    } else {
      // c.at(1) == "-|"
      (c.last(), c.first())
    }
  } else {
    (c.horizontal, c.vertical)
  }.map(resolve.with(ctx))
  return (
    horizontal.at(0),
    vertical.at(1),
    0
  )
}

#let resolve-lerp(resolve, ctx, c) = {
  // (a: <coordinate>, number: <number>,
  //  abs?: <bool>, angle?: <angle>, b: <coordinate>)
  // (a, number, b)
  // (a, number, angle, b)

  let (a, number, angle, b, abs) = if type(c) == "array" {
    if c.len() == 3 {
      (
        ..c.slice(0, 2),
        none, // angle
        c.last(),
        false,
      )
    } else {
      (
        ..c,
        false
      )
    }
  } else {
    (
      c.a,
      c.number,
      c.at("angle", default: 0deg),
      c.b,
      c.at("abs", default: false),
    )
  }

  (a, b) = (a, b).map(resolve.with(ctx))

  if angle != none {
    let (x, y, _) = vector.sub(b,a)
    b = vector.add(
      (
        calc.cos(angle) * x - calc.sin(angle) * y,
        calc.sin(angle) * x + calc.cos(angle) * y,
        0
      ),
      a,
    )
  }

  if type(number) == "length" {
    number = util.resolve-number(ctx, number) / vector.len(vector.sub(b,a))
  }

  if abs {
    number = number / vector.dist(a, b)
  }

  return vector.add(
    vector.scale(
      a,
      (1 - number)
    ),
    vector.scale(
      b,
      number
    )
  )
}

#let resolve-function(resolve, ctx, c) = {
  (c.first())(..c.slice(1).map(resolve.with(ctx)))
}

// Returns the given coordinate's system name
#let resolve-system(c) = {
  let t = if type(c) == "dictionary" {
    let keys = c.keys()
    let len = c.len()
    if len in (1, 2, 3) and keys.all(k => k in ("x", "y", "z")) {
      "xyz"
    } else if len == 2 and keys.all(k => k in ("angle", "radius")) and (type(c.radius) in ("integer", "float", "length") or (type(c.radius) == "array" and c.radius.len() == 2)) {
      "polar"
    } else if len == 1 and keys == ("bary",) {
      "barycentric"
    } else if len in (1, 2) and keys.all(k => k in ("name", "anchor")) {
      "anchor"
    } else if len == 3 and keys.all(k => k in ("element", "point", "solution")) {
      "tangent"
    } else if len == 2 and keys.all(k => k in ("horizontal", "vertical")) {
      "perpendicular"
    } else if len in (1, 2, 3) and keys.all(k => k in ("rel", "to", "update")) {
      "relative"
    } else if len in (3, 4) and keys.all(k => k in ("a", "number", "angle", "abs", "b")) {
      "lerp"
    }
  } else if type(c) == "array" {
    let len = c.len()
    let types = c.map(type)
    if len == 0 {
      "previous"
    } else if len in (2, 3) and types.all(t => t in ("integer", "float", "length")) {
      "xyz"
    } else if len == 2 and types.first() == "angle" {
      "polar"
    } else if len == 3 and c.at(1) in ("-|", "|-") {
      "perpendicular"
    } else if len in (3, 4) and types.at(1) in ("integer", "float", "length") and (len == 3 or (len == 4 and types.at(2) == "angle")) {
      "lerp"
    } else if len >= 2 and types.first() == "function" {
      "function"
    }
  } else if type(c) == "string" {
    "anchor"
  }

  if t == none {
    panic("Failed to resolve coordinate: " + repr(c))
  }
  return t
}



#let resolve(ctx, c) = {
  let t = resolve-system(c)

  return if t == "xyz" {
    resolve-xyz(c)
  } else if t == "previous" {
    ctx.prev.pt
  } else if t == "polar" {
    resolve-polar(c)
  } else if t == "barycentric" {
    resolve-barycentric(ctx, c)
  } else if t == "anchor" {
    resolve-anchor(ctx, c)
  } else if t == "tangent" {
    resolve-tangent(resolve, ctx, c)
  } else if t == "perpendicular" {
    resolve-perpendicular(resolve, ctx, c)
  } else if t == "relative" {
    resolve-relative(resolve, ctx, c)
  } else if t == "lerp" {
    resolve-lerp(resolve, ctx, c)
  } else if t == "function" {
    resolve-function(resolve, ctx, c)
  } else {
    panic("Failed to resolve coordinate of format: " + repr(c))
  }.map(util.resolve-number.with(ctx))
}
