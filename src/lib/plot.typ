// CeTZ Library for drawing plots
#import "axes.typ"
#import "palette.typ"
#import "../util.typ"
#import "../draw.typ"

#import "plot/sample.typ": sample-fn, sample-fn2
#import "plot/line.typ": add, add-hline, add-vline
#import "plot/contour.typ": add-contour
#import "plot/boxwhisker.typ": add-boxwhisker

#import "../draw.typ"
#import "../vector.typ"
#import "../matrix.typ"
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

// Get the default axis orientation
// depending on the axis name
#let get-default-axis-horizontal(name) = {
  return lower(name).starts-with("x")
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
/// `x-min: 0` or `y-label: [y]`.
/// #box[
///   - label (content): Axis label
///   - min (int): Axis minimum value
///   - max (int): Axis maximum value
///   - tick-step (none, float): Distance between major ticks (or no ticks if none)
///   - minor-tick-step (none, float): Distance between minor ticks (or no ticks if none)
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
///   - unit (none, content): Tick label suffix
///   - decimals (int): Number of decimals digits to display for tick labels
/// ]
///
/// - body (body): Calls of `plot.add` or `plot.add-*` commands
/// - size (array): Plot canvas size tuple of width and height in canvas units
/// - axis-style (none, string): Axis style "scientific", "left", "school-book"
///     - `"scientific"`: Frame plot area and draw axes y, x, y2, and x2 around it
///     - `"school-book"`: Draw axes x and y as arrows with both crossing at $(0, 0)$
///     - `"left"`: Draw axes x and y as arrows, the y axis stays on the left (at `x.min`)
///                 and the x axis at the bottom (at `y.min`)
///     - `none`: Draw no axes (and no ticks).
/// - plot-style (style,function): Style used for drawing plot graphs
///                                This style gets inherited by all plots.
/// - mark-style (style,function): Style used for drawing plot marks.
///                                This style gets inherited by all plots.
/// - fill-below (bool): Fill functions below the axes (draw axes above fills)
/// - name (string): Element name
/// - ..options (any): The following options are supported per axis
///                    and must be prefixed by `<axis-name>-`, e.G.
///                    `x-min: 0`.
///                    - min (int): Axis minimum
///                    - max (int): Axis maximum
///                    - horizontal (bool): Axis orientation; note that each
///                      plot must use one vertical and one horizontal axis!
///                      The default value for this parameter is guessed: Axes
///                      starting with "x" are considered horizontal by default.
///                      This does not affect the side the ticks of the axis are
///                      drawn, but only the drawing direction.
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
          fill-below: true,
          ..options
          ) = draw.group(name: name, ctx => {
  import "plot/mark.typ"

  // Create plot context object
  let make-ctx(x, y, size) = {
    assert(x != none, message: "X axis does not exist")
    assert(y != none, message: "Y axis does not exist")

    return (x: x, y: y, size: size)
  }

  // Setup data viewport
  let data-viewport(data, x, y, size, body, name: none) = {
    if body == none or body == () { return }

    assert.ne(x.horizontal, y.horizontal,
      message: "Data must use one horizontal and one vertical axis!")

    // If y is the horizontal axis, swap x and y
    // coordinates by swapping the transformation
    // matrix columns.
    if y.horizontal {
      (x, y) = (y, x)
      body = draw.set-ctx(ctx => {
        ctx.transform = matrix.swap-cols(ctx.transform, 0, 1)
        return ctx
      }) + body
    }

    // Setup the viewport
    axes.axis-viewport(size, x, y, body, name: name)
  }

  let data = ()
  let anchors = ()
  let body = if body != none { body } else { () }

  for cmd in body {
    assert(type(cmd) == dictionary and "type" in cmd,
           message: "Expected plot sub-command in plot body")
    if cmd.type == "anchor" { anchors.push(cmd) } else { data.push(cmd) }
  }

  assert(axis-style in (none, "scientific", "school-book", "left"),
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
      let domain = if i == 0 {
        d.at("x-domain", default: (0, 0))
      } else {
        d.at("y-domain", default: (0, 0))
      }
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

    // Configure axis bounds
    axis.min = get-axis-option(name, "min", axis.min)
    axis.max = get-axis-option(name, "max", axis.max)

    assert(axis.min not in (none, auto) and
           axis.max not in (none, auto),
      message: "Axis min and max must be set.")
    if axis.min == axis.max {
      axis.min -= 1; axis.max += 1
    }

    // Configure axis orientation
    axis.horizontal = get-axis-option(name, "horizontal",
      get-default-axis-horizontal(name))

    // Configure ticks
    axis.ticks.list = get-axis-option(name, "ticks", ())
    axis.ticks.step = get-axis-option(name, "tick-step", axis.ticks.step)
    axis.ticks.minor-step = get-axis-option(name, "minor-tick-step", axis.ticks.minor-step)
    axis.ticks.decimals = get-axis-option(name, "decimals", 2)
    axis.ticks.unit = get-axis-option(name, "unit", [])
    axis.ticks.format = get-axis-option(name, "format", axis.ticks.format)

    // Configure grid
    axis.ticks.grid = get-axis-option(name, "grid", false)

    axis-dict.at(name) = axis
  }

  // Set axis options round two, after setting
  // axis bounds
  for (name, axis) in axis-dict {
    let changed = false

    // Configure axis aspect ratio
    let equal-to = get-axis-option(name, "equal", none)
    if equal-to != none {
      assert.eq(type(equal-to), str,
        message: "Expected axis name.")
      assert(equal-to != name,
        message: "Axis can not be equal to itself.")

      let other = axis-dict.at(equal-to, default: none)
      assert(other != none,
        message: "Other axis must exist.")
      assert(other.horizontal != axis.horizontal,
        message: "Equal axes must have opposing orientation.")

      let (w, h) = size
      let ratio = if other.horizontal {
        h / w
      } else {
        w / h
      }
      axis.min = other.min * ratio
      axis.max = other.max * ratio

      changed = true
    }

    if changed {
      axis-dict.at(name) = axis
    }
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
    data.at(i).style = util.merge-dictionary(
      style-base, data.at(i).style)

    if "mark-style" in data.at(i) {
      let mark-style-base = mark-style
      if type(mark-style-base) == function {
        mark-style-base = (mark-style-base)(i)
      }
      if type(data.at(i).mark-style) == function {
        data.at(i).mark-style = (data.at(i).mark-style)(i)
      }
      data.at(i).mark-style = util.merge-dictionary(
        mark-style-base, data.at(i).mark-style)
    }
  }

  // Prepare
  for i in range(data.len()) {
    let (x, y) = data.at(i).axes.map(name => axis-dict.at(name))
    let plot-ctx = make-ctx(x, y, size)

    if "plot-prepare" in data.at(i) {
      data.at(i) = (data.at(i).plot-prepare)(data.at(i), plot-ctx)
    }
  }

  // Fill
  if fill-below {
    for d in data {
      let (x, y) = d.axes.map(name => axis-dict.at(name))
      let plot-ctx = make-ctx(x, y, size)

      data-viewport(d, x, y, size, {
        draw.anchor("center", (0, 0))
        draw.set-style(..d.style)

        if "plot-fill" in d {
          (d.plot-fill)(d, plot-ctx)
        }
      })
    }
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
    let plot-ctx = make-ctx(x, y, size)

    data-viewport(d, x, y, size, {
      draw.anchor("center", (0, 0))
      draw.set-style(..d.style)

      if not fill-below and "plot-fill" in d {
        (d.plot-fill)(d, plot-ctx)
      }
      if "plot-stroke" in d {
        (d.plot-stroke)(d, plot-ctx)
      }
      if "mark" in d and d.mark != none {
        draw.set-style(..d.style, ..d.mark-style)
        mark.draw-mark(d.data, x, y, d.mark, d.mark-size, size)
      }
    })
  }

  // Place anchors
  for a in anchors {
    let (x, y) = a.axes.map(name => axis-dict.at(name))
    let plot-ctx = make-ctx(x, y, size)

    data-viewport(a, x, y, size, {
      let (ax, ay) = a.position
      if ax == "min" {ax = x.min} else if ax == "max" {ax = x.max}
      if ay == "min" {ay = y.min} else if ay == "max" {ay = y.max}
      draw.anchor("default", (0,0))
      draw.anchor(a.name, (ax, ay))
    }, name: "anchors")
    draw.copy-anchors("anchors", filter: (a.name,))
  }
})
