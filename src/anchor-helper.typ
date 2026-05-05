#import "vector.typ"
#import "util.typ": float-epsilon

#let _sampled-quarter-samples = 16
#let _sampled-quarter = range(0, _sampled-quarter-samples + 1).map(t => {
  t = t / _sampled-quarter-samples * 90deg
  (calc.cos(t), calc.sin(t))
})

// Get the circumference of a sampled quarter.
//
// -> float
#let _sampled-quarter-circumference(x-radius, y-radius) = {
  let len = _sampled-quarter-samples
  let u = 0
  for i in range(1, len + 1) {
    let (p0x, p0y) = _sampled-quarter.at(i - 1)
    p0x *= x-radius
    p0y *= y-radius

    let (p1x, p1y) = _sampled-quarter.at(i)
    p1x *= x-radius
    p1y *= y-radius

    u += vector.dist((p0x, p0y), (p1x, p1y))
  }
  return u
}

// Lookup a sampled point on a quarter for distance s.
//
// - s (float): Distance on the quarter
// -> vector
#let _lookup-sampled-quarter-point(s, x-radius, y-radius) = {
  let len = _sampled-quarter-samples
  let t = 0
  for i in range(1, len + 1) {
    let (p0x, p0y) = _sampled-quarter.at(i - 1)
    p0x *= x-radius
    p0y *= y-radius

    let (p1x, p1y) = _sampled-quarter.at(i)
    p1x *= x-radius
    p1y *= y-radius
    let d = vector.dist((p0x, p0y), (p1x, p1y))

    // We found our segement, lets interpolate
    if t <= s and s <= t + d {
      return vector.lerp((p0x, p0y), (p1x, p1y), (s - t) / d)
    }

    t += d
  }

  return (0, y-radius)
}

// Lookup a point on the sampled ellipse for distance s
//
// - s (ration, float, length): Distance on the ellipses border, must be normalized
// - x-radius (float): X radius
// - y-radius (float): Y radius
// - unit-length (length): Unit length
// -> vector
// -> none
#let _lookup-ellipse-point(s, x-radius, y-radius, unit-length) = {
  let qcirc = _sampled-quarter-circumference(x-radius, y-radius)
  let circ = 4 * qcirc

  if type(s) == ratio {
    s = s / 100% * circ
  }
  if type(s) == length {
    s = s / unit-length
  }

  // Normalize the distance to [0, circ]
  s = s - calc.floor(s / circ) * circ

  // Find the quadrant we are in
  let quadrant = calc.floor(s / qcirc)
  let local = s - quadrant * qcirc

  return if quadrant == 0 {
    _lookup-sampled-quarter-point(local, x-radius, y-radius)
  } else if quadrant == 1 {
    let (x, y) = _lookup-sampled-quarter-point(qcirc - local, x-radius, y-radius)
    (-x, y)
  } else if quadrant == 2 {
    let (x, y) = _lookup-sampled-quarter-point(local, x-radius, y-radius)
    (-x, -y)
  } else {
    let (x, y) = _lookup-sampled-quarter-point(qcirc - local, x-radius, y-radius)
    (x, -y)
  }
}

// Compute a point on a circle for distance s
//
// - s (float): Distance on the circle border
// -> vector
#let _circle-point(s, radius, unit-length) = {
  let circ = 2 * calc.pi * radius

  if type(s) == ratio {
    s = s / 100% * circ
  }
  if type(s) == length {
    s = s / unit-length
  }

  // Normalize the distance to [0, u]
  s = s - calc.floor(s / circ) * circ

  let theta = s / circ * 360deg
  return (calc.cos(theta) * radius,
          calc.sin(theta) * radius)
}

/// Compute the border-anchor of a rect.
///
/// - center (vector): Rect center point
/// - angle (angle): Angle
/// - width (float): Width of the rect
/// - height (float): Height of the rect
/// -> vector
#let compute-rect-border(center, angle, width: 1, height: 1) = {
  let eps = float-epsilon
  let (cx, cy, cz) = center

  // Normalize angle
  angle = angle - calc.floor(angle / 360deg) * 360deg

  // Special cases for degenerate rects
  if width < eps {
    return (cx, cy + calc.sin(angle) * height / 2, cz)
  } else if height < eps {
    return (cx + calc.cos(angle) * width / 2, cy, cz)
  }

  // Fast path for square rects
  /* if calc.abs(width - height) < eps { */
    let sx = calc.cos(angle)
    let sy = calc.sin(angle)

    if 45deg <= angle and angle <= 135deg { sy = 1 }
    else if 225deg <= angle and angle <= 315deg { sy = -1 }

    if 315deg <= angle or angle <= 45deg { sx = 1 }
    else if 135deg <= angle and angle <= 225deg { sx = -1 }

    return (cx + sx * width / 2,
            cy + sy * height / 2,
            cz)
  /* } */

/* This is the correct code for tikz like border anchors on a circle
  let radius = width * width + height * height

  let p0 = (cx - width / 2, cy + height / 2, cz)
  let p1 = (cx + width / 2, cy + height / 2, cz)
  let p2 = (cx + width / 2, cy - height / 2, cz)
  let p3 = (cx - width / 2, cy - height / 2, cz)

  let scanline = (cx + calc.cos(angle) * radius,
                  cy + calc.sin(angle) * radius,
                  cz)

  let pt
  pt = intersection.line-line(p0, p1, center, scanline)
  if (pt != none) { return pt }
  pt = intersection.line-line(p1, p2, center, scanline)
  if (pt != none) { return pt }
  pt = intersection.line-line(p2, p3, center, scanline)
  if (pt != none) { return pt }
  pt = intersection.line-line(p3, p0, center, scanline)
  if (pt != none) { return pt }

  panic("Unreachable: rect-border", angle, center, scanline, width, height)
*/
}

/// Compute the path-anchor of a rect.
///
/// - center (vector): Rect center point
/// - anchor (float, ratio): Distance
/// - width (float): Width of the rect
/// - height (float): Height of the rect
/// - unit-length (length): Canvas unit length
/// -> vector
#let compute-rect-path(center, anchor, width: 1, height: 1, unit-length: 1cm) = {
  let u = width * 2 + height * 2
  if type(anchor) == ratio {
    anchor = anchor / 100% * u
  }
  if type(anchor) == length {
    anchor /= unit-length
  }

  // Normalize the distance to [0, u]
  anchor = anchor - calc.floor(anchor / u) * u
  let (cx, cy, cz) = center

  // We start at north-west -> south -> ...
  if anchor <= height { return (cx - width / 2, cy + height / 2 - anchor, cz) }
  if anchor <= height + width { return (cx - width / 2 + anchor - height, cy + height / 2, cz) }
  if anchor <= 2 * height + width { return (cx + width / 2, cy - height / 2 + anchor - height - width, cz) }
  return (cx + width / 2 - anchor + 2 * height + width, cy + height / 2, cz)
}

/// Compute the border-anchor of an ellipse.
///
/// - center (vector): Rect center point
/// - angle (angle): Angle
/// - x-radius (float): X radius
/// - y-radius (float): Y radius
/// -> vector
#let compute-ellipse-border(center, angle, x-radius: 1, y-radius: 1) = {
  let eps = float-epsilon

  let (cx, cy, cz) = center

  // TODO: See compute-rect-border
  /* if calc.abs(x-radius - y-radius) < eps { */
    return (cx + calc.cos(angle) * x-radius,
            cy + calc.sin(angle) * y-radius,
            cz)
  /* } */

/*
  let d = calc.sqrt(calc.pow(calc.cos(angle), 2)/(x-radius * x-radius) + calc.pow(calc.sin(angle), 2)/(y-radius * y-radius))
  let bx = calc.cos(angle) / d
  let by = calc.sin(angle) / d

  return (cx + bx, cy + by, cz)
*/
}

/// Compute the path-anchor of an ellipse
///
/// - center (vector): Rect center point
/// - anchor (float, ratio, length): Distance
/// - x-radius (float): X radius
/// - y-radius (float): Y radius
/// - unit-length (length): Canvas unit length
/// -> vector
#let compute-ellipse-path(center, anchor, x-radius: 1, y-radius: 1, unit-length: 1cm) = {
  let eps = 1e-6

  let (ox, oy) = if calc.abs(x-radius - y-radius) < eps {
    _circle-point(anchor, x-radius, unit-length)
  } else {
    _lookup-ellipse-point(anchor, x-radius, y-radius, unit-length)
  }

  let (cx, cy, cz) = center
  return (cx + ox, cy + oy, cz)
}
