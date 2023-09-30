// CeTZ Library for drawing charts

#import "axes.typ"
#import "palette.typ"
#import "../util.typ"
#import "../draw.typ"
#import "../vector.typ"
#import "../bezier.typ"

#let default-colors = (blue, red, green, yellow, black)

#let default-plot-style(i) = {
  let color = default-colors.at(calc.rem(i, default-colors.len()))
  return (stroke: color,
          fill: color.lighten(75%))
}

#let default-mark-style(i) = {
  return default-plot-style(i)
}

// Compute list of linear paths for data points, clipped to
// the bounding box of [min-x, max-x][min-y, max-y].
//
// - data (array): List of (x, y) data points
// - min-x (float): Min x
// - max-x (float): Max x
// - min-y (float): Min y
// - max-y (float): Max y
#let paths-for-points(data, min-x, max-x, min-y, max-y) = {
  let in-range(p) = {
    if p == none { return false }
    let (px, py, ..) = p
    return (px >= min-x
        and px <= max-x
        and py >= min-y
        and py <= max-y)
  }

  let lin-interpolated-pt(a, b) = {
    let x1 = a.at(0)
    let y1 = a.at(1)
    let x2 = b.at(0)
    let y2 = b.at(1)

    /* Special case for vertical lines */
    if x2 - x1 == 0 {
      return (x2, calc.min(max-y, calc.max(y2, min-y)))
    }

    if y2 - y1 == 0 {
      return (calc.min(max-x, calc.max(x2, min-x)), y2)
    }

    let m = (y2 - y1) / (x2 - x1)
    let n = y2 - m * x2

    let x = x2
    let y = y2

    y = calc.min(max-y, calc.max(y, min-y))
    x = (y - n) / m

    x = calc.min(max-x, calc.max(x, min-x))
    y = m * x + n

    return (x, y)
  }

  let paths = ()

  let path = ()
  let prev-p = none
  for p in data {
    if p == none { continue }

    let (px, py, ..) = p
    if px == none or py == none { continue }

    if in-range(p) {
      if not in-range(prev-p) and prev-p != none {
        path.push(lin-interpolated-pt(p, prev-p))
      }

      path.push(p)
    } else {
      if in-range(prev-p) {
        path.push(lin-interpolated-pt(prev-p, p))
      } else if prev-p != none {
        let a = lin-interpolated-pt(p, prev-p)
        let b = lin-interpolated-pt(prev-p, p)
        if in-range(a) and in-range(b) {
          path.push(a)
          path.push(b)
        }
      }

      if path.len() > 0 {
        paths.push(path)
        path = ()
      }
    }

    prev-p = p
  }

  if path.len() > 0 {
    paths.push(path)
  }
  return paths
}

/// Add data to a plot environment.
///
/// Must be called from the body of a `plot(..)` command.
///
/// - domain (array): Domain tuple of the plot. If `data` is a function,
///                   domain must be specified, as `data` is sampled
///                   for x-values in `domain`. Values must be numbers.
/// - hypograph (bool): Fill hypograph; uses the `hypograph` style key for
///                     drawing
/// - epigraph (bool): Fill epigraph; uses the `epigraph` style key for
///                    drawing
/// - fill (bool): Fill to y zero
/// - samples (int): Number of times the `data` function gets called for
///                  sampling y-values. Only used if `data` is of
///                  type function.
/// - sample-at (array): Array of x-values the function gets sampled at in addition
///                      to the default sampling.
/// - line (string, dictionary): Line type to use. The following types are
///                              supported:
///                              / `"linear"`: Linear line segments
///                              / `"spline"`: A smoothed line
///                              / `"vh"`: Move vertical and then horizontal
///                              / `"hv"`: Move horizontal and then vertical
///                              / `"vhv"`: Add a vertical step in the middle
///                              / `"raw"`: Like linear, but without linearization.
///                                `"linear"` _should_ never look different than `"raw"`.
///
///                              If the value is a dictionary, the type must be
///                              supplied via the `type` key. The following extra
///                              attributes are supported:
///                              / `"samples" <int>`: Samples of splines
///                              / `"tension" <float>`: Tension of splines
///                              / `"mid" <float>`: Mid-Point of vhv lines (0 to 1)
///                              / `"epsilon" <float>`: Linearization slope epsilon for
///                                use with `"linear"`, defaults to 0.
/// - style (style): Style to use, can be used with a palette function
/// - axes (array): Name of the axes to use ("x", "y"), note that not all
///                 plot styles are able to display a custom axis!
/// - mark (string): Mark symbol to place at each distinct value of the
///                  graph. Uses the `mark` style key of `style` for drawing.
///
///                  The following marks are supported:
///                  - `"*"` or `"x"` -- X
///                  - `"+"` -- Cross
///                  - `"|"` -- Bar
///                  - `"-"` -- Dash
///                  - `"o"` -- Circle
///                  - `"triangle"` -- Triangle
///                  - `"square"` -- Square
/// - mark-size (float): Mark size in cavas units
/// - data (array,function): Array of 2D data points (numeric) or a function
///                          of the form `x => y`, where `x` is a value
///                          insides `domain` and `y` must be numeric or
///                          a 2D vector (for parametric functions).
///
///                          *Examples*
///                          - `((0,0), (1,1), (2,-1))`
///                          - x => calc.pow(x, 2)
#let add(domain: auto,
         hypograph: false,
         epigraph: false,
         fill: false,
         style: (:),
         mark: none,
         mark-size: .2,
         mark-style: (:),
         samples: 100,
         sample-at: (),
         line: "linear",
         axes: ("x", "y"),
         data
         ) = {
  // If data is of type function, sample it
  if type(data) == function {
    assert(samples >= 2)
    assert(type(domain) == array and domain.len() == 2)

    let (lo, hi) = domain

    let y0 = (data)(lo)
    let is-vector = type(y0) == array
    if not is-vector {
      y0 = ((lo, y0), )
    } else {
      y0 = (y0, )
    }

    let pts = sample-at + range(0, samples + 1).map(t => lo + t / samples * (hi - lo))
    pts = pts.sorted()

    data = pts.map(x => {
      if is-vector {
        (data)(x)
      } else {
        (x, (data)(x))
      }
    })
  }

  // Simplify linear data by "detecting" linear sections
  // and skipping points until the slope changes.
  // This can have a huge impact on the number of lines
  // getting rendered.
  let linear-data(epsilon) = {
    let pts = ()
    // Current slope, set to none if infinite
    let dx = none
    // Previous point, last skipped point
    let prev = none
    let skipped = none
    // Current direction
    let dir = 0

    let len = data.len()
    for i in range(0, len) {
      let pt = data.at(i)
      if prev != none and i < len - 1 {
        let new-dir = pt.at(0) - prev.at(0)
        if new-dir == 0 {
          // Infinite slope
          if dx != none {
            if skipped != none {pts.push(skipped); skipped = none}
            pts.push(pt)
          } else {
            skipped = pt
          }
          dx = none
        } else {
          // Push the previous and the current point
          // if slope or direction changed
          let new-dx = ((pt.at(1) - prev.at(1)) / new-dir)
          if dx == none or calc.abs(new-dx - dx) > epsilon or (new-dir * dir) < 0 {
            if skipped != none {pts.push(skipped); skipped = none}
            pts.push(pt)

            dx = new-dx
            dir = new-dir
          } else {
            skipped = pt
          }
        }
      } else {
        if skipped != none {pts.push(skipped); skipped = none}
        pts.push(pt)
      }

      prev = pt
    }

    return pts
  }

  let spline-data(tension, samples) = {
    let curves = bezier.catmull-to-cubic(data, tension)
    let pts = ()
    for c in curves {
      for t in range(0, samples + 1) {
        let t = t / samples
        pts.push(bezier.cubic-point(..c, t))
      }
    }
    return pts
  }

  let vhv-data(t) = {
    if type(t) == ratio {
      t = t / 1%
    }
    t = calc.max(0, calc.min(t, 1))

    let pts = ()

    let len = data.len()
    for i in range(0, len) {
      pts.push(data.at(i))

      if i < len - 1 {
        let (a, b) = (data.at(i), data.at(i+1))
        if t == 0 {
          pts.push((a.at(0), b.at(1)))
        } else if t == 1 {
          pts.push((b.at(0), a.at(1)))
        } else {
          let x = a.at(0) + (b.at(0) - a.at(0)) * t
          pts.push((x, a.at(1)))
          pts.push((x, b.at(1)))
        }
      }
    }
    pts
  }

  if type(line) == str {
    line = (type: line)
  }

  let line-type = line.at("type", default: "linear")
  assert(line-type in ("raw", "linear", "spline", "vh", "hv", "vhv"))

  // Transform data into line-data
  let line-data = if line-type == "linear" {
    linear-data(line.at("epsilon", default: 0))
  } else if line-type == "spline" {
    spline-data(line.at("tension", default: .5),
                line.at("samples", default: 15))
  } else if line-type == "vh" {
    vhv-data(0)
  } else if line-type == "hv" {
    vhv-data(1)
  } else if line-type == "vhv" {
    vhv-data(line.at("mid", default: .5))
  } else {
    data
  }

  // Get x-domain
  let x-domain = (
    calc.min(..line-data.map(t => t.at(0))),
    calc.max(..line-data.map(t => t.at(0)))
  )

  // Get y-domain
  let y-domain = if line-data != none {(
    calc.min(..line-data.map(t => t.at(1))),
    calc.max(..line-data.map(t => t.at(1)))
  )}

  ((
    type: "data",
    data: data, /* Raw data */
    line-data: line-data, /* Transformed data */
    axes: axes,
    x-domain: x-domain,
    y-domain: y-domain,
    epigraph: epigraph,
    hypograph: hypograph,
    fill: fill,
    style: style,
    mark: mark,
    mark-size: mark-size,
    mark-style: mark-style,
  ),)
}

/// Add an anchor to a plot environment
///
/// - name (string): Anchor name
/// - position (array): Tuple of x and y values.
///                     Both values can have the special values "min" and
///                     "max", which resolve to the axis min/max value.
///                     Position is in axis space!
/// - axes (array): Name of the axes to use ("x", "y"), note that both
///                 axes must exist!
#let add-anchor(name, position, axes: ("x", "y")) = {
  ((
    type: "anchor",
    name: name,
    position: position,
    axes: axes,
  ),)
}

/// Create a plot environment
///
/// Note: Data for plotting must be passed via `plot.add(..)`
///
/// Note that different axis-styles can show different axes.
/// The `"school-book"` and `"left"` style shows only axis "x" and "y",
/// while the `"scientific"` style can show "x2" and "y2", if set
/// (if unset, "x2" mirrors "x" and "y2" mirrors "y"). Other
/// axes (e.G. "my-axis") work, but no ticks or labels will be shown.
///
/// *Options*
///
/// The following options are supported per axis
/// and must be prefixed by `<axis-name>-`, e.G.
/// `x-min: 0`.
/// #box[
///   - label (content): Axis label
///   - min (int): Axis minimum value
///   - max (int): Axis maximum value
///   - tick-step (float): Distance between major ticks
///   - minor-tick-step (float): Distance between minor ticks
///   - ticks (array): List of ticks values or value/label
///                    tuples. Example `(1,2,3)` or `((1, [A]), (2, [B]),)`
///   - format (string): Tick label format, `"float"`, `"sci"` (scientific)
///                      or a custom function that receives a value and
///                      returns a content (`value => content`).
///   - grid (bool,string): Enable grid-lines at tick values:
///                         - `"major"`: Enable major tick grid
///                         - `"minor"`: Enable minor tick grid
///                         - `"both"`: Enable major & minor tick grid
///                         - `false`: Disable grid
///   - unit (content): Tick label suffix
///   - decimals (int): Number of decimals digits to display for tick labels
/// ]
///
/// - body (body): Calls of `plot.add` commands
/// - size (array): Plot canvas size tuple of width and height in canvas units
/// - axis-style (string): Axis style "scientific", "left", "school-book"
///                  - `"scientific"`: Frame plot area and draw axes y, x, y2, and x2 around it
///                  - `"school-book"`: Draw axes x and y as arrows with both crossing at $(0, 0)$
///                  - `"left"`: Draw axes x and y as arrows, the y axis stays on the left (at `x.min`)
///                              and the x axis at the bottom (at `y.min`)
/// - plot-style (style,function): Style used for drawing plot graphs
///                                This style gets inherited by all plots.
/// - mark-style (style,function): Style used for drawing plot marks.
///                                This style gets inherited by all plots.
/// - name (string): Element name
/// - ..options (any): The following options are supported per axis
///                    and must be prefixed by `<axis-name>-`, e.G.
///                    `x-min: 0`.
///                    - min (int): Axis minimum
///                    - max (int): Axis maximum
///                    - tick-step (float): Major tick step
///                    - minor-tick-step (float): Major tick step
///                    - ticks (array): List of ticks values or value/label
///                                     tuples
///                    - unit (content): Tick label suffix
///                    - decimals (int): Number of decimals digits to display
#let plot(body,
          size: (1, 1),
          axis-style: "scientific",
          name: none,
          plot-style: default-plot-style,
          mark-style: default-mark-style,
          ..options
          ) = draw.group(name: name, ctx => {
  let data = ()
  let anchors = ()
  let body = if body != none { body } else { () }

  for cmd in body {
    assert(type(cmd) == dictionary and "type" in cmd,
           message: "Expected plot sub-command in plot body")
    if cmd.type == "data" { data.push(cmd) }
    if cmd.type == "anchor" { anchors.push(cmd) }
  }

  assert(axis-style in ("scientific", "school-book", "left"),
         message: "Invalid plot style")

  let axis-dict = (:)

  // Create axes for data
  for d in data {
    for (i, name) in d.axes.enumerate() {
      if not name in axis-dict {
        axis-dict.insert(name, axes.axis(
          min: none, max: none))
      }

      let axis = axis-dict.at(name)
      let domain = if i == 0 {d.x-domain} else {d.y-domain}
      axis.min = util.min(axis.min, ..domain)
      axis.max = util.max(axis.max, ..domain)

      axis-dict.at(name) = axis
    }
  }

  // Create axes for anchors
  for a in anchors {
    for (i, name) in a.axes.enumerate() {
      if not name in axis-dict {
        axis-dict.insert(name, axes.axis(min: none, max: none))
      }
    }
  }

  let options = options.named()
  let get-axis-option(axis-name, name, default) = {
    let v = options.at(axis-name + "-" + name, default: default)
    if v == auto { default } else { v }
  }

  // Set axis options
  for (name, axis) in axis-dict {
    if not "ticks" in axis { axis.ticks = () }

    axis.label = get-axis-option(name, "label", $#name$)
    axis.min = get-axis-option(name, "min", axis.min)
    axis.max = get-axis-option(name, "max", axis.max)

    axis.ticks.list = get-axis-option(name, "ticks", ())
    axis.ticks.step = get-axis-option(name, "tick-step", axis.ticks.step)
    axis.ticks.minor-step = get-axis-option(name, "minor-tick-step", axis.ticks.minor-step)
    axis.ticks.decimals = get-axis-option(name, "decimals", 2)
    axis.ticks.unit = get-axis-option(name, "unit", [])
    axis.ticks.format = get-axis-option(name, "format", axis.ticks.format)
    axis.ticks.grid = get-axis-option(name, "grid", false)

    // Sanity checks
    assert(axis.min < axis.max,
           message: "Axis min. must be < max.")

    axis-dict.at(name) = axis
  }

  // Prepare styles
  for i in range(data.len()) {
    let style-base = plot-style
    if type(style-base) == function {
      style-base = (style-base)(i)
    }
    if type(data.at(i).style) == function {
      data.at(i).style = (data.at(i).style)(i)
    }
    let mark-style-base = mark-style
    if type(mark-style-base) == function {
      mark-style-base = (mark-style-base)(i)
    }
    if type(data.at(i).mark-style) == function {
      data.at(i).mark-style = (data.at(i).mark-style)(i)
    }
    data.at(i).style = util.merge-dictionary(
      style-base, data.at(i).style)
    data.at(i).mark-style = util.merge-dictionary(
      mark-style-base, data.at(i).mark-style)
  }

  // Compute poly-lines
  for i in range(data.len()) {
    let (x, y) = data.at(i).axes.map(name => axis-dict.at(name))

    data.at(i).path = paths-for-points(
      data.at(i).line-data,
      x.min, x.max, y.min, y.max)
  }

  let stroke-segments(segments) = {
    for s in segments {
      if s != none and s.len() > 1 {
        draw.line(..s, fill: none)
      }
    }
  }

  let draw-marks(pts, x, y, mark, mark-size) = {
    // Scale marks back to canvas scaling
    let (sx, sy) = size
    sx = (x.max - x.min) / sx
    sy = (y.max - y.min) / sy
    sx *= mark-size
    sy *= mark-size

    let bl(pt) = (rel: (-sx/2, -sy/2), to: pt)
    let br(pt) = (rel: (sx/2, -sy/2), to: pt)
    let tl(pt) = (rel: (-sx/2, sy/2), to: pt)
    let tr(pt) = (rel: (sx/2, sy/2), to: pt)
    let ll(pt) = (rel: (-sx/2, 0), to: pt)
    let rr(pt) = (rel: (sx/2, 0), to: pt)
    let tt(pt) = (rel: (0, sy/2), to: pt)
    let bb(pt) = (rel: (0, -sy/2), to: pt)

    let draw-mark = (
      if mark == "o" {
        draw.circle.with(radius: (sx/2, sy/2))
      } else
      if mark == "square" {
        pt => { draw.rect(bl(pt), tr(pt)) }
      } else
      if mark == "triangle" {
        pt => { draw.line(bl(pt), br(pt), tt(pt), close: true) }
      } else
      if mark == "*" or mark == "x" {
        pt => { draw.line(bl(pt), tr(pt));
                draw.line(tl(pt), br(pt)) }
      } else
      if mark == "+" {
        pt => { draw.line(ll(pt), rr(pt));
                draw.line(tt(pt), bb(pt)) }
      } else
      if mark == "-" {
        pt => { draw.line(ll(pt), rr(pt)) }
      } else
      if mark == "|" {
        pt => { draw.line(tt(pt), bb(pt)) }
      }
    )

    for pt in pts {
      let (px, py, ..) = pt
      if px >= x.min and px <= x.max and py >= y.min and py <= y.max {
        draw-mark(pt)
      }
    }
  }

  let fill-segments-to(segments, to) = {
    for s in segments {
      let origin = (s.first().at(0), to)
      let target = (s.last().at(0), to)

      draw.line(origin, ..s, target, stroke: none)
    }
  }

  // Fill epi-/hypo-graph
  for d in data {
    let (x, y) = d.axes.map(name => axis-dict.at(name))
    axes.axis-viewport(size, x, y, {
      draw.anchor("center", (0, 0))
      draw.set-style(..d.style)

      if d.at("hypograph", default: false) {
        fill-segments-to(d.path, y.min)
      }
      if d.at("epigraph", default: false) {
        fill-segments-to(d.path, y.max)
      }
      if d.at("fill", default: false) {
        fill-segments-to(d.path, calc.max(calc.min(y.max, 0), y.min))
      }
    })
  }

  if axis-style == "scientific" {
    axes.scientific(
      size: size,
      bottom: axis-dict.at("x", default: none),
      top: axis-dict.at("x2", default: auto),
      left: axis-dict.at("y", default: none),
      right: axis-dict.at("y2", default: auto),)
  } else if axis-style == "left" {
    axes.school-book(
      size: size,
      axis-dict.x,
      axis-dict.y,
      x-position: axis-dict.y.min,
      y-position: axis-dict.x.min)
  } else if axis-style == "school-book" {
    axes.school-book(
      size: size,
      axis-dict.x,
      axis-dict.y,)
  }

  // Stroke + Mark data
  for d in data {
    let (x, y) = d.axes.map(name => axis-dict.at(name))
    axes.axis-viewport(size, x, y, {
      draw.set-style(..d.style)
      stroke-segments(d.path)
    })
    if d.mark != none {
      axes.axis-viewport(size, x, y, {
        draw.set-style(..d.style, ..d.mark-style)
        draw-marks(d.data, x, y, d.mark, d.mark-size)
      })
    }
  }

  // Place anchors
  for a in anchors {
    let (x, y) = a.axes.map(name => axis-dict.at(name))
    assert(x != none, message: "Axis " + name + " does not exist")
    assert(y != none, message: "Axis " + name + " does not exist")
    axes.axis-viewport(name: "anchors", size, x, y, {
      let (ax, ay) = a.position
      if ax == "min" {ax = x.min} else if ax == "max" {ax = x.max}
      if ay == "min" {ay = y.min} else if ay == "max" {ay = y.max}
      draw.anchor("default", (0,0))
      draw.anchor(a.name, (ax, ay))
    })
    draw.copy-anchors("anchors", filter: (a.name,))
  }
})
