// CeTZ Library for drawing charts

#import "axes.typ"
#import "palette.typ"
#import "../util.typ"
#import "../draw.typ"
#import "../vector.typ"

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
///                          insides `domain` and `y` must be numeric.
///
///                          *Examples*
///                          - `((0,0), (1,1), (2,-1))`
///                          - x => calc.pow(x, 2)
#let add(domain: auto,
         hypograph: false,
         epigraph: false,
         fill: false,
         mark: none,
         mark-size: .2,
         samples: 100,
         style: (stroke: black, fill: gray),
         mark-style: (stroke: black, fill: none),
         axes: ("x", "y"),
         data
         ) = {
  // If data is of type function, sample it
  if type(data) == "function" {
    assert(samples >= 2)
    assert(type(domain) == "array" and domain.len() == 2)

    let (lo, hi) = domain
    data = range(0, samples + 1).map(x => {
      let x = lo + x / samples * (hi - lo)
      (x, (data)(x))
    })
  }

  // If data is not of type function, auto set domain
  if domain == auto or domain.at(0) == auto or domain.at(1) == auto {
    let (lo, hi) = (
      calc.min(..data.map(t => t.at(0))),
      calc.max(..data.map(t => t.at(0)))
    )
    if domain == auto {
      domain = (lo, hi)
    } else if domain.at(0) == auto {
      domain.at(0) = lo
    } else if domain.at(1) == auto {
      domain.at(1) = hi
    }
  }

  // Get y-domain
  let y-domain = (
    calc.min(..data.map(t => t.at(1))),
    calc.max(..data.map(t => t.at(1)))
  )

  ((
    data: data,
    axes: axes,
    x-domain: domain,
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

/// Create a plot environment
///
/// Note: Data for plotting must be passed via `plot.add(..)`
///
/// Note that different axis-styles can show different axes.
/// The `"school-book"` style shows only axis "x" and "y", while
/// the `"scientific"` style can show "x2" and "y2", if set
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
///   - format (string): Tick label format, `"float"` or `"sci"` (scientific)
///   - unit (content): Tick label suffix
///   - decimals (int): Number of decimals digits to display for tick labels
/// ]
///
/// - body (body): Calls of `plot.add` commands
/// - size (array): Plot canvas size tuple of width and height in canvas units
/// - axis-style (string): Axis style "scientific" or "school-book"
/// - options (any): The following options are supported per axis
///                  and must be prefixed by `<axis-name>-`, e.G.
///                  `x-min: 0`.
///                  - min (int): Axis minimum
///                  - max (int): Axis maximum
///                  - tick-step (float): Major tick step
///                  - minor-tick-step (float): Major tick step
///                  - ticks (array): List of ticks values or value/label
///                                   tuples
///                  - unit (content): Tick label suffix
///                  - decimals (int): Number of decimals digits to display
#let plot(body,
          size: (1, 1),
          axis-style: "scientific",
          ..options
          ) = {
  let data = body

  assert(axis-style in ("scientific", "school-book"),
         message: "Invalid plot style")

  // Create axes
  let axis-dict = (:)
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

    axis-dict.at(name) = axis
  }

  // Prepare styles
  for i in range(data.len()) {
    if type(data.at(i).style) == "function" {
      data.at(i).style = (data.at(i).style)(i)
    }
    if type(data.at(i).mark-style) == "function" {
      data.at(i).mark-style = (data.at(i).mark-style)(i)
    }
  }

  // Compute poly-lines
  for i in range(data.len()) {
    let (x, y) = data.at(i).axes.map(name => axis-dict.at(name))
    data.at(i).path = paths-for-points(data.at(i).data,
      x.min, x.max, y.min, y.max)
  }

  let stroke-segments(segments) = {
    for s in segments {
      draw.line(..s, fill: none)
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
        fill-segments-to(d.path, 0)
      }
    })
  }

  if axis-style == "scientific" {
    axes.scientific(
      size: size,
      bottom: axis-dict.x,
      top: axis-dict.at("x2", default: auto),
      left: axis-dict.y,
      right: axis-dict.at("y2", default: auto),)
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
}
