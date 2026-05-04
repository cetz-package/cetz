#import "vector.typ"
#import "matrix.typ"
#import "util.typ"
#import "deps.typ"

#let resolve-xyz(c) = {
  // (x: <number> or <none>, y: <number> or <none>, z: <number> or <none>)
  // (x, y)
  // (x, y, z)

  return if type(c) == array {
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

  let (angle, xr, yr) = if type(c) == array {
    (
      c.first(),
      ..if type(c.last()) == array {
        c.last()
      } else {
        (c.last(), c.last())
      }
    )
  } else {
    (
      c.angle,
      ..if type(c.radius) == array {
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

#let resolve-anchor(ctx, inverse, c) = {
  // (name: <string>, anchor: <number, angle, string> or <none>)
  // "name.anchor"
  // "name"
  let (name, anchor) = if type(c) == str {
    if not c.contains(".") {
      (c, "default")
    } else {
      let (name, ..anchor) = c.split(".")
      (name, anchor)
    }
  } else {
    (c.name, c.at("anchor", default: "default"))
  }

  // Check if node is known
  let node = ctx.nodes.at(name, default: none)
  if node == none {
    panic("Unknown element '" + name + "' in elements " + repr(ctx.nodes.keys()))
  }

  // Resolve length anchors
  if type(anchor) == length {
    anchor = util.resolve-number(ctx, anchor)
  }

  return util.apply-transform(
    inverse,
    (node.anchors)(anchor)
  )
}

#let resolve-barycentric(ctx, inverse, c) = {
  // dictionary of numbers
  return vector.scale(
    c.bary.pairs().fold(
      (0, 0, 0),
      (vec, (k, v)) => {
          vector.add(
            vec,
            vector.scale(
              resolve-anchor(ctx, inverse, k),
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
  let (ctx, rel) = resolve(ctx, c.rel, update: false)
  let (ctx, to) = if "to" in c {
      resolve(ctx, c.to, update: false)
    } else {
      (ctx, ctx.prev.pt)
    }
  c = vector.add(
    rel,
    to,
  )
  c.insert(0, update)
  return c
}

#let resolve-tangent(resolve, inverse, ctx, c) = {
  // (element: <string>, point: <coordinate>, solution: <integer>)

  // 1) center + query point
  let C = resolve-anchor(ctx, inverse, c.element)
  let (ctx, P) = resolve(ctx, c.point, update: false)

  // 2) semi-axes a (east), b (north)
  let a = vector.len(vector.sub(resolve-anchor(ctx, inverse, c.element + ".east"),  C))
  let b = vector.len(vector.sub(resolve-anchor(ctx, inverse, c.element + ".north"), C))

  // 3) vector center→P
  let D = vector.sub(P, C)

  // 4) move into unit-circle coords
  let Dscaled = (D.at(0)/a, D.at(1)/b)
  let rho = vector.len(Dscaled)
  if rho < 1 {
    panic("No tangent solution for element " + c.element + " and point " + repr(c.point))
  }

  // 5) normalize & compute tangent parameters
  let ux = Dscaled.at(0) / rho
  let uy = Dscaled.at(1) / rho
  let t  = 1 / rho
  let h  = calc.sqrt(1 - t*t)

  // 6) pick one of the two solutions on the unit circle
  let (sx, sy) = if c.solution == 1 {
    (
      ux*t - uy*h,
      uy*t + ux*h
    )
  } else {
    (
      ux*t + uy*h,
      uy*t - ux*h
    )
  }

  // 7) map back through the ellipse‐stretch and return
  return (
    C.at(0) + a * sx,
    C.at(1) + b * sy,
    0
  )
}

#let resolve-perpendicular(resolve, ctx, c) = {
  // (horizontal: <coordinate>, vertical: <coordinate>)
  // (horizontal, "-|", vertical)
  // (vertical, "|-", horizontal)

  let (ctx, horizontal, vertical) = resolve(ctx, ..if type(c) == array {
    if c.at(1) == "|-" {
      (c.first(), c.last())
    } else {
      // c.at(1) == "-|"
      (c.last(), c.first())
    }
  } else {
    (c.horizontal, c.vertical)
  }, update: false)

  return (
    horizontal.at(0),
    vertical.at(1),
    0
  )
}

#let resolve-lerp(resolve, ctx, c) = {
  // (a: <coordinate>, number: <number,ratio>,
  //  angle?: <angle>, b: <coordinate>)
  // (a, <number, ratio>, b)
  // (a, <number, ratio>, angle, b)

  let (a, number, angle, b) = if type(c) == array {
    if c.len() == 3 {
      (
        ..c.slice(0, 2),
        none, // angle
        c.last(),
      )
    } else {
      c
    }
  } else {
    (
      c.a,
      c.number,
      c.at("angle", default: 0deg),
      c.b
    )
  }

  (ctx, a, b) = resolve(ctx, a, b)

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

  let ab = vector.sub(b, a)

  let is-absolute = type(number) != ratio
  let distance = if is-absolute {
    let dist = vector.len(ab)
    if dist != 0 {
      util.resolve-number(ctx, number) / dist
    } else {
      0
    }
  } else {
    number / 100%
  }

  return vector.add(a, vector.scale(ab, distance))
}

// Resolve a projection coordinate.
//
// (project: p, onto: (a, b))
// (p, "_|_", a, b)
// (p, "⟂", a, b)
#let resolve-project-point-on-line(resolve, ctx, c) = {
  let (ctx, a, b, p) = if type(c) == dictionary {
    let (project: p, onto: (a, b)) = c
    (_, a, b) = resolve(ctx, a, b)
    (ctx, p) = resolve(ctx, p)
    (ctx, a, b, p)
  } else {
    let (p, _, a, b) = c
    (_, a, b) = resolve(ctx, a, b)
    (ctx, p) = resolve(ctx, p)
    (ctx, a, b, p)
  }

  let ap = vector.sub(p, a)
  let ab = vector.sub(b, a)

  return vector.add(a, vector.scale(ab, vector.dot(ap, ab) / vector.dot(ab, ab)))
}

#let resolve-function(resolve, ctx, c) = {
  let (func, ..c) = c
  (ctx, ..c) = resolve(ctx, ..c)
  func(..c)
}

// Figures out what system a coordinate belongs to and returns the corresponding string.
// - c (coordinate): The coordinate to find the system of.
// -> str
#let _resolve-system(c) = {
  let t = if type(c) == dictionary {
    let keys = c.keys()
    let len = c.len()
    if len in (1, 2, 3) and keys.all(k => k in ("x", "y", "z")) {
      "xyz"
    } else if len == 2 and keys.all(k => k in ("angle", "radius")) and {
      let radius-type = type(c.radius)
      radius-type in (int, float, length) or (radius-type == array and c.radius.len() == 2)
    } {
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
    } else if len == 2 and keys.all(k => k in ("project", "onto")) {
      "project"
    }
  } else if type(c) == array {
    let len = c.len()
    let t0 = if len > 0 { type(c.first()) }
    let t1 = if len > 1 { type(c.at(1)) }
    let t2 = if len > 2 { type(c.at(2)) }

    if len == 0 {
      "previous"
    } else if len == 2 and t0 in (int, float, length) and t1 in (int, float, length) {
      "xyz"
    } else if len == 3 and t0 in (int, float, length) and t1 in (int, float, length) and t2 in (int, float, length) {
      "xyz"
    } else if len == 2 and t0 == angle {
      "polar"
    } else if len == 3 and c.at(1) in ("-|", "|-") {
      "perpendicular"
    } else if len == 3 and t1 in (int, float, length, ratio) {
      "lerp"
    } else if len == 4 and t1 in (int, float, length, ratio) and t2 == angle {
      "lerp"
    } else if len == 4 and c.at(1) in ("_|_", "⟂") {
      "project"
    } else if len >= 2 and t0 == function {
      "function"
    }
  } else if type(c) == str {
    if c.contains(".") {
      "anchor"
    } else {
      "element"
    }
  }

  if t == none {
    panic("Failed to resolve coordinate system: " + repr(c))
  }
  return t
}

// Fast path for resolving 3 element vectors of numbers.
#let _resolve-vec(ctx, v) = {
  let (x, y, z, ..) = v
  let t0 = type(x)
  let t1 = type(y)
  let t2 = type(z)
  let int-float = (int, float)

  if t0 in int-float and t1 in int-float and t2 in int-float {
    return (float(x), float(y), float(z))
  }

  return (util.resolve-number(ctx, x),
          util.resolve-number(ctx, y),
          util.resolve-number(ctx, z))
}

/// Resolve a list of coordinates to absolute vectors. Returns an array of the new <Type>context</Type> then the resolved coordinate vectors.
///
/// ```example
/// line((0,0), (1,1), name: "l")
/// get-ctx(ctx => {
///   // Get the vector of coordinate "l.start" and "l.end"
///   let (ctx, a, b) = cetz.coordinate.resolve(ctx, "l.start", "l.end")
///   content("l.start", [#a], frame: "rect", stroke: none, fill: white)
///   content("l.end",   [#b], frame: "rect", stroke: none, fill: white)
/// })
/// ```
///
/// - ctx (context): Canvas context object
/// - ..coordinates (coordinate): List of coordinates
/// - update (bool): Update the context's last position
/// -> array
#let resolve(ctx, ..coordinates, update: true) = {
  let cached-inverse = none

  let resolver = if type(ctx.resolve-coordinate) == array {
    ctx.resolve-coordinate
  } else {
    ()
  }

  let result = ()
  for c in coordinates.pos() {
    for resolve-fn in resolver.rev() {
      c = resolve-fn(ctx, c)
    }

    let t = _resolve-system(c)
    c = _resolve-vec(ctx, if t == "xyz" {
      resolve-xyz(c)
    } else if t == "previous" {
      ctx.prev.pt
    } else if t == "polar" {
      resolve-polar(c)
    } else if t == "barycentric" {
      if cached-inverse == none {
        cached-inverse = matrix.inverse(ctx.transform)
      }
      resolve-barycentric(ctx, cached-inverse, c)
    } else if t in ("element", "anchor") {
      if cached-inverse == none {
        cached-inverse = matrix.inverse(ctx.transform)
      }
      resolve-anchor(ctx, cached-inverse, c)
    } else if t == "tangent" {
      if cached-inverse == none {
        cached-inverse = matrix.inverse(ctx.transform)
      }
      resolve-tangent(resolve, cached-inverse, ctx, c)
    } else if t == "perpendicular" {
      resolve-perpendicular(resolve, ctx, c)
    } else if t == "relative" {
      (update, ..c) = resolve-relative(resolve, ctx, c)
      c
    } else if t == "lerp" {
      resolve-lerp(resolve, ctx, c)
    } else if t == "project" {
      resolve-project-point-on-line(resolve, ctx, c)
    } else if t == "function" {
      resolve-function(resolve, ctx, c)
    } else {
      panic("Failed to resolve coordinate of format: " + repr(c))
    })

    if update {
      ctx.prev.pt = c
    }

    result.push(c)
  }

  return (ctx, ..result)
}
