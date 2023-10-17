#import "util.typ"
#import "sample.typ"
#import "/src/draw.typ"

// Find contours of a 2D array by using marching squares algorithm
//
// - data (array): 2D float array (rows => columns)
// - offset (float): Value (offset) a cell must be greater or equal to to count as true
// - interpolate (bool): Enable cell interpolation for smoother lines
// - contour-limit (int): Contour limit after which the algorithm panics
// -> array: Array of contour point arrays
#let find-contours(data, offset, interpolate: true, contour-limit: 50) = {
  assert(data != none)
  assert(type(data) == array)
  assert(type(offset) in (int, float))

  let n-rows = data.len()
  let n-cols = data.at(0).len()
  if n-rows < 2 or n-cols < 2 {
    return ()
  }

  // Return if data is set
  let is-set(v) = {
    return if offset < 0 {
      v <= offset
    } else {
      v >= offset
    }
  }

  // Build a binary map that has 0 for unset and 1 for set cells
  let bin-data = data.map(r => r.map(is-set))

  // Get binary data at x, y
  let get-bin(x, y) = {
    if x >= 0 and x < n-cols and y >= 0 and y < n-rows {
      return bin-data.at(y).at(x)
    }
    return false
  }

  // Get data point for x, y coordinate
  let get-data(x, y) = {
    if x >= 0 and x < n-cols and y >= 0 and y < n-rows {
      return float(data.at(y).at(x))
    }
    return 0
  }

  // Get case (0 to 15)
  let get-case(tl, tr, bl, br) = {
    let case = int(tl) * 1000 + int(tr) * 100 + int(bl) * 10 + int(br)
    return if case == 0000 {  0 }
      else if case == 0010 {  1 }
      else if case == 0001 {  2 }
      else if case == 0011 {  3 }
      else if case == 0100 {  4 }
      else if case == 0110 {  5 }
      else if case == 0101 {  6 }
      else if case == 0111 {  7 }
      else if case == 1000 {  8 }
      else if case == 1010 {  9 }
      else if case == 1001 { 10 }
      else if case == 1011 { 11 }
      else if case == 1100 { 12 }
      else if case == 1110 { 13 }
      else if case == 1101 { 14 }
      else if case == 1111 { 15 }
  }

  let lerp(a, b) = {
    if a == b { return a }
    return (offset - a) / (b - a)
  }

  // List of all found contours
  let contours = ()

  let segments = ()
  for y in range(-1, n-rows) {
    for x in range(-1, n-cols) {
      let tl = get-bin(x, y)
      let tr = get-bin(x+1, y)
      let bl = get-bin(x, y+1)
      let br = get-bin(x+1, y+1)

      // Corner data
      // 
      // nw-----ne
      // |       |
      // |       |
      // |       |
      // sw-----se
      let nw = get-data(x, y)
      let ne = get-data(x+1, y)
      let se = get-data(x+1, y+1)
      let sw = get-data(x, y+1)

      // Interpolated edge points
      //
      // +-- a --+
      // |       |
      // d       b
      // |       |
      // +-- c --+
      let a = (x + .5, y)
      let b = (x + 1, y + .5)
      let c = (x + .5, y + 1)
      let d = (x, y + .5)
      if interpolate {
        a = (x + lerp(nw, ne), y)
        b = (x + 1, y + lerp(ne, se))
        c = (x + lerp(sw, se), y + 1)
        d = (x, y + lerp(nw, sw))
      }

      let case = get-case(tl, tr, bl, br)
      if case in (1, 14) {
        segments.push((d, c))
      } else if case in (2, 13) {
        segments.push((b, c))
      } else if case in (3, 12) {
        segments.push((d, b))
      } else if case in (4, 11) {
        segments.push((a, b))
      } else if case == 5 {
        segments.push((d, a))
        segments.push((c, b))
      } else if case in (6, 9) {
        segments.push((c, a))
      } else if case in (7, 8) {
        segments.push((d, a))
      } else if case == 10 {
        segments.push((a, b))
        segments.push((c, d))
      }
    }
  }

  // Join lines to one or more contours
  // This is done by searching for the next line
  // that starts at the current contours head or tail
  // point. If found, push the other coordinate to
  // the contour. If no line could be found, push a
  // new contour.
  let contours = ()
  while segments.len() > 0 {
    if contours.len() == 0 {
      contours.push(segments.remove(0))
    }

    let found = false

    let i = 0
    while i < segments.len() {
      let (a, b) = segments.at(i)
      let (h, t) = (contours.last().first(),
                    contours.last().last())
      if a == t {
        contours.last().push(b)
        segments.remove(i)
        found = true
      } else if b == t {
        contours.last().push(a)
        segments.remove(i)
        found = true
      } else if a == h {
        contours.last().insert(0, b)
        segments.remove(i)
        found = true
      } else if b == h {
        contours.last().insert(0, a)
        segments.remove(i)
        found = true
      } else {
        i += 1
      }
    }

    // Insert the next contour
    if not found {
      contours.push(segments.remove(0))
    }

    // Check limit
    assert(contours.len() <= contour-limit,
      message: "Countour limit reached! Raise contour-limit if you " +
                "think this is not an error")
  }

  return contours
}

// Prepare line data
#let _prepare(self, ctx) = {
  let (x, y) = (ctx.x, ctx.y)

  self.contours = self.contours.map(c => {
    c.stroke-paths = util.compute-stroke-paths(c.line-data,
      (x.min, y.min), (x.max, y.max))

    if self.fill {
      c.fill-paths = util.compute-fill-paths(c.line-data,
        (x.min, y.min), (x.max, y.max))
    }
    return c
  })

  return self
}

// Stroke line data
#let _stroke(self, ctx) = {
  for c in self.contours {
    for p in c.stroke-paths {
      draw.line(..p, fill: none)
    }
  }
}

// Fill line data
#let _fill(self, ctx) = {
  if not self.fill { return }
  for c in self.contours {
    for p in c.fill-paths {
      draw.line(..p, stroke: none)
    }
  }
}

/// Add a contour plot of a sampled function or a matrix.
///
/// - data (array, function): Matrix or `(x, y) => z` function
///
///                           *Examples:*
///                           - `(x, y) => x > 0`
///                           - `(x, y) => 30 - (calc.pow(1 - x, 2)+calc.pow(1 - y, 2))`
/// - z (float, array): Z values to plot. Contours containing values
///                     above z (z >= 0) or below z (z < 0) get plotted.
///                     If you specify multiple z values, they get plotted in order.
/// - x-domain (array): X axis domain tuple (min, max)
/// - y-domain (array): Y axis domain tuple (min, max)
/// - x-samples (int): X axis domain samples (2 < n)
/// - y-samples (int): Y axis domain samples (2 < n)
/// - interpolate (bool): Use linear interpolation between sample values
/// - fill (bool): Fill each contour
/// - style (style): Style to use, can be used with a palette function
/// - axes (array): Name of the axes to use ("x", "y"), note that not all
///                 plot styles are able to display a custom axis!
/// - limit (int): Limit of contours to create per z value before the function panics
#let add-contour(data,
                 z: (1,),
                 x-domain: (0, 1),
                 y-domain: (0, 1),
                 x-samples: 25,
                 y-samples: 25,
                 interpolate: true,
                 axes: ("x", "y"),
                 style: (:),
                 fill: false,
                 limit: 50,
  ) = {
  // Sample a x/y function
  if type(data) == function {
    data = sample.sample-fn2(data,
                             x-domain, y-domain,
                             x-samples, y-samples)
  }

  // Find matrix dimensions
  assert(type(data) == array)
  let (x-min, x-max) = x-domain
  let dx = (x-max - x-min) / (data.at(0).len() - 1)
  let (y-min, y-max) = y-domain
  let dy = (y-max - y-min) / (data.len() - 1)

  let contours = ()
  let z = if type(z) == array { z } else { (z,) }
  for z in z {
    for contour in find-contours(data, z, interpolate: interpolate) {
      let line-data = contour.map(pt => {
        (pt.at(0) * dx + x-min,
         pt.at(1) * dy + y-min)
      })

      contours.push((
        z: z,
        line-data: line-data,
      ))
    }
  }

  return ((
    type: "contour",
    contours: contours,
    axes: axes,
    x-domain: x-domain,
    y-domain: y-domain,
    style: style,
    fill: fill,
    mark: none,
    mark-style: none,
    plot-prepare: _prepare,
    plot-stroke: _stroke,
    plot-fill: _fill,
  ),)
}
