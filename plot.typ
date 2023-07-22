// CeTZ Library for drawing graph axes
#import "util.typ"
#import "draw.typ"
#import "vector.typ"

// Global defaults
#let num-samples = 50
#let tic-limit = 100
#let major-mark-size = .08
#let minor-mark-size = .05

// Construct Axis Object
//
// - min (number): Minimum value
// - max (numble): Maximum value
// - tics (dictionary): Tick settings:
//     - step (number): Major tic step
//     - minor-step (number): Minor tic step
// - label (content): Axis label
#let axis(min: -1, max: 1, tics: (step: 1, minor-step: none), label: none) = (
  min: min, max: max, tics: tics, label: label,
)

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

// Compute list of tics for axis
//
// - axis (axis): Axis
#let compute-linear-tics(axis) = {
  let (min, max) = (axis.min, axis.max)
  let dt = max - min; if (dt == 0) { dt = 1 }
  let tics = axis.tics

  let l = ()
  if tics != none {
    if "step" in tics and tics.step != none {
      let s = 1 / tics.step
      let r = int(max * s + .5) - int(min * s)
      let n = range(int(min * s), int(max * s + 1.5))

      assert(n.len() <= tic-limit, message: "Number of major tics exceeds limit.")
      for t in n {
        let v = ((t / s) - min) / dt
        if v >= 0 and v <= 1 {
          l.push((v, t / s))
        }
      }
    }

    if "minor-step" in tics and tics.minor-step != none {
      let s = 1 / tics.minor-step
      let r = int(max * s + .5) - int(min * s)
      let n = range(int(min * s), int(max * s + 1.5))

      assert(n.len() <= tic-limit, message: "Number of minor tics exceeds limit.")
      for t in n {
        let v = ((t / s) - min) / dt
        if v != none and v >= 0 and v <= 1 {
          l.push((v, none))
        }
      }
    }

    if "list" in tics {
      for t in tics.list {
        let (v, label) = (none, none)
        if type(t) in ("float", "integer") {
          v = t
          label = str(t)
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

// Compute list of linear paths for data points
//
// - data (array): List of (x, y) data points
#let paths-for-points(data) = {
  let in-range(p) = {
    if p == none { return false }
    let (px, py, ..) = p
    return (px >= 0
        and px <= 1
        and py >= 0
        and py <= 1)
  }

  let lin-interpolated-pt(a, b) = {
    let x1 = a.at(0)
    let y1 = a.at(1)
    let x2 = b.at(0)
    let y2 = b.at(1)

    /* Special case for vertical lines */
    if x2 - x1 == 0 {
      return (x2, calc.min(1, calc.max(y2, 0)))
    }

    if y2 - y1 == 0 {
      return (calc.min(1, calc.max(x2, 0)), y2)
    }

    let m = (y2 - y1) / (x2 - x1)
    let n = y2 - m * x2

    let x = x2
    let y = y2

    y = calc.min(1, calc.max(y, 0))
    x = (y - n) / m

    x = calc.min(1, calc.max(x, 0))
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

// Draw data
//
// - data (array|dictionary): Data
// - axes (array): Array of x and y axis
// - w (number): Width
// - h (number): Height
#let draw-data-path(data, axes, w, h) = {
  let style = (stroke: black + 1pt)
  let fill = false
  let epigraph = false
  let hypograph = false
  let num-samples = num-samples

  if type(data) == "dictionary" {
    style = data.at("style", default: style)
    epigraph = data.at("epigraph", default: false)
    hypograph = data.at("hypograph", default: false)
    fill = data.at("fill", default: false)
    num-samples = data.at("samples", default: num-samples)

    data = data.data
  }

  if type(data) == "function" {
    let (lo, hi) = (axes.at(0).min, axes.at(0).max)
    let scale = num-samples / (hi - lo)
    data = range(int(lo * scale - .5), int(hi * scale + 1.5)).map(x =>
      (x / scale, data(x / scale)))
  }

  let segments = paths-for-points(data.map(((x, y, ..)) => {
    (value-on-axis(axes.at(0), x),
     value-on-axis(axes.at(1), y))
  })).map(l => l.map(((x, y)) => {
    (x * w, y * h)
  }))

  let fill-graph-to(to, style) = {
    to = value-on-axis(axes.at(1), to) * h

    if not "stroke" in style { style.stroke = none }
    if not "mark" in style { style.mark = (begin: none, end: none) }

    let pts = ()
    for segment in segments {
      pts += segment
    }

    let origin = (pts.first().at(0), to)
    let target = (pts.last().at(0), to)

    draw.line(origin, ..pts, target, ..style)
  }

  if epigraph {
    fill-graph-to(axes.at(1).max,
                  style.at("epigraph", default: (fill: gray)))
  }
  if hypograph {
    fill-graph-to(axes.at(1).min,
                  style.at("hypograph", default: (fill: gray)))
  }
  if fill {
    fill-graph-to(0,
                  (fill: style.at("fill", default: gray)))
  }

  for segment in segments {
    let style = style
    style.fill = none
    draw.line(..segment, ..style)
  }
}

// Draw up to four axes in an "scientific" style
//
// - left (axis): Left (y) axis
// - bottom (axis): Bottom (x) axis
// - right (axis): Right axis
// - top (axis): Top axis
// - size (array): Size (width, height)
// - name (string): Object name
// - ..style (any): Style
// - ..data (array|dictionary): Data
#let scientific-axes(size: (1, 1),
                     left: none, right: auto, bottom: none, top: auto,
                     name: none,
                     ..style-data) = {
  import draw: *

  if right == auto and left != none {right = left; right.is-mirror = true}
  if top == auto and bottom != none {top = bottom; top.is-mirror = true}

  group(name: name, {
    let (w, h) = size

    set-style(content: (padding: .1))
    let style = style-data.named()
    if style.len() > 0 {
      set-style(..style)
    }

    let axis-settings = (
      (left, "left", "right", (0, auto), (1, 0)),
      (right, "right", "left", (w, auto), (1, 0)),
      (bottom, "bottom", "top", (auto, 0), (0, 1)),
      (top, "top", "bottom", (auto, h), (0, 1)),
    )

    for data in style-data.pos() {
      let axes = (bottom, left)
      if type(data) == "dictionary" {
        if "axes" in data {
          axes = data.axes
        }
      }
      draw-data-path(data, axes, w, h)
    }

    group(name: "axes", {
      rect((0, 0), size)
      for (axis, _, anchor, placement, mark-dir) in axis-settings {
        if axis != none {
          for (pos, label) in compute-linear-tics(axis) {
            let (x, y) = placement
            if x == auto { x = pos * w }
            if y == auto { y = pos * h }

            if label != none and not axis.at("is-mirror", default: false) {
              content((x, y), [#label], anchor: anchor)
            }

            let major = label != none
            let dir = vector.scale(mark-dir,
              if major {major-mark-size} else {minor-mark-size})
            line(vector.sub((x, y), dir),
                 vector.add((x, y), dir))
          }
        }
      }
    })
    for (axis, side, anchor, ..) in axis-settings {
      if "label" in axis and axis.label != none and not axis.at("is-mirror", default: false) {
        let angle = if side in ("left", "right") {
          -90deg
        } else { 0deg }

        // Use a group to get non-rotated anchors
        group(content("axes." + side, axis.label,
                      angle: angle), anchor: anchor)
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
// - ..data (array|dictionary): Data
#let school-book-axes(x-axis, y-axis,
                      size: (1, 1),
                      x-position: 0,
                      y-position: 0,
                      axis-padding: .4,
                      name: none,
                      ..style-data) = {
  import draw: *

  group(name: name, {
    set-style(content: (padding: .1))

    let style = style-data.named()
    if style.len() > 0 {
      set-style(..style)
    }

    x-position = calc.min(calc.max(y-axis.min, x-position), y-axis.max)
    y-position = calc.min(calc.max(x-axis.min, y-position), x-axis.max)

    let (w, h) = size
    let x-y = value-on-axis(y-axis, x-position) * h
    let y-x = value-on-axis(x-axis, y-position) * w

    let axis-settings = (
      (x-axis, "top",   (auto, x-y), (0, 1)),
      (y-axis, "right", (y-x, auto), (1, 0)),
    )

    translate((axis-padding, axis-padding, 0))

    for data in style-data.pos() {
      let axes = (x-axis, y-axis)
      draw-data-path(data, axes, w, h)
    }

    line((-axis-padding, x-y), (w + axis-padding, x-y), mark: (end: ">"),
         name: "x-axis")
    if "label" in x-axis and x-axis.label != none {
      content("x-axis.end", anchor: "top", x-axis.label)
    }

    line((y-x, -axis-padding), (y-x, h + axis-padding), mark: (end: ">"),
         name: "y-axis")
    if "label" in y-axis and y-axis.label != none {
      content("y-axis.end", anchor: "right", y-axis.label)
    }

    let origin-drawn = false
    for (axis, anchor, placement, mark-dir) in axis-settings {
      if axis != none {
        for (pos, label) in compute-linear-tics(axis) {
          let (x, y) = placement
          if x == auto { x = pos * w }
          if y == auto { y = pos * h }

          if label != none {
            if x == y-x and y == x-y {
              if origin-drawn { continue }
              origin-drawn = true
              content((x, y), [#label], anchor: "top-right")
            } else {
              content((x, y), [#label], anchor: anchor)
            }
          }

          let major = label != none
          let dir = vector.scale(mark-dir,
            if major {major-mark-size} else {minor-mark-size})
          line(vector.sub((x, y), dir),
               vector.add((x, y), dir))
        }
      }
    }
  })
}
