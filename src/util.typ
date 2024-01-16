#import "deps.typ"
#import deps.oxifmt: strfmt

#import "matrix.typ"
#import "vector.typ"
#import "bezier.typ"


/// Constant to be used as float rounding error
#let float-epsilon = 0.000001

#let typst-measure = measure


/// Multiplies vectors by the transform matrix
///
/// - transform (matrix): Transformation matrix
/// - ..vecs (vectors): Vectors to get transformed. Only the positional part of the sink is used. A dictionary of vectors can be passed and all will be transformed.
/// -> vectors If multiple vectors are given they are returned as an array, if only one vector is given only one will be returned, if a dictionary is given they will be returned in the dictionary with the same keys.
#let apply-transform(transform, ..vecs) = {
  let t = vec => matrix.mul4x4-vec3(
    transform, vec)
  if type(vecs.pos().first()) == dictionary {
    vecs = vecs.pos().first()
    for (k, vec) in vecs {
      vecs.insert(k, t(vec))
    }
  } else {
    vecs = vecs.pos().map(t)
    if vecs.len() == 1 {
      return vecs.first()
    }
  }
  return vecs
}

// #let apply-transform-many(transform, vecs) = {
//   if type(vecs) == array {
//     vecs.map(apply-transform.with(transform))
//   } else if type(vecs) == dictionary {
//     for (k, vec) in vecs {
//       vecs.insert(k, apply-transform(transform, vec))
//     }
//     vecs
//   }
// }

/// Reverts the transform of the given vector
///
/// - transform (matrix): Transformation matrix
/// - vec (vector): Vector to get transformed
/// -> vector
#let revert-transform(transform, ..vecs) = {
  apply-transform(matrix.inverse(transform), ..vecs)
}

// Get point on line
//
// - a (vector): Start point
// - b (vector): End point
// - t (float):  Position on line [0, 1]
#let line-pt(a, b, t) = {
  return vector.add(a, vector.scale(vector.sub(b, a), t))
}

/// Get orthogonal vector to line
///
/// - a (vector): Start point
/// - b (vector): End point
/// -> vector Cormal direction
#let line-normal(a, b) = {
  let v = vector.norm(vector.sub(b, a))
  return (0 - v.at(1), v.at(0), v.at(2, default: 0))
}

/// Get the arc-len of a circle or arc
///
/// - radius (float): Circle or arc radius
/// - start (angle): Start angle
/// - stop (angle): Stop angle
/// -> float Arc length
#let circle-arclen(radius, angle: 360deg) = {
  calc.abs(angle / 360deg * 2 * calc.pi)
}

/// Get point on an ellipse for an angle
///
/// - center (vector): Center
/// - radius (float,array): Radius or tuple of x/y radii
/// - angled (angle): Angle to get the point at
/// -> vector
#let ellipse-point(center, radius, angle) = {
  let (rx, ry) = if type(radius) == array {
    radius
  } else {
    (radius, radius)
  }

  let (x, y, z) = center
  return (calc.cos(angle) * rx + x, calc.sin(angle) * ry + y, z)
}

/// Calculate circle center from 3 points. The z coordinate
/// is taken from point a.
///
/// - a (vector): Point 1
/// - b (vector): Point 2
/// - c (vector): Point 3
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

  // Find intersection point of two 2d lines
  // L1: a*x + c
  // L2: b*x + d
  let line-intersection-2d(a, c, b, d) = {
    if a - b == 0 {
      if c == d {
        return (0, c, 0)
      }
      return none
    }
    let x = (d - c)/(a - b)
    let y = a * x + c
    return (x, y)
  }

  assert(args.len() == 4, message: "Could not find circle center")
  return vector.as-vec(line-intersection-2d(..args), init: (0, 0, a.at(2)))
}

#let resolve-number(ctx, num) = {
  if type(num) == length {
    if repr(num).ends-with("em") {
      float(repr(num).slice(0, -2)) * ctx.em-size.width / ctx.length
    } else {
      float(num / ctx.length)
    }
  } else if type(num) == ratio {
    return num
  } else {
    return float(num)
  }
}

#let resolve-radius(radius) = {
  return if type(radius) == array {radius} else {(radius, radius)}
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
#let merge-dictionary(a, b, overwrite: true) = {
  for (k, v) in b {
    if type(a) == dictionary and k in a and type(v) == dictionary and type(a.at(k)) == dictionary {
      a.insert(k, merge-dictionary(a.at(k), v, overwrite: overwrite))
    } else if overwrite or k not in a {
      a.insert(k, v)
    }
  }
  return a
}

// Measure content in canvas coordinates
#let measure(ctx, cnt) = {
  let size = typst-measure(cnt, ctx.typst-style)
  return (
    calc.abs(size.width / ctx.length),
    calc.abs(size.height / ctx.length)
  )
}

/// Get a padding/margin dictionary (top, left, bottom, right) from
/// a padding value.
///
/// - padding (none, number, array, dictionary): Padding specification
///   Type of `padding`:
///   / `none`: All sides padded by 0
///   / `number`: All sides are padded by the same value
///   / `array`: CSS like padding: `(y, x)`, `(top, x, bottom)` or `(top, right, bottom, left)`
///   / `dictionary`: Converts typst padding dictionary (top, left, bottom, right, x, y, rest)
///                   to a dictionary containing top, left, bottom and right.
///
/// -> dictionary Dictionary with the keys: top, left, bottom and right
#let as-padding-dict(padding) = {
  if padding == none {
    padding = 0
  }

  if type(padding) == array {
    // Allow CSS like padding array
    assert(padding.len() in (2, 3, 4),
      message: "Padding array formats are: (y, x), (top, x, bottom), (top, right, bottom, left)")
    if padding.len() == 2 {
      let (y, x) = padding
      return (top: y, right: x, bottom: y, left: x)
    } else if padding.len() == 3 {
      let (top, x, bottom) = padding
      return (top: top, right: x, bottom: bottom, left: x)
    } else if padding.len() == 4 {
      let (top, right, bottom, left) = padding
      return (top: top, right: right, bottom: bottom, left: left)
    }
  } else if type(padding) == dictionary {
    // Support typst padding dictionary
    let rest = padding.at("rest", default: 0)
    let x = padding.at("x", default: rest)
    let y = padding.at("y", default: rest)
    if not "left" in padding { padding.left = x }
    if not "right" in padding { padding.right = x }
    if not "top" in padding { padding.top = y }
    if not "bottom" in padding { padding.bottom = y }

    return padding
  } else {
    return (top: padding, left: padding, bottom: padding, right: padding)
  }
}

/// Get a corner-radius dictionary (north-east, north-west, south-east, south-west) from
/// a corner-radius value. Returns none if all radii are zero or none
///
/// - ctx (context): Canvas context object
/// - radii (none, number, dictionary): Radius specification
///   Type of `padding`:
///   / `number`: All corners have the same radius
///   / `tuple`: All corners have the same rx/ry radius
///   / `dictionary`: Converts corner radius dictionary (rest, north, south, east, west, north-south, north-east, south-west, south-east)
///     to a dictionary containing north-east, north-west, south-east and south-west
///
/// -> dictionary Dictionary with the keys: north-east, north-west, south-east, south-west set
///    to corner radius tuples (x and y radius)
#let as-corner-radius-dict(ctx, radii, size) = {
  if radii == none or radii == 0 {
    return (north-west: (0,0), north-east: (0,0),
            south-west: (0,0), south-east: (0,0))
  }

  let radii = (if type(radii) == dictionary {
    let rest = radii.at("rest", default: (0,0))
    let north = radii.at("north", default: auto)
    let south = radii.at("south", default: auto)
    let west = radii.at("west", default: auto)
    let east = radii.at("east", default: auto)

    if north != auto or south != auto {
      assert(west == auto and east == auto,
        message: "Corner radius north/south and west/east are mutually exclusive! Use per corner radii: north-west, .. instead.")
    }
    if west != auto or east != auto {
      assert(north == auto and south == auto,
        message: "Corner radius north/south and west/east are mutually exclusive! Use per corner radii: north-west, .. instead.")
    }

    let north-east = if north != auto { north } else if east != auto { east } else {rest}
    let north-west = if north != auto { north } else if west != auto { west } else {rest}
    let south-east = if south != auto { south } else if east != auto { east } else {rest}
    let south-west = if south != auto { south } else if west != auto { west } else {rest}

    (radii.at("north-west", default: north-west),
     radii.at("north-east", default: north-east),
     radii.at("south-west", default: south-west),
     radii.at("south-east", default: south-east))
  } else if type(radii) == array {
    panic("Invalid corner radius type: " + type(radii))
  } else {
    (radii, radii, radii, radii)
  }).map(v => if type(v) != array { (v, v) } else { v })

  // Resolve lengths to floats
  radii = radii.map(t => t.map(resolve-number.with(ctx)))

  // Clamp radii to half the size
  radii = radii.map(t => t.enumerate().map(((i, v)) => {
    calc.max(0, calc.min(if type(v) == ratio {
        v * size.at(i) / 100%
      } else { v }, size.at(i) / 2))
  }))

  let (nw, ne, sw, se) = radii
  return (
    north-west: nw,
    north-east: ne,
    south-west: sw,
    south-east: se,
  )
}

/// Sort list of points/vectors by distance to base
/// - base (vector): Vector to measure distance to
/// - pts (array of vector): List of points
/// -> array Sorted list of points
#let sort-points-by-distance(base, pts) = {
  if pts.len() == 1 {
    return pts
  }

  // Sort by transforming points into tuples of (point, distance),
  // sorting them by key 1 and then transforming them back to points.
  return pts.map(p => {
      return (p, vector.dist(p, base))
    })
    .sorted(key: t => t.at(1))
    .map(t => t.at(0))
}

/// Resolves a stroke into a usable dictionary with all fields that are missing or auto set to their defaults
#let resolve-stroke(stroke) = {
  if stroke == none {
    return (paint: none, thickness: 0pt, join: none, cap: none, miter-limit: 4)
  }

  let default = (
    paint: black,
    thickness: 1pt,
    join: "miter",
    cap: "butt",
    miter-limit: 4
  )
  let s = line(stroke: stroke).stroke
  let stroke = (:)
  for (k, v) in (paint: s.paint, thickness: s.thickness, join: s.join, cap: s.cap, miter-limit: s.miter-limit) {
    if v == auto {
      stroke.insert(k, default.at(k))
    } else {
      stroke.insert(k, v)
    }
  }
  return stroke
}
