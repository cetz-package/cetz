#import "util.typ"
#import "sample.typ"
#import "/src/draw.typ"

// Transform points
//
// - data (array): Data points
// - line (str,dictionary): Line line
#let transform-lines(data, line) = {
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
    return pts
  }

  if type(line) == str {
    line = (type: line)
  }

  let line-type = line.at("type", default: "linear")
  assert(line-type in ("raw", "linear", "spline", "vh", "hv", "vhv"))

  // Transform data into line-data
  let line-data = if line-type == "linear" {
    return util.linearized-data(data, line.at("epsilon", default: 0))
  } else if line-type == "spline" {
    return util.sampled-spline-data(data,
                                    line.at("tension", default: .5),
                                    line.at("samples", default: 15))
  } else if line-type == "vh" {
    return vhv-data(0)
  } else if line-type == "hv" {
    return vhv-data(1)
  } else if line-type == "vhv" {
    return vhv-data(line.at("mid", default: .5))
  } else {
    return data
  }
}

// Fill a plot by generating a fill path to y value `to`
#let fill-segments-to(segments, to) = {
  for s in segments {
    let low  = calc.min(..s.map(v => v.at(0)))
    let high = calc.max(..s.map(v => v.at(0)))

    let origin = (low, to)
    let target = (high, to)

    draw.line(origin, ..s, target, stroke: none)
  }
}

// Fill a shape by generating a fill path for each segment
#let fill-shape(paths) = {
  for p in paths {
    draw.line(..p, stroke: none)
  }
}

// Prepare line data
#let _prepare(self, ctx) = {
  let (x, y) = (ctx.x, ctx.y)

  // Generate stroke paths
  self.stroke-paths = util.compute-stroke-paths(self.line-data,
    (x.min, y.min), (x.max, y.max))

  // Compute fill paths if filling is requested
  self.hypograph = self.at("hypograph", default: false)
  self.epigraph = self.at("epigraph", default: false)
  self.fill = self.at("fill", default: false)
  if self.hypograph or self.epigraph or self.fill {
    self.fill-paths = util.compute-fill-paths(self.line-data,
      (x.min, y.min), (x.max, y.max))
  }

  return self
}

// Stroke line data
#let _stroke(self, ctx) = {
  let (x, y) = (ctx.x, ctx.y)

  for p in self.stroke-paths {
    draw.line(..p, fill: none)
  }
}

// Fill line data
#let _fill(self, ctx) = {
  let (x, y) = (ctx.x, ctx.y)

  if self.hypograph {
    fill-segments-to(self.fill-paths, y.min)
  }
  if self.epigraph {
    fill-segments-to(self.fill-paths, y.max)
  }
  if self.fill {
    if self.at("fill-type", default: "axis") == "shape" {
      fill-shape(self.fill-paths)
    } else {
      fill-segments-to(self.fill-paths,
        calc.max(calc.min(y.max, 0), y.min))
    }
  }
}

/// Add data to a plot environment.
///
/// Note: You can use this for scatter plots by setting
///       the stroke style to `none`: `add(..., style: (stroke: none))`.
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
/// - fill-type (string): Fill type:
///                       / `"axis"`: Fill to y = 0
///                       / `"shape"`: Fill the functions shape
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
///                              / `"linear"` _should_ never look different than `"raw"`.
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
         fill-type: "axis",
         style: (:),
         mark: none,
         mark-size: .2,
         mark-style: (:),
         samples: 50,
         sample-at: (),
         line: "linear",
         axes: ("x", "y"),
         data
         ) = {
  // If data is of type function, sample it
  if type(data) == function {
    data = sample.sample-fn(data, domain, samples, sample-at: sample-at)
  }

  // Transform data
  let line-data = transform-lines(data, line)

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
    type: "line",
    data: data, /* Raw data */
    line-data: line-data, /* Transformed data */
    axes: axes,
    x-domain: x-domain,
    y-domain: y-domain,
    epigraph: epigraph,
    hypograph: hypograph,
    fill: fill,
    fill-type: fill-type,
    style: style,
    mark: mark,
    mark-size: mark-size,
    mark-style: mark-style,
    plot-prepare: _prepare,
    plot-stroke: _stroke,
    plot-fill: _fill,
  ),)
}

/// Add horizontal lines at values y
///
/// - ..y (number): Y axis value(s) to add a line at
/// - axes (array): Name of the axes to use ("x", "y"), note that not all
///                 plot styles are able to display a custom axis!
/// - style (style): Style to use, can be used with a palette function
#let add-hline(..y,
               axes: ("x", "y"),
               style: (:),
               ) = {
  assert(y.pos().len() >= 1,
         message: "Specify at least one y value")
  assert(y.named().len() == 0)

  let prepare(self, ctx) = {
    let (x-min, x-max) = (ctx.x.min, ctx.x.max)
    let (y-min, y-max) = (ctx.y.min, ctx.y.max)
    self.lines = self.y.filter(y => y >= y-min and y <= y-max)
      .map(y => ((x-min, y), (x-max, y)))
    return self
  }

  let stroke(self, ctx) = {
    for (a, b) in self.lines {
      draw.line(a, b, fill: none)
    }
  }

  ((
    type: "hline",
    y: y.pos(),
    y-domain: (calc.min(..y.pos()), calc.max(..y.pos())),
    axes: axes,
    style: style,
    plot-prepare: prepare,
    plot-stroke: stroke,
  ),)
}

/// Add vertical lines at values x.
///
/// - ..x (number): X axis values to add a line at
/// - axes (array): Name of the axes to use ("x", "y"), note that not all
///                 plot styles are able to display a custom axis!
/// - style (style): Style to use, can be used with a palette function
#let add-vline(..x,
               axes: ("x", "y"),
               style: (:),
               ) = {
  assert(x.pos().len() >= 1,
         message: "Specify at least one x value")
  assert(x.named().len() == 0)

  let prepare(self, ctx) = {
    let (x-min, x-max) = (ctx.x.min, ctx.x.max)
    let (y-min, y-max) = (ctx.y.min, ctx.y.max)
    self.lines = self.x.filter(x => x >= x-min and x <= x-max)
      .map(x => ((x, y-min), (x, y-max)))
    return self
  }

  let stroke(self, ctx) = {
    for (a, b) in self.lines {
      draw.line(a, b, fill: none)
    }
  }

  ((
    type: "vline",
    x: x.pos(),
    x-domain: (calc.min(..x.pos()), calc.max(..x.pos())),
    axes: axes,
    style: style,
    plot-prepare: prepare,
    plot-stroke: stroke
  ),)
}
