// CeTZ Library for drawing graph axes
#import "/src/util.typ"
#import "/src/draw.typ"
#import "/src/vector.typ"
#import "/src/styles.typ"
#import "/src/process.typ"
#import "/src/drawable.typ"
#import "/src/path-util.typ"

#let typst-content = content

/// Default axis style
///
/// #show-parameter-block("tick-limit", "int", default: 100, [Upper major tick limit.])
/// #show-parameter-block("minor-tick-limit", "int", default: 1000, [Upper minor tick limit.])
/// #show-parameter-block("auto-tick-factors", "array", [List of tick factors used for automatic tick step determination.])
/// #show-parameter-block("auto-tick-count", "int", [Number of ticks to generate by default.])
/// #show-parameter-block("stroke", "stroke", [Axis stroke style.])
/// #show-parameter-block("label.offset", "number", [Distance to move axis labels away from the axis.])
/// #show-parameter-block("label.anchor", "anchor", [Anchor of the axis label to use for it's placement.])
/// #show-parameter-block("label.angle", "angle", [Angle of the axis label.])
/// #show-parameter-block("axis-layer", "float", [Layer to draw axes on (see @@on-layer() )])
/// #show-parameter-block("grid-layer", "float", [Layer to draw the grid on (see @@on-layer() )])
/// #show-parameter-block("background-layer", "float", [Layer to draw the background on (see @@on-layer() )])
/// #show-parameter-block("padding", "number", [Extra distance between axes and plotting area. For schoolbook axes, this is the length of how much axes grow out of the plotting area.])
/// #show-parameter-block("overshoot", "number", [School-book style axes only: Extra length to add to the end (right, top) of axes.])
/// #show-parameter-block("tick.stroke", "stroke", [Major tick stroke style.])
/// #show-parameter-block("tick.minor-stroke", "stroke", [Minor tick stroke style.])
/// #show-parameter-block("tick.offset", ("number", "ratio"), [Major tick offset along the tick's direction, can be relative to the length.])
/// #show-parameter-block("tick.minor-offset", ("number", "ratio"), [Minor tick offset along the tick's direction, can be relative to the length.])
/// #show-parameter-block("tick.length", ("number"), [Major tick length.])
/// #show-parameter-block("tick.minor-length", ("number", "ratio"), [Minor tick length, can be relative to the major tick length.])
/// #show-parameter-block("tick.label.offset", ("number"), [Major tick label offset away from the tick.])
/// #show-parameter-block("tick.label.angle", ("angle"), [Major tick label angle.])
/// #show-parameter-block("tick.label.anchor", ("anchor"), [Anchor of major tick labels used for positioning.])
/// #show-parameter-block("tick.label.show", ("auto", "bool"), default: auto, [Set visibility of tick labels. A value of `auto` shows tick labels for all but mirrored axes.])
/// #show-parameter-block("grid.stroke", "stroke", [Major grid line stroke style.])
/// #show-parameter-block("break-point.width", "number", [Axis break width along the axis.])
/// #show-parameter-block("break-point.length", "number", [Axis break length.])
/// #show-parameter-block("minor-grid.stroke", "stroke", [Minor grid line stroke style.])
/// #show-parameter-block("shared-zero", ("bool", "content"), default: "$0$", [School-book style axes only: Content to display at the plots origin (0,0). If set to `false`, nothing is shown. Having this set, suppresses auto-generated ticks for $0$!])
#let default-style = (
  tick-limit: 100,
  minor-tick-limit: 1000,
  auto-tick-factors: (1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10), // Tick factor to try
  auto-tick-count: 11,  // Number of ticks the plot tries to place
  fill: none,
  stroke: auto,
  label: (
    offset: .2cm,       // Axis label offset
    anchor: auto,       // Axis label anchor
    angle:  auto,       // Axis label angle
  ),
  axis-layer: 0,
  grid-layer: 0,
  background-layer: 0,
  padding: 0,
  tick: (
    fill: none,
    stroke: black + 1pt,
    minor-stroke: black + .5pt,
    offset: 0,
    minor-offset: 0,
    length: .1cm,       // Tick length: Number
    minor-length: 70%,  // Minor tick length: Number, Ratio
    label: (
      offset: .15cm,    // Tick label offset
      angle:  0deg,     // Tick label angle
      anchor: auto,     // Tick label anchor
      "show": auto,     // Show tick labels for axes in use
    )
  ),
  break-point: (
    width: .75cm,
    length: .15cm,
  ),
  grid: (
    stroke: (paint: gray.lighten(50%), thickness: 1pt),
  ),
  minor-grid: (
    stroke: (paint: gray.lighten(50%), thickness: .5pt),
  ),
)

// Default Scientific Style
#let default-style-scientific = util.merge-dictionary(default-style, (
  left:   (tick: (label: (anchor: "east"))),
  bottom: (tick: (label: (anchor: "north"))),
  right:  (tick: (label: (anchor: "west"))),
  top:    (tick: (label: (anchor: "south"))),
  stroke: (cap: "square"),
  padding: 0,
))

#let default-style-schoolbook = util.merge-dictionary(default-style, (
  x: (stroke: auto, fill: none, mark: (start: none, end: "straight"),
    tick: (label: (anchor: "north"))),
  y: (stroke: auto, fill: none, mark: (start: none, end: "straight"),
    tick: (label: (anchor: "east"))),
  label: (offset: .1cm),
  origin: (label: (offset: .05cm)),
  padding: .1cm,   // Axis padding on both sides outsides the plotting area
  overshoot: .5cm, // Axis end "overshoot" out of the plotting area
  tick: (
    offset: -50%,
    minor-offset: -50%,
    length: .2cm,
    minor-length: 70%,
  ),
  shared-zero: $0$, // Show zero tick label at (0, 0)
))

#let _prepare-style(ctx, style) = {
  if type(style) != dictionary { return style }

  let res = util.resolve-number.with(ctx)
  let rel-to(v, to) = {
    if type(v) == ratio {
      return v * to / 100%
    } else {
      return res(v)
    }
  }

  style.tick.length = res(style.tick.length)
  style.tick.offset = rel-to(style.tick.offset, style.tick.length)
  style.tick.minor-length = rel-to(style.tick.minor-length, style.tick.length)
  style.tick.minor-offset = rel-to(style.tick.minor-offset, style.tick.minor-length)
  style.tick.label.offset = res(style.tick.label.offset)

  // Break points
  style.break-point.width = res(style.break-point.width)
  style.break-point.length = res(style.break-point.length)

  // Padding
  style.padding = res(style.padding)

  if "overshoot" in style {
    style.overshoot = res(style.overshoot)
  }

  return style
}

#let _get-axis-style(ctx, style, name) = {
  if not name in style {
    return style
  }

  style = styles.resolve(style, merge: style.at(name))
  return _prepare-style(ctx, style)
}

#let _get-grid-type(axis) = {
  let grid = axis.ticks.at("grid", default: false)
  if grid == "major" or grid == true { return 1 }
  if grid == "minor" { return 2 }
  if grid == "both" { return 3 }
  return 0
}

#let _inset-axis-points(ctx, style, axis, start, end) = {
  if axis == none { return (start, end) }

  let (low, high) = axis.inset.map(v => util.resolve-number(ctx, v))

  let is-horizontal = start.at(1) == end.at(1)
  if is-horizontal {
    start = vector.add(start, (low, 0))
    end = vector.sub(end, (high, 0))
  } else {
    start = vector.add(start, (0, low))
    end = vector.sub(end, (0, high))
  }
  return (start, end)
}

#let _draw-axis-line(start, end, axis, is-horizontal, style) = {
  let enabled = if axis != none and axis.show-break {
    axis.min > 0 or axis.max < 0
  } else { false }

  if enabled {
    let size = if is-horizontal {
      (style.break-point.width, 0)
    } else {
      (0, style.break-point.width, 0)
    }

    let up = if is-horizontal {
      (0, style.break-point.length)
    } else {
      (style.break-point.length, 0)
    }

    let add-break(is-end) = {
      let a = ()
      let b = (rel: vector.scale(size, .3), update: false)
      let c = (rel: vector.add(vector.scale(size, .4), vector.scale(up, -1)), update: false)
      let d = (rel: vector.add(vector.scale(size, .6), vector.scale(up, +1)), update: false)
      let e = (rel: vector.scale(size, .7), update: false)
      let f = (rel: size)

      let mark = if is-end {
        style.at("mark", default: none)
      }
      draw.line(a, b, c, d, e, f, stroke: style.stroke, mark: mark)
    }

    draw.merge-path({
      draw.move-to(start)
      if axis.min > 0 {
        add-break(false)
        draw.line((rel: size, to: start), end, mark: style.at("mark", default: none))
      } else if axis.max < 0 {
        draw.line(start, (rel: vector.scale(size, -1), to: end))
        add-break(true)
      }
    }, stroke: style.stroke)
  } else {
    draw.line(start, end, stroke: style.stroke, mark: style.at("mark", default: none))
  }
}

// Construct Axis Object
//
// - min (number): Minimum value
// - max (number): Maximum value
// - ticks (dictionary): Tick settings:
//     - step (number): Major tic step
//     - minor-step (number): Minor tic step
//     - unit (content): Tick label suffix
//     - decimals (int): Tick float decimal length
// - label (content): Axis label
#let axis(min: -1, max: 1, label: none,
          ticks: (step: auto, minor-step: none,
                  unit: none, decimals: 2, grid: false,
                  format: "float")) = (
  min: min, max: max, ticks: ticks, label: label, inset: (0, 0), show-break: false,
)

// Format a tick value
#let format-tick-value(value, tic-options) = {
  // Without it we get negative zero in conversion
  // to content! Typst has negative zero floats.
  if value == 0 { value = 0 }

  let round(value, digits) = {
    calc.round(value, digits: digits)
  }

  let format-float(value, digits) = {
    $#round(value, digits)$
  }

  let format-sci(value, digits) = {
    let exponent = if value != 0 {
      calc.floor(calc.log(calc.abs(value), base: 10))
    } else {
      0
    }

    let ee = calc.pow(10, calc.abs(exponent + 1))
    if exponent > 0 {
      value = value / ee * 10
    } else if exponent < 0 {
      value = value * ee * 10
    }

    value = round(value, digits)
    if exponent <= -1 or exponent >= 1 {
      return $#value times 10^#exponent$
    }
    return $#value$
  }

  if type(value) != typst-content {
    let format = tic-options.at("format", default: "float")
    if format == none {
      value = []
    } else if type(format) == typst-content {
      value = format
    } else if type(format) == function {
      value = (format)(value)
    } else if format == "sci" {
      value = format-sci(value, tic-options.at("decimals", default: 2))
    } else {
      value = format-float(value, tic-options.at("decimals", default: 2))
    }
  } else if type(value) != typst-content {
    value = str(value)
  }

  if tic-options.at("unit", default: none) != none {
    value += tic-options.unit
  }
  return value
}

// Get value on axis [0, 1]
//
// - axis (axis): Axis
// - v (number): Value
// -> float
#let value-on-axis(axis, v) = {
  if v == none { return }
  let (min, max) = (axis.min, axis.max)
  let dt = max - min; if dt == 0 { dt = 1 }

  return (v - min) / dt
}

// Compute list of linear ticks for axis
//
// - axis (axis): Axis
#let compute-linear-ticks(axis, style, add-zero: true) = {
  let (min, max) = (axis.min, axis.max)
  let dt = max - min; if (dt == 0) { dt = 1 }
  let ticks = axis.ticks
  let ferr = util.float-epsilon
  let tick-limit = style.tick-limit
  let minor-tick-limit = style.minor-tick-limit

  let l = ()
  if ticks != none {
    let major-tick-values = ()
    if "step" in ticks and ticks.step != none {
      assert(ticks.step >= 0,
             message: "Axis tick step must be positive and non 0.")
      if axis.min > axis.max { ticks.step *= -1 }

      let s = 1 / ticks.step

      let num-ticks = int(max * s + 1.5)  - int(min * s)
      assert(num-ticks <= tick-limit,
             message: "Number of major ticks exceeds limit " + str(tick-limit))

      let n = range(int(min * s), int(max * s + 1.5))
      for t in n {
        let v = (t / s - min) / dt
        if t / s == 0 and not add-zero { continue }

        if v >= 0 - ferr and v <= 1 + ferr {
          l.push((v, format-tick-value(t / s, ticks), true))
          major-tick-values.push(v)
        }
      }
    }

    if "minor-step" in ticks and ticks.minor-step != none {
      assert(ticks.minor-step >= 0,
             message: "Axis minor tick step must be positive")

      let s = 1 / ticks.minor-step

      let num-ticks = int(max * s + 1.5) - int(min * s)
      assert(num-ticks <= minor-tick-limit,
             message: "Number of minor ticks exceeds limit " + str(minor-tick-limit))

      let n = range(int(min * s), int(max * s + 1.5))
      for t in n {
        let v = (t / s - min) / dt
        if v in major-tick-values {
          // Prefer major ticks over minor ticks
          continue
        }

        if v != none and v >= 0 and v <= 1 + ferr {
          l.push((v, none, false))
        }
      }
    }

  }

  return l
}

// Get list of fixed axis ticks
//
// - axis (axis): Axis object
#let fixed-ticks(axis) = {
  let l = ()
  if "list" in axis.ticks {
    for t in axis.ticks.list {
      let (v, label) = (none, none)
      if type(t) in (float, int) {
        v = t
        label = format-tick-value(t, axis.ticks)
      } else {
        (v, label) = t
      }

      v = value-on-axis(axis, v)
      if v != none and v >= 0 and v <= 1 {
        l.push((v, label, true))
      }
    }
  }
  return l
}

// Compute list of axis ticks
//
// A tick triple has the format:
//   (rel-value: float, label: content, major: bool)
//
// - axis (axis): Axis object
#let compute-ticks(axis, style, add-zero: true) = {
  let find-max-n-ticks(axis, n: 11) = {
    let dt = calc.abs(axis.max - axis.min)
    let scale = calc.floor(calc.log(dt, base: 10) - 1)
    if scale > 5 or scale < -5 {return none}

    let (step, best) = (none, 0)
    for s in style.auto-tick-factors {
      s = s * calc.pow(10, scale)

      let divs = calc.abs(dt / s)
      if divs >= best and divs <= n {
        step = s
        best = divs
      }
    }
    return step
  }

  if axis == none or axis.ticks == none { return () }
  if axis.ticks.step == auto {
    axis.ticks.step = find-max-n-ticks(axis, n: style.auto-tick-count)
  }
  if axis.ticks.minor-step == auto {
    axis.ticks.minor-step = if axis.ticks.step != none {
      axis.ticks.step / 5
    } else {
      none
    }
  }

  let ticks = compute-linear-ticks(axis, style, add-zero: add-zero)
  ticks += fixed-ticks(axis)
  return ticks
}

// Prepares the axis post creation. The given axis
// must be completely set-up, including its intervall.
// Returns the prepared axis
#let prepare-axis(ctx, axis, name) = {
  let style = styles.resolve(ctx.style, root: "axes",
                             base: default-style-scientific)
  style = _prepare-style(ctx, style)
  style = _get-axis-style(ctx, style, name)

  if type(axis.inset) != array {
    axis.inset = (axis.inset, axis.inset)
  }

  axis.inset = axis.inset.map(v => util.resolve-number(ctx, v))

  if axis.show-break {
    if axis.min > 0 {
      axis.inset.at(0) += style.break-point.width
    } else if axis.max < 0 {
      axis.inset.at(1) += style.break-point.width
    }
  }

  return axis
}

// Draw inside viewport coordinates of two axes
//
// - size (vector): Axis canvas size (relative to origin)
// - origin (coordinates): Axis Canvas origin
// - x (axis): Horizontal axis
// - y (axis): Vertical axis
// - name (string,none): Group name
#let axis-viewport(size, x, y, origin: (0, 0), name: none, body) = {
  draw.group(name: name, ctx => {
    let origin = origin
    let size = size

    origin.at(0) += x.inset.at(0)
    size.at(0) -= x.inset.sum()
    origin.at(1) += y.inset.at(0)
    size.at(1) -= y.inset.sum()

    size = (rel: size, to: origin)
    draw.set-viewport(origin, size,
      bounds: (x.max - x.min,
               y.max - y.min,
               0))
    draw.translate((-x.min, -y.min))
    body
  })
}

// Draw grid lines for the ticks of an axis
//
// - cxt (context):
// - axis (dictionary): The axis
// - ticks (array): The computed ticks
// - low (vector): Start position of a grid-line at tick 0
// - high (vector): End position of a grid-line at tick 0
// - dir (vector): Normalized grid direction vector along the grid axis
// - style (style): Axis style
#let draw-grid-lines(ctx, axis, ticks, low, high, dir, style) = {
  let offset = (0,0)
  if axis.inset != none {
    let (inset-low, inset-high) = axis.inset.map(v => util.resolve-number(ctx, v))
    offset = vector.scale(vector.norm(dir), inset-low)
    dir = vector.sub(dir, vector.scale(vector.norm(dir), inset-low + inset-high))
  }

  let kind = _get-grid-type(axis)
  if kind > 0 {
    for (distance, label, is-major) in ticks {
      let offset = vector.add(vector.scale(dir, distance), offset)
      let start = vector.add(low, offset)
      let end = vector.add(high, offset)
        
      // Draw a major line
      if is-major and (kind == 1 or kind == 3) {
        draw.line(start, end, stroke: style.grid.stroke)
      }
      // Draw a minor line
      if not is-major and kind >= 2 {
        draw.line(start, end, stroke: style.minor-grid.stroke)
      }
    }
  }
}

// Place a list of tick marks and labels along a path
#let place-ticks-on-line(ticks, start, stop, style, flip: false, is-mirror: false) = {
  let dir = vector.sub(stop, start)
  let norm = vector.norm((-dir.at(1), dir.at(0), dir.at(2, default: 0)))

  let def(v, d) = {
    return if v == none or v == auto {d} else {v}
  }

  let show-label = style.tick.label.show
  if show-label == auto {
    show-label = not is-mirror
  }

  for (distance, label, is-major) in ticks {
    let offset = style.tick.offset
    let length = if is-major { style.tick.length } else { style.tick.minor-length }
    if flip {
      offset *= -1
      length *= -1
    }

    let pt = vector.lerp(start, stop, distance)
    let a = vector.add(pt, vector.scale(norm, offset))
    let b = vector.add(a, vector.scale(norm, length))

    draw.line(a, b, stroke: style.tick.stroke)

    if show-label and label != none {
      let offset = style.tick.label.offset
      if flip {
        offset *= -1
        length *= -1
      }

      let c = vector.sub(if length <= 0 { b } else { a },
        vector.scale(norm, offset))

      let angle = def(style.tick.label.angle, 0deg)
      let anchor = def(style.tick.label.anchor, "center")

      draw.content(c, [#label], angle: angle, anchor: anchor)
    }
  }
}

// Draw up to four axes in an "scientific" style at origin (0, 0)
//
// - size (array): Size (width, height)
// - left (axis): Left (y) axis
// - bottom (axis): Bottom (x) axis
// - right (axis): Right axis
// - top (axis): Top axis
// - name (string): Object name
// - draw-unset (bool): Draw axes that are set to `none`
// - ..style (any): Style
#let scientific(size: (1, 1),
                left: none,
                right: auto,
                bottom: none,
                top: auto,
                draw-unset: true,
                name: none,
                ..style) = {
  import draw: *

  if right == auto {
    if left != none {
      right = left; right.is-mirror = true
    } else {
      right = none
    }
  }
  if top == auto {
    if bottom != none {
      top = bottom; top.is-mirror = true
    } else {
      top = none
    }
  }

  group(name: name, ctx => {
    let (w, h) = size
    anchor("origin", (0, 0))

    let style = style.named()
    style = styles.resolve(ctx.style, merge: style, root: "axes",
                           base: default-style-scientific)
    style = _prepare-style(ctx, style)

    // Compute ticks
    let x-ticks = compute-ticks(bottom, style)
    let y-ticks = compute-ticks(left, style)
    let x2-ticks = compute-ticks(top, style)
    let y2-ticks = compute-ticks(right, style)

    // Draw frame
    if style.fill != none {
      on-layer(style.background-layer, {
        rect((0,0), (w,h), fill: style.fill, stroke: none)
      })
    }

    // Draw grid
    group(name: "grid", ctx => {
      let axes = (
        ("bottom", (0,0), (0,h), (+w,0), x-ticks,  bottom),
        ("top",    (0,h), (0,0), (+w,0), x2-ticks, top),
        ("left",   (0,0), (w,0), (0,+h), y-ticks,  left),
        ("right",  (w,0), (0,0), (0,+h), y2-ticks, right),
      )
      for (name, start, end, direction, ticks, axis) in axes {
        if axis == none { continue }

        let style = _get-axis-style(ctx, style, name)
        let is-mirror = axis.at("is-mirror", default: false)

        if not is-mirror {
          on-layer(style.grid-layer, {
            draw-grid-lines(ctx, axis, ticks, start, end, direction, style)
          })
        }
      }
    })

    // Draw axes
    group(name: "axes", {
      let axes = (
        ("bottom", (0, 0), (w, 0), (0, -1), false, x-ticks,  bottom,),
        ("top",    (0, h), (w, h), (0, +1), true,  x2-ticks, top,),
        ("left",   (0, 0), (0, h), (-1, 0), true,  y-ticks,  left,),
        ("right",  (w, 0), (w, h), (+1, 0), false, y2-ticks, right,)
      )
      let label-placement = (
        bottom: ("south", "north", 0deg),
        top:    ("north", "south", 0deg),
        left:   ("west", "south", 90deg),
        right:  ("east", "north", 90deg),
      )

      for (name, start, end, outsides, flip, ticks, axis) in axes {
        let style = _get-axis-style(ctx, style, name)
        let is-mirror = axis == none or axis.at("is-mirror", default: false)
        let is-horizontal = name in ("bottom", "top")

        if style.padding != 0 {
          let padding = vector.scale(outsides, style.padding)
          start = vector.add(start, padding)
          end = vector.add(end, padding)
        }

        let (data-start, data-end) = _inset-axis-points(ctx, style, axis, start, end)

        let path = _draw-axis-line(start, end, axis, is-horizontal, style)
        on-layer(style.axis-layer, {
          group(name: "axis", {
            if draw-unset or axis != none {
              path;
              place-ticks-on-line(ticks, data-start, data-end, style, flip: flip, is-mirror: is-mirror)
            }
          })

          if axis != none and axis.label != none and not is-mirror {
            let offset = vector.scale(outsides, style.label.offset)
            let (group-anchor, content-anchor, angle) = label-placement.at(name)

            if style.label.anchor != auto {
              content-anchor = style.label.anchor
            }
            if style.label.angle != auto {
              angle = style.label.angle
            }

            content((rel: offset, to: "axis." + group-anchor),
              [#axis.label],
              angle: angle,
              anchor: content-anchor)
          }
        })
      }
    })
  })
}

// Draw two axes in a "school book" style
//
// - x-axis (axis): X axis
// - y-axis (axis): Y axis
// - size (array): Size (width, height)
// - x-position (number): X Axis position
// - y-position (number): Y Axis position
// - name (string): Object name
// - ..style (any): Style
#let school-book(x-axis, y-axis,
                 size: (1, 1),
                 x-position: 0,
                 y-position: 0,
                 name: none,
                 ..style) = {
  import draw: *

  group(name: name, ctx => {
    let (w, h) = size
    anchor("origin", (0, 0))

    let style = style.named()
    style = styles.resolve(
      ctx.style,
      merge: style,
      root: "axes",
      base: default-style-schoolbook)
    style = _prepare-style(ctx, style)

    let x-position = calc.min(calc.max(y-axis.min, x-position), y-axis.max)
    let y-position = calc.min(calc.max(x-axis.min, y-position), x-axis.max)
    let x-y = value-on-axis(y-axis, x-position) * h
    let y-x = value-on-axis(x-axis, y-position) * w

    let shared-zero = style.shared-zero != false and x-position == 0 and y-position == 0

    let x-ticks = compute-ticks(x-axis, style, add-zero: not shared-zero)
    let y-ticks = compute-ticks(y-axis, style, add-zero: not shared-zero)

    // Draw grid
    group(name: "grid", ctx => {
      let axes = (
        ("x", (0,0), (0,h), (+w,0), x-ticks, x-axis),
        ("y", (0,0), (w,0), (0,+h), y-ticks, y-axis),
      )

      for (name, start, end, direction, ticks, axis) in axes {
        if axis == none { continue }

        let style = _get-axis-style(ctx, style, name)
        on-layer(style.grid-layer, {
          draw-grid-lines(ctx, axis, ticks, start, end, direction, style)
        })
      }
    })

    // Draw axes
    group(name: "axes", {
      let axes = (
        ("x", (0, x-y), (w, x-y), (1, 0), false, x-ticks, x-axis),
        ("y", (y-x, 0), (y-x, h), (0, 1), true, y-ticks, y-axis),
      )
      let label-pos = (
        x: ("north", (0,-1)),
        y: ("east", (-1,0)),
      )

      on-layer(style.axis-layer, {
        for (name, start, end, dir, flip, ticks, axis) in axes {
          let style = _get-axis-style(ctx, style, name)

          let pad = style.padding
          let overshoot = style.overshoot
          let vstart = vector.sub(start, vector.scale(dir, pad))
          let vend = vector.add(end, vector.scale(dir, pad + overshoot))
          let is-horizontal = name == "x"

          let (data-start, data-end) = _inset-axis-points(ctx, style, axis, start, end)
          group(name: "axis", {
            _draw-axis-line(vstart, vend, axis, is-horizontal, style)
            place-ticks-on-line(ticks, data-start, data-end, style, flip: flip)
          })

          if axis.label != none {
            let (content-anchor, offset-dir) = label-pos.at(name)

            let angle = if style.label.angle not in (none, auto) {
              style.label.angle
            } else { 0deg }
            if style.label.anchor not in (none, auto) {
              content-anchor = style.label.anchor
            }

            let offset = vector.scale(offset-dir, style.label.offset)
            content((rel: offset, to: vend),
              [#axis.label],
              angle: angle,
              anchor: content-anchor)
          }
        }

        if shared-zero {
          let pt = (rel: (-style.tick.label.offset, -style.tick.label.offset),
                     to: (y-x, x-y))
          let zero = if type(style.shared-zero) == typst-content {
            style.shared-zero
          } else {
            $0$
          }
          content(pt, zero, anchor: "north-east")
        }
      })
    })
  })
}
