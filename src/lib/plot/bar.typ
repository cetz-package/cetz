#import "/src/draw.typ"
#import "/src/util.typ"

#import "errorbar.typ": draw-errorbar

#let _transform-row(row, x-key, y-key, error-key) = {
  let x = row.at(x-key)
  let y = if y-key == auto {
    row.slice(1)
  } else if type(y-key) == array {
    y-key.map(k => row.at(k, default: 0))
  } else {
    row.at(y-key, default: 0)
  }
  let err = if error-key == none {
    0
  } else if type(error-key) == array {
    error-key.map(k => row.at(k, default: 0))
  } else {
    row.at(error-key, default: 0)
  }

  if type(y) != array { y = (y,) }
  if type(err) != array { err = (err,) }

  (x, y.flatten(), err.flatten())
}

// Get a single items min and maximum y-value
#let _minmax-value(row) = {
  let min = none
  let max = none

  let y = row.at(1)
  let e = row.at(2)
  for i in range(0, y.len()) {
    let i-min = y.at(i) - e.at(i, default: 0)
    if min == none { min = i-min }
    else { min = calc.min(min, i-min) }

    let i-max = y.at(i) + e.at(i, default: 0)
    if max == none { max = i-max }
    else { max = calc.max(max, i-max) }
  }

  return (min: min, max: max)
}

// Functions for max value calculation
#let _max-value-fn = (
  basic: (data, min: 0) => {
    calc.max(min, ..data.map(t => _minmax-value(t).max))
  },
  clustered: (data, min: 0) => {
    calc.max(min, ..data.map(t => _minmax-value(t).max))
  },
  stacked: (data, min: 0) => {
    calc.max(min, ..data.map(t => t.at(1).sum()))
  },
  stacked100: (.., min: 0) => {min + 100}
)

// Functions for min value calculation
#let _min-value-fn = (
  basic: (data, min: 0) => {
    calc.min(min, ..data.map(t => _minmax-value(t).min))
  },
  clustered: (data, min: 0) => {
    calc.min(min, ..data.map(t => _minmax-value(t).min))
  },
  stacked: (data, min: 0) => {
    calc.min(min, ..data.map(t => t.at(1).sum()))
  },
  stacked100: (.., min: 0) => {min}
)

#let _prepare(self, ctx) = {
  return self
}

#let _get-x-offset(position, width) = {
  if position == "start" { 0 }
  else if position == "end" { width }
  else { width / 2 }
}

#let _draw-rects(filling, self, ctx, ..args) = {
  let x-axis = ctx.x
  let y-axis = ctx.y

  let bars = ()
  let errors = ()

  let w = self.bar-width
  for d in self.data {
    let (x, n, len, y-min, y-max, err) = d

    let w = self.bar-width
    let gap = self.cluster-gap * if w > 0 { -1 } else { +1 }
    w += gap * (len - 1)

    let x-offset = _get-x-offset(self.bar-position, self.bar-width)
    x-offset += gap * n

    let left  = x - x-offset
    let right = left + w
    let width = (right - left) / len

    if self.mode in ("basic", "clustered") {
      left = left + width * n
      right = left + width
    }

    if (left <= x-axis.max and right >= x-axis.min and
        y-min <= y-axis.max and y-max >= y-axis.min) {
      left = calc.max(left, x-axis.min)
      right = calc.min(right, x-axis.max)
      y-min = calc.max(y-min, y-axis.min)
      y-max = calc.min(y-max, y-axis.max)

      draw.rect((left, y-min), (right, y-max))

      if not filling and err != 0 {
        let y-whisker-size = self.whisker-size * ctx.x-scale
        draw-errorbar(((left + right) / 2, y-max),
          0, err, 0, y-whisker-size / 2, self.style + self.error-style)
      }
    }
  }
}

#let _stroke(self, ctx) = {
  _draw-rects(false, self, ctx, fill: none)
}

#let _fill(self, ctx) = {
  _draw-rects(true, self, ctx, stroke: none)
}

/// Add a bar- or column-chart to the plot
///
/// A bar- or column-chart is a chart where values are drawn as rectangular boxes.
///
/// - data (array): Array of data items. An item is an array containing a x an one or more y values.
///                 For example `(0, 1)` or `(0, 10, 5, 30)`. Depending on the `mode`, the data items
///                 get drawn as either clustered or stacked rects.
/// - x-key: (int,string): Key to use for retreiving a bars x-value from a single data entry.
///   This value gets passed to the `.at(...)` function of a data item.
/// - y-key: (auto,int,string,array): Key to use for retreiving a bars y-value. For clustered/stacked
///   data, this must be set to a list of keys (e.g. `range(1, 4)`). If set to `auto`, att but the first
///   array-values of a data item are used as y-values.
/// - error-key: (none,int,string): Key to use for retreiving a bars y-error.
/// - mode (string): The mode on how to group data items into bars:
///   / basic: Add one bar per data value. If the data contains multiple values,
///     group those bars next to each other.
///   / clustered: Like "basic", but take into account the maximum number of values of all items
///     and group each cluster of bars together having the width of the widest cluster.
///   / stacked: Stack bars of subsequent item values onto the previous bar, generating bars
///     with the height of the sume of all an items values.
///   / stacked100: Like "stacked", but scale each bar to height $100$, making the different
///     bars percentages of the sum of an items values.
/// - labels (none,content,array): A single legend label for "basic" bar-charts, or a
///   a list of legend labels per bar category, if the mode is one of "clustered", "stacked" or "stacked100".
/// - bar-width (float): Width of one data item on the y axis
/// - bar-position (string): Positioning of data items relative to their x value.
///   - "start": The lower edge of the data item is on the x value (left aligned)
///   - "center": The data item is centered on the x value
///   - "end": The upper edge of the data item is on the x value (right aligned)
/// - cluster-gap (float): Spacing between bars insides a cluster.
/// - style (dictionary): Plot style
/// - axes (axes): Plot axes. To draw a horizontal growing bar chart, you can swap the x and y axes.
#let add-bar(data,
             x-key: 0,
             y-key: auto,
             error-key: none,
             mode: "basic",
             labels: none,
             bar-width: 1,
             bar-position: "center",
             cluster-gap: 0,
             whisker-size: .25,
             error-style: (:),
             style: (:),
             axes: ("x", "y")) = {
  assert(mode in ("basic", "clustered", "stacked", "stacked100"),
    message: "Mode must be basic, clustered, stacked or stacked100, but is " + mode)
  assert(bar-position in ("start", "center", "end"),
    message: "Invalid bar-position '" + bar-position + "'. Allowed values are: start, center, end")
  assert(bar-width != 0,
    message: "Option bar-width must be != 0, but is " + str(bar-width))
  if error-key != none {
    assert(y-key != auto,
      message: "Bar value-key must be set != auto if error-key is set")
    assert(mode in ("basic", "clustered"),
      message: "Error bars are supported for basic or clustered only, got " + mode)
  }

  // Transform data to (x, y, error) triplets
  let data = data.map(row => _transform-row(row, x-key, y-key, error-key))

  let n = util.max(..data.map(d => d.at(1).len()))
  let x-offset = _get-x-offset(bar-position, bar-width)
  let x-domain = (util.min(..data.map(d => d.at(0))) - x-offset,
                  util.max(..data.map(d => d.at(0))) - x-offset + bar-width)
  let y-domain = (_min-value-fn.at(mode)(data),
                  _max-value-fn.at(mode)(data))

  // For stacked 100%, multiply each column/bar
  if mode == "stacked100" {
    data = data.map(((x, y, err)) => {
      let f = 100 / y.sum()
      return (x, y.map(v => v * f), err)
    })
  }

  // Transform data from (x, ..y) to (x, n, len, y-min, y-max) per y
  let stacked = mode in ("stacked", "stacked100")
  let clustered = mode == "clustered"
  let bar-data = if mode == "basic" {
    range(0, data.len()).map(_ => ())
  } else {
    range(0, n).map(_ => ())
  }

  let j = 0
  for (x, y, err) in data {
    let len = if clustered { n } else { y.len() }
    let sum = 0
    for (i, y) in y.enumerate() {
      let err = err.at(i, default: 0)
      if stacked {
        bar-data.at(i).push((x, i, len, sum, sum + y, err))
      } else if clustered {
        bar-data.at(i).push((x, i, len, 0, y, err))
      } else {
        bar-data.at(j).push((x, i, len, 0, y, err))
      }
      sum += y
    }
    j += 1
  }

  let labels = if type(labels) == array { labels } else { (labels,) }
  range(0, bar-data.len()).map(i => (
    type: "bar",
    label: labels.at(i, default: none),
    axes: axes,
    mode: mode,
    data: bar-data.at(i),
    x-domain: x-domain,
    y-domain: y-domain,
    style: style,
    bar-width: bar-width,
    bar-position: bar-position,
    cluster-gap: cluster-gap,
    whisker-size: whisker-size,
    error-style: error-style,
    plot-prepare: _prepare,
    plot-stroke: _stroke,
    plot-fill: _fill,
    plot-legend-preview: self => {
      draw.rect((0,0), (1,1), ..self.style)
    }
  ))
}
