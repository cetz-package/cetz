// CeTZ Library for drawing graph axes
#import "../util.typ"
#import "../draw.typ"
#import "../vector.typ"
#import "../styles.typ"

// Global defaults
#let tic-limit = 100
#let default-style = (
  fill: none,
  stroke: black,
  label: (
    offset: .2,
  ),
  tick: (
    fill: none,
    stroke: black,
    length: .1,
    minor-length: .08,
    label: (
      offset: .2,
    )
  ),
  grid: (
    stroke: (paint: gray, dash: "dotted"),
    fill: none
  ),
)

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
          ticks: (step: 1, minor-step: none,
                 unit: none, decimals: 2, grid: false)) = (
  min: min, max: max, ticks: ticks, label: label,
)

// Format a tick value
#let format-tick-value(value, tic-options) = {
  if type(value) in ("int", "float") {
    let factor = calc.pow(10, tic-options.at("decimals", default: 2))
    value = str(calc.floor(value * factor + .5) / factor)
  } else if type(value) != "content" {
    value = str(value)
  }

  if tic-options.at("unit", default: none) != none {
    value += tic-options.unit
  }
  return value
}

// Get value on axis
//
// - axis (axis): Axis
// - v (number): Value
#let value-on-axis(axis, v) = {
  if v == none { return }
  let (min, max) = (axis.min, axis.max)
  let dt = max - min; if dt == 0 { dt = 1 }

  return (v - min) / dt
}

// Compute list of ticks for axis
//
// - axis (axis): Axis
#let compute-linear-ticks(axis) = {
  let (min, max) = (axis.min, axis.max)
  let dt = max - min; if (dt == 0) { dt = 1 }
  let ticks = axis.ticks

  let l = ()
  if ticks != none {
    if "step" in ticks and ticks.step != none {
      let s = 1 / ticks.step
      let r = int(max * s + .5) - int(min * s)
      let n = range(int(min * s), int(max * s + 1.5))

      assert(n.len() <= tic-limit, message: "Number of major ticks exceeds limit.")
      for t in n {
        let v = ((t / s) - min) / dt
        if v >= 0 and v <= 1 {
          l.push((v, format-tick-value(t / s, ticks)))
        }
      }
    }

    if "minor-step" in ticks and ticks.minor-step != none {
      let s = 1 / ticks.minor-step
      let r = int(max * s + .5) - int(min * s)
      let n = range(int(min * s), int(max * s + 1.5))

      assert(n.len() <= tic-limit, message: "Number of minor ticks exceeds limit.")
      for t in n {
        let v = ((t / s) - min) / dt
        if v != none and v >= 0 and v <= 1 {
          l.push((v, none))
        }
      }
    }

    if "list" in ticks {
      for t in ticks.list {
        let (v, label) = (none, none)
        if type(t) in ("float", "integer") {
          v = t
          label = format-tick-value(t, ticks)
        } else {
          (v, label) = t
        }

        v = value-on-axis(axis, v)
        if v != none and v >= 0 and v <= 1 {
          l.push((v, label))
        }
      }
    }
  }

  return l
}

/// Draw inside viewport coordinates of two axes
///
/// - size (vector): Axis canvas size (relative to origin)
/// - origin (coordinates): Axis Canvas origin
/// - x (axis): X Axis
/// - y (axis): Y Axis
/// - name (string,none): Group name
#let axis-viewport(size, x, y, origin: (0, 0), name: none, body) = {
  size = (rel: size, to: origin)

  draw.group({
    draw.set-viewport(origin, size,
      bounds: (x.max - x.min,
               y.max - y.min,
               0))
    draw.translate((-x.min, y.min, 0), pre: false)
    body
  })
}

// Draw up to four axes in an "scientific" style at origin (0, 0)
//
// - left (axis): Left (y) axis
// - bottom (axis): Bottom (x) axis
// - right (axis): Right axis
// - top (axis): Top axis
// - size (array): Size (width, height)
// - name (string): Object name
// - padding (array): Padding (left, right, top, bottom)
// - frame (bool): If true, draw frame
// - ..style (any): Style
#let scientific(size: (1, 1),
                left: none,
                right: auto,
                bottom: none,
                top: auto,
                frame: true,
                padding: (left: 0, right: 0, top: 0, bottom: 0),
                name: none,
                ..style) = {
  import draw: *

  if right == auto and left != none {right = left; right.is-mirror = true}
  if top == auto and bottom != none {top = bottom; top.is-mirror = true}

  group(name: name, ctx => {
    let (w, h) = size

    anchor("origin",           (0, 0))
    anchor("data-bottom-left", (0, 0))
    anchor("data-top-right",   (w, h))

    let style = style.named()
    style = util.merge-dictionary(default-style,
      styles.resolve(ctx.style, style, root: "axes"))

    let padding = (
      l: padding.at("left", default: 0),
      r: padding.at("right", default: 0),
      t: padding.at("top", default: 0),
      b: padding.at("bottom", default: 0),
    )

    let axis-settings = (
      (left,   "left",   "right",  (0, auto), ( 1, 0)),
      (right,  "right",  "left",   (w, auto), (-1, 0)),
      (bottom, "bottom", "top",    (auto, 0), (0,  1)),
      (top,    "top",    "bottom", (auto, h), (0, -1)),
    )

    group(name: "axes", {
      let (w, h) = (w - padding.l - padding.r,
                    h - padding.t - padding.b)
      for (axis, _, anchor, placement, tic-dir) in axis-settings {
        if axis != none {
          for (pos, label) in compute-linear-ticks(axis) {
            let (x, y) = placement
            if x == auto { x = pos * w + padding.l }
            if y == auto { y = pos * h + padding.b }

            if label != none and not axis.at("is-mirror", default: false) {
              let label-pos = vector.add((x, y),
                vector.scale(tic-dir, -style.tick.label.offset))
              content(label-pos, [#label], anchor: anchor)
            }

            let major = label != none
            let length = if major {
              style.tick.length} else {
              style.tick.minor-length}
            
            if length != none and length > 0 {
              line((x, y),
                   vector.add((x, y), vector.scale(tic-dir, length)),
                   ..style.tick)
            }

            if axis.ticks.at("grid", default: false) {
              let grid-dir = tic-dir
              grid-dir.at(0) *= w
              grid-dir.at(1) *= h

              line((x, y), (rel: grid-dir),
                   ..style.grid)
            }
          }
        }
      }

      if frame {
        rect((0, 0), size, ..style)
      }
    })

    for (axis, side, anchor, ..) in axis-settings {
      if axis == none {continue}
      if "label" in axis and axis.label != none and not axis.at("is-mirror", default: false) {
        let angle = if side in ("left", "right") {
          -90deg
        } else { 0deg }

        // Use a group to get non-rotated anchors
        group(content("axes." + side, axis.label,
                      angle: angle, padding: style.label.offset),
                      anchor: anchor)
      }
    }
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
                 axis-padding: .4,
                 name: none,
                 ..style) = {
  import draw: *

  let padding = (
    left: axis-padding,
    right: axis-padding,
    top: axis-padding,
    bottom: axis-padding,
  )

  group(name: name, ctx => {
    let style = style.named()
    style = util.merge-dictionary(default-style,
      styles.resolve(ctx.style, style, root: "axes"))

    let x-position = calc.min(calc.max(y-axis.min, x-position), y-axis.max)
    let y-position = calc.min(calc.max(x-axis.min, y-position), x-axis.max)

    let (w, h) = size

    let x-y = value-on-axis(y-axis, x-position) * h
    let y-x = value-on-axis(x-axis, y-position) * w

    let axis-settings = (
      (x-axis, "top",   (auto, x-y), (0, 1)),
      (y-axis, "right", (y-x, auto), (1, 0)),
    )

    line((-axis-padding, x-y), (w + axis-padding, x-y), mark: (end: ">"),
         name: "x-axis")
    if "label" in x-axis and x-axis.label != none {
      content((rel: (0, -style.tick.label.offset), to: "x-axis.end"),
        anchor: "top", x-axis.label)
    }

    line((y-x, -axis-padding), (y-x, h + axis-padding), mark: (end: ">"),
         name: "y-axis")
    if "label" in y-axis and y-axis.label != none {
      content((rel: (-style.tick.label.offset, 0), to: "y-axis.end"),
        anchor: "right", y-axis.label)
    }

    let origin-drawn = false
    for (axis, anchor, placement, tic-dir) in axis-settings {
      if axis != none {
        for (pos, label) in compute-linear-ticks(axis) {
          let (x, y) = placement
          if x == auto { x = pos * w }
          if y == auto { y = pos * h }

          if label != none {
            let label-pos = vector.sub((x, y),
              vector.scale(tic-dir, style.tick.label.offset / 2))

            if x == y-x and y == x-y {
              if origin-drawn { continue }
              origin-drawn = true
              content(vector.add((x, y),
                  vector.scale((-1, -1), style.tick.label.offset)),
                [#label], anchor: "top-right")
            } else {
              content(label-pos, [#label], anchor: anchor)
            }
          }

          let major = label != none
          let dir = vector.scale(tic-dir,
            if major {style.tick.length} else {style.tick.minor-length})
          line(vector.sub((x, y), dir),
               vector.add((x, y), dir))
        }
      }
    }
  })
}
