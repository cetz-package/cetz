#import "/src/draw.typ"
#import "/src/util.typ"
#import "/src/vector.typ"

#let _prepare(self, ctx) = {
  return self
}

#let _draw-whisker(pt, dir, ..style) = {
  let a = vector.add(pt, vector.scale(dir, -1))
  let b = vector.add(pt, vector.scale(dir, +1))

  draw.line(a, b, ..style)
}

#let _stroke(self, ctx) = {
  let (x-min, x-max) = self.x-error.map(v => v + self.x)
  let (y-min, y-max) = self.y-error.map(v => v + self.y)

  let pt-x-min = (x-min, self.y)
  let pt-x-max = (x-max, self.y)
  let pt-y-min = (self.x, y-min)
  let pt-y-max = (self.x, y-max)

  if x-min != x-max or y-min != y-max {
    if x-min != x-max {
      draw.line(pt-x-min, pt-x-max, ..self.style)

      let whisker-size = self.whisker-size * ctx.y-scale
      if whisker-size != 0 {
        _draw-whisker(pt-x-min, (0,whisker-size / 2), ..self.style)
        _draw-whisker(pt-x-max, (0,whisker-size / 2), ..self.style)
      }
    }
    if y-min != y-max {
      draw.line(pt-y-min, pt-y-max, ..self.style)

      let whisker-size = self.whisker-size * ctx.x-scale
      if whisker-size != 0 {
        _draw-whisker(pt-y-min, (whisker-size / 2,0), ..self.style)
        _draw-whisker(pt-y-max, (whisker-size / 2,0), ..self.style)
      }
    }
  }
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
