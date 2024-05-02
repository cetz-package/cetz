#import "/src/draw.typ"
#import "/src/util.typ"
#import "/src/vector.typ"

#let _draw-whisker(pt, dir, ..style) = {
  let a = vector.add(pt, vector.scale(dir, -1))
  let b = vector.add(pt, vector.scale(dir, +1))

  draw.line(a, b, ..style)
}

#let draw-errorbar(pt, x, y, x-whisker-size, y-whisker-size, style) = {
  if type(x) != array { x = (-x, x) }
  if type(y) != array { y = (-y, y) }

  let (x-min, x-max) = x
  let x-min-pt = vector.add(pt, (x-min, 0))
  let x-max-pt = vector.add(pt, (x-max, 0))
  if x-min != 0 or x-max != 0 {
    draw.line(x-min-pt, x-max-pt, ..style)
    if x-whisker-size > 0 {
      if x-min != 0 {
        _draw-whisker(x-min-pt, (0, x-whisker-size), ..style)
      }
      if x-max != 0 {
        _draw-whisker(x-max-pt, (0, x-whisker-size), ..style)
      }
    }
  }

  let (y-min, y-max) = y
  let y-min-pt = vector.add(pt, (0, y-min))
  let y-max-pt = vector.add(pt, (0, y-max))
  if y-min != 0 or y-max != 0 {
    draw.line(y-min-pt, y-max-pt, ..style)
    if y-whisker-size > 0 {
      if y-min != 0 {
        _draw-whisker(y-min-pt, (y-whisker-size, 0), ..style)
      }
      if y-max != 0 {
        _draw-whisker(y-max-pt, (y-whisker-size, 0), ..style)
      }
    }
  }
}

#let _prepare(self, ctx) = {
  return self
}

#let _stroke(self, ctx) = {
  let x-whisker-size = self.whisker-size * ctx.y-scale
  let y-whisker-size = self.whisker-size * ctx.x-scale

  draw-errorbar((self.x, self.y),
    self.x-error, self.y-error,
    x-whisker-size, y-whisker-size,
    self.style)
}

/// Add x- and/or y-error bars
///
/// - pt (tuple): Error-bar center coordinate tuple: `(x, y)`
/// - x-error: (float,tuple): Single error or tuple of errors along the x-axis
/// - y-error: (float,tuple): Single error or tuple of errors along the y-axis
/// - mark: (none,string): Mark symbol to show at the error position (`pt`).
/// - mark-size: (number): Size of the mark symbol.
/// - mark-style: (style): Extra style to apply to the mark symbol.
/// - whisker-size (float): Width of the error bar whiskers in canvas units.
/// - style (dictionary): Style for the error bars
/// - label: (none,content): Label to tsh
/// - axes (axes): Plot axes. To draw a horizontal growing bar chart, you can swap the x and y axes.
#let add-errorbar(pt,
                  x-error: 0,
                  y-error: 0,
                  label: none,
                  mark: "o",
                  mark-size: .2,
                  mark-style: (:),
                  whisker-size: .5,
                  style: (:),
                  axes: ("x", "y")) = {
  assert(x-error != 0 or y-error != 0,
    message: "Either x-error or y-error must be set.")

  let (x, y) = pt

  if type(x-error) != array {
    x-error = (x-error, x-error)
  }
  if type(y-error) != array {
    y-error = (y-error, y-error)
  }

  x-error.at(0) = calc.abs(x-error.at(0)) * -1
  y-error.at(0) = calc.abs(y-error.at(0)) * -1

  let x-domain = x-error.map(v => v + x)
  let y-domain = y-error.map(v => v + y)

  return ((
    type: "errorbar",
    label: label,
    axes: axes,
    data: ((x,y),),
    x: x,
    y: y,
    x-error: x-error,
    y-error: y-error,
    x-domain: x-domain,
    y-domain: y-domain,
    mark: mark,
    mark-size: mark-size,
    mark-style: mark-style,
    whisker-size: whisker-size,
    style: style,
    plot-prepare: _prepare,
    plot-stroke: _stroke,
  ),)
}
