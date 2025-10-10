#import "deps.typ"
#import deps.oxifmt: strfmt

#import "matrix.typ"
#import "vector.typ"
#import "bezier.typ"

/// Constant to be used as float rounding error
#let float-epsilon = 0.000001

/// Compare two floating point numbers
/// - a (float): First number
/// - b (float): Second number
/// - epsilon: Maximum distance between both numbers
/// -> bool
#let float-eq(a, b, epsilon: float-epsilon) = {
  return calc.abs(a - b) <= epsilon
}

/// Multiplies vectors by a transformation matrix. If multiple vectors are given they are returned as an array, if only one vector is given only one will be returned, if a dictionary is given they will be returned in the dictionary with the same keys.
///
/// - transform (matrix,function): The $4 times 4$ transformation matrix or a function that accepts and returns a vector.
/// - ..vecs (vector): Vectors to get transformed. Only the positional part of the sink is used. A dictionary of vectors can also be passed and all will be transformed.
/// -> vector,array,dictionary
#let apply-transform(transform, ..vecs) = {
  let t = if type(transform) != function {
    matrix.mul4x4-vec3.with(transform)
  } else {
    transform
  }
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

/// Reverts the transform of the given vector
///
/// - transform (matrix): Transformation matrix
/// - vec (vector): Vector to be transformed
/// -> vector
#let revert-transform(transform, ..vecs) = {
  apply-transform(matrix.inverse(transform), ..vecs)
}

/// Linearly interpolates between two points and returns its position
///
/// - a (vector): Start point
/// - b (vector): End point
/// - t (float):  Position on the line $[0, 1]$
/// -> vector
#let line-pt(a, b, t) = {
  return vector.add(a, vector.scale(vector.sub(b, a), t))
}

/// Get orthogonal vector to line
///
/// - a (vector): Start point
/// - b (vector): End point
/// -> vector
#let line-normal(a, b) = {
  let v = vector.norm(vector.sub(b, a))
  return (0 - v.at(1), v.at(0), v.at(2, default: 0))
}

/// Calculates the arc-length of a circle or arc
///
/// - radius (float): Circle or arc radius
/// - angle (angle): The angle of the arc.
/// -> float
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

/// Calculates the center of a circle from 3 points. The z coordinate is taken from point a.
///
/// - a (vector): Point 1
/// - b (vector): Point 2
/// - c (vector): Point 3
/// -> vector
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

/// Converts a {{number}} to "canvas units"
/// - ctx (context): The current context object.
/// - num (number): The number to resolve.
/// -> float
#let resolve-number(ctx, num) = {
  return if type(num) == length {
    float(num.to-absolute() / ctx.length)
  } else if type(num) == ratio {
    num
  } else {
    float(num)
  }
}

/// Call function `fn` for each key-value pair of `d`
/// and return the transformed dictionary.
///
/// - d (dictionary) Input dictionary
/// - fn (function) Transformation function
/// -> dictionary
#let map-dict(d, fn) = {
  for ((key, value)) in d {
    d.at(key) = fn(key, value)
  }
  return d
}

/// Ensures that a radius has an `x` and `y` component.
/// - radius (number, array):
/// -> array
#let resolve-radius(radius) = {
  return if type(radius) == array {radius} else {(radius, radius)}
}

/// Finds the minimum of a set of values while ignoring `none` values.
/// - a (float,none):
/// -> float
#let min(..a) = {
  let a = a.pos().filter(v => v != none)
  return calc.min(..a)
}

/// Finds the maximum of a set of values while ignoring `none` values.
/// - ..a (float,none):
/// -> float
#let max(..a) = {
  let a = a.pos().filter(v => v != none)
  return calc.max(..a)
}

/// Merges dictionary `b` onto dictionary `a`. If a key does not exist in `a` but does in `b`, it is inserted into `a` with `b`'s value. If a key does exist in `a` and `b`, the value in `b` is only inserted into `a` if the `overwrite` argument is `true`. If a key does exist both in `a` and `b` and both values are of type {{dictionary}} they will be recursively merged with this same function.
///
/// - a (dictionary): Dictionary a
/// - b (dictionary): Dictionary b
/// - overwrite (bool): Whether to override an entry in `a` that also exists in `b` with the value in `b`.
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

/// Measures the size of some {{content}} in canvas coordinates.
/// - ctx (context): The current context object.
/// - cnt (content): The content to measure.
/// -> vector
#let measure(ctx, cnt) = {
  let size = std.measure(cnt)
  return (
    calc.abs(size.width / ctx.length),
    calc.abs(size.height / ctx.length)
  )
}

/// Get a padding/margin dictionary with keys `(top, left, bottom, right)` from a padding value.
///
///
/// Type of `padding`:
/// / `none`: All sides padded by 0
/// / `number`: All sides are padded by the same value
/// / `array`: CSS like padding: `(y, x)`, `(top, x, bottom)` or `(top, right, bottom, left)`
/// / `dictionary`: Converts a Typst padding dictionary (top, left, bottom, right, x, y, rest) to a dictionary containing top, left, bottom and right.
///
/// - padding (none, number, array, dictionary): Padding specification
///
/// -> dictionary
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

/// Creates a corner-radius dictionary with keys `north-east`, `north-west`, `south-east` and `south-west` with values of a two element {{array}} of the radius in the `x` and `y` direction. Returns none if all radii are zero or none.
///
/// - ctx (context): The current canvas context object
/// - radii (none, number, dictionary): The radius specification. A {{number}} will cause all corners to have the same radius. An {{array}} with two items will cause all corners to have the same rx and ry radius. A {{dictionary}} can be given where the key specifies the corner and the value specifies the radius. The value can be either {{number}} for a circle radius or {{array}} for an x and y radius. The keys `north`, `south`, `east` and `west` targets both corners in that cardinal direction e.g. `south` sets the south west and south east corners. The keys `north-east`, `north-west`, `south-east` and `south-west` targets the corresponding corner. The key `rest` targets all other corners that have not been target by other keys.
/// - size (???): I'm not sure what this does.
///
/// -> dictionary
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

/// Sorts an array of vectors by distance to a common position.
/// - base (vector): The position to measure the distance of the other vectors from.
/// - pts (array): The array of vectors to sort.
/// -> array
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

/// Resolves a stroke into a usable dictionary with all fields that are missing or auto set to their Typst defaults.
/// - stroke (none, stroke): The stroke to resolve.
/// -> dictionary
#let resolve-stroke(stroke) = {
  if stroke == none {
    return (paint: none, thickness: 0pt, join: none, cap: none, miter-limit: 4)
  }

  if type(stroke) in (std.color, std.length) {
    stroke = std.stroke(stroke)
  }

  if type(stroke) == std.stroke {
    stroke = (
      paint: stroke.paint,
      thickness: stroke.thickness,
      join: stroke.join,
      cap: stroke.cap,
      miter-limit: stroke.miter-limit,
      dash: stroke.dash,
    )
  }

  let or-default(key, default) = {
    let v = stroke.at(key, default: default)
    return if v == auto { default } else { v }
  }

  return (
    paint: or-default("paint", black),
    thickness: or-default("thickness", 1pt),
    join: or-default("join", "miter"),
    cap: or-default("cap", "butt"),
    miter-limit: or-default("miter-limit", 4),
    dash: or-default("dash", none),
  )
}

/// Asserts whether a "body" has the correct type.
#let assert-body(body) = {
  assert(body == none or type(body) in (array, function),
    message: "Body must be of type none, array or function")
}

// Returns body if of type array, an
// empty array if body is none or
// the result of body called with ctx if of type
// function. A function result of none will return
// an empty array.
#let resolve-body(ctx, body) = {
  if type(body) == function {
    body = body(ctx)
  }
  if body == none {
    body = ()
  }
  return body
}


#let str-to-number-regex = regex("^(-?\d*\.?\d+)(cm|mm|pt|em|in|%|deg|rad)?$")
#let number-units = (
  "%": 1%,
  "cm": 1cm,
  "mm": 1mm,
  "pt": 1pt,
  "em": 1em,
  "in": 1in,
  "deg": 1deg,
  "rad": 1rad
)
#let str-is-number(string) = string.match(str-to-number-regex) != none
#let str-to-number(string) = {
  let (num, unit) = string.match(str-to-number-regex).captures
  num = float(num)
  if unit != none and unit in number-units {
    num *= number-units.at(unit)
  }
  return num
}
