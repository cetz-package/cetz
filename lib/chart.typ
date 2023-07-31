// CeTZ Library for drawing charts

#import "axes.typ"
#import "palette.typ"
#import "../draw.typ"

// Styles
#let barchart-default-style = (
  axes: (tick: (length: 0))
)
#let columnchart-default-style = (
  axes: (tick: (length: 0))
)
#let radarchart-default-style = (
  grid: (stroke: (paint: gray, dash: "dashed")),
  mark: (size: .075, stroke: none, fill: black),
  label-padding: .1,
)

// Valid bar- and columnchart modes
#let barchart-modes = (
  "basic", "clustered", "stacked", "stacked100"
)

// Functions for max value calculation
#let barchart-max-value-fn = (
  basic: (data, value-key) => {
    calc.max(0, ..data.map(t => t.at(value-key)))
  },
  clustered: (data, value-key) => {
    calc.max(0, ..data.map(t => calc.max(
      ..value-key.map(k => t.at(k)))))
  },
  stacked: (data, value-key) => {
    calc.max(0, ..data.map(t => 
      value-key.map(k => t.at(k)).sum()))
  },
  stacked100: (..) => {
    100
  }
)

/// Draw a bar chart. A bar chart is a chart that represents data with
/// rectangular bars that grow from left to right, proportional to the values
/// they represent. For examples see @barchart-examples.
///
/// *Style root*: `barchart`.
///
/// - data (array): Array of data rows. A row can be of type array or
///                 dictionary, with `label-key` and `value-key` being
///                 the keys to access a rows label and value(s).
///
///                 *Example*
///                 ```typc
///                 (([A], 1), ([B], 2), ([C], 3),)
///                 ``` 
/// - label-key (int,string): Key to access the label of a data row.
///                           This key is used as argument to the
///                           rows `.at(..)` function.
/// - value-key (int,string): Key(s) to access value(s) of data row.
///                           These keys are used as argument to the
///                           rows `.at(..)` function.
/// - mode (string): Chart mode:
///                  - `"basic"` -- Single bar per data row
///                  - `"clustered"` -- Group of bars per data row
///                  - `"stacked"` -- Stacked bars per data row
///                  - `"stacked100"` -- Stacked bars per data row relative
///                                      to the sum of the row
/// - size (array): Chart size as width and height tuple in canvas unist;
///                 height can be set to `auto`.
/// - bar-width (float): Size of a bar in relation to the charts height.
/// - bar-style (style,function): Style or function (idx => style) to use for
///                               each bar, accepts a palette function.
/// - x-tick-step (float): Step size of x axis ticks 
/// - x-ticks (array): List of tick values or value/label tuples
///
///                    *Example*
///                    
///                    `(1, 5, 10)` or `((1, [One]), (2, [Two]), (10, [Ten]))`
/// - x-unit (content,auto): Tick suffix added to each tick label
/// - x-label (content,none): X axis label
/// - y-label (content,none): Y axis label
#let barchart(data,
              label-key: 0,
              value-key: 1,
              mode: "basic",
              size: (1, auto),
              bar-width: .8,
              bar-style: palette.red,
              x-tick-step: auto,
              x-ticks: (),
              x-unit: auto,
              x-label: none,
              y-label: none,
              ) = {
  import draw: *

  assert(mode in barchart-modes,
    message: "Invalid barchart mode")
  assert(type(label-key) in ("integer", "string"))
  if mode == "basic" {
    assert(type(value-key) in ("integer", "string"))
  } else {
    assert(type(value-key) in ("array"))
  }

  if size.at(1) == auto {
    size.at(1) = (data.len() + 1)
  }

  let max-value = (barchart-max-value-fn.at(mode))(data, value-key)

  let y-tic-list = data.enumerate().map(((i, t)) => {
    (i, t.at(label-key))
  })

  let x-unit = x-unit
  if x-unit == auto {
    x-unit = if mode == "stacked100" {[%]} else []
  }
  
  let x = axes.axis(min: 0, max: max-value,
                    label: x-label,
                    ticks: (grid: true, step: x-tick-step,
                            minor-step: none,
                            unit: x-unit, decimals: 1,
                            list: x-ticks))
  let y = axes.axis(min: data.len(), max: -1,
                    label: y-label,
                    ticks: (grid: true,
                            step: none,
                            minor-step: none,
                            list: y-tic-list))

  let basic-draw-bar(idx, y, item, ..style) = {
    rect((0, y - bar-width / 2),
         (rel: (item.at(value-key), bar-width)),
         ..bar-style(idx))
  }

  let clustered-draw-bar(idx, y, item, ..style) = {
    let y-offset = bar-width / 2
    let sub-values = value-key.map(k => item.at(k))
    let bar-width = bar-width / sub-values.len()

    for (sub-idx, sub) in sub-values.enumerate() {
      rect((0, y - y-offset + sub-idx * bar-width),
           (rel: (sub, bar-width)),
           ..bar-style(sub-idx))
    }
  }

  let stacked-draw-bar(idx, y, item, ..style) = {
    let sub-values = value-key.map(k => item.at(k))

    move-to((0, y))

    let sum = 0
    for (sub-idx, sub) in sub-values.enumerate() {
      move-to((sum, y))
      rect((sum, y - bar-width / 2),
           (rel: (sub, bar-width)),
           ..bar-style(sub-idx))
      sum += sub
    }
  }

  let stacked100-draw-bar(idx, y, item, ..style) = {
    let sum = value-key.map(k => item.at(k)).sum()
    for k in value-key {
      item.at(k) *= 100 / sum
    }

    stacked-draw-bar(idx, y, item, ..style)
  }

  let draw-data = (
    if mode == "basic" {basic-draw-bar} else
    if mode == "clustered" {clustered-draw-bar} else
    if mode == "stacked" {stacked-draw-bar} else
    if mode == "stacked100" {stacked100-draw-bar}
  )

  group(ctx => {
    let style = util.merge-dictionary(barchart-default-style,
      styles.resolve(ctx.style, (:), root: "barchart"))

    axes.scientific(size: size,
                    left: y,
                    right: none,
                    bottom: x,
                    top: none,
                    frame: "set",
                    ..style.axes)
    if data.len() > 0 {
      if type(bar-style) != "function" { bar-style = ((i) => bar-style) }

      axes.axis-viewport(size, x, y, {
        for (i, row) in data.enumerate() {
          draw-data(i, y.min - i - 1, row)
        }
      })
    }
  })
}

/// Draw a column chart. A bar chart is a chart that represents data with
/// rectangular bars that grow from bottom to top, proportional to the values
/// they represent. For examples see @columnchart-examples.
///
/// *Style root*: `columnchart`.
///
/// - data (array): Array of data rows. A row can be of type array or
///                 dictionary, with `label-key` and `value-key` being
///                 the keys to access a rows label and value(s).
///
///                 *Example*
///                 ```typc
///                 (([A], 1), ([B], 2), ([C], 3),)
///                 ``` 
/// - label-key (int,string): Key to access the label of a data row.
///                           This key is used as argument to the
///                           rows `.at(..)` function.
/// - value-key (int,string): Key(s) to access value(s) of data row.
///                           These keys are used as argument to the
///                           rows `.at(..)` function.
/// - mode (string): Chart mode:
///                  - `"basic"` -- Single bar per data row
///                  - `"clustered"` -- Group of bars per data row
///                  - `"stacked"` -- Stacked bars per data row
///                  - `"stacked100"` -- Stacked bars per data row relative
///                                      to the sum of the row
/// - size (array): Chart size as width and height tuple in canvas unist;
///                 width can be set to `auto`.
/// - bar-width (float): Size of a bar in relation to the charts height.
/// - bar-style (style,function): Style or function (idx => style) to use for
///                               each bar, accepts a palette function.
/// - y-tick-step (float): Step size of y axis ticks 
/// - y-ticks (array): List of tick values or value/label tuples
///
///                    *Example*
///                    
///                    `(1, 5, 10)` or `((1, [One]), (2, [Two]), (10, [Ten]))`
/// - y-unit (content,auto): Tick suffix added to each tick label
/// - y-label (content,none): Y axis label
/// - x-label (content,none): x axis label
#let columnchart(data,
                 label-key: 0,
                 value-key: 1,
                 mode: "basic",
                 size: (auto, 1),
                 bar-width: .8,
                 bar-style: palette.red,
                 x-label: none,
                 y-tick-step: auto,
                 y-ticks: (),
                 y-unit: auto,
                 y-label: none,
                 ) = {
  import draw: *

  assert(mode in barchart-modes,
    message: "Invalid columnchart mode")
  assert(type(label-key) in ("integer", "string"))
  if mode == "basic" {
    assert(type(value-key) in ("integer", "string"))
  } else {
    assert(type(value-key) in ("array"))
  }

  if size.at(0) == auto {
    size.at(0) = (data.len() + 1)
  }

  let max-value = (barchart-max-value-fn.at(mode))(data, value-key)

  let x-tic-list = data.enumerate().map(((i, t)) => {
    (i, t.at(label-key))
  })

  let y-unit = y-unit
  if y-unit == auto {
    y-unit = if mode == "stacked100" {[%]} else []
  }
  
  let x = axes.axis(min: -1, max: data.len(),
                    label: x-label,
                    ticks: (grid: true,
                            step: none,
                            minor-step: none,
                            list: x-tic-list))
  let y = axes.axis(min: 0, max: max-value,
                    label: y-label,
                    ticks: (grid: true, step: y-tick-step,
                            minor-step: none,
                            unit: y-unit, decimals: 1,
                            list: y-ticks))

  let basic-draw-bar(idx, x, item, ..style) = {
    rect((x - bar-width / 2, 0),
         (rel: (bar-width, item.at(value-key))),
         ..bar-style(idx))
  }

  let clustered-draw-bar(idx, x, item, ..style) = {
    let x-offset = bar-width / 2
    let sub-values = value-key.map(k => item.at(k))
    let bar-width = bar-width / sub-values.len()

    for (sub-idx, sub) in sub-values.enumerate() {
      rect((x - x-offset + sub-idx * bar-width, 0),
           (rel: (bar-width, sub)),
           ..bar-style(sub-idx))
    }
  }

  let stacked-draw-bar(idx, x, item, ..style) = {
    let sub-values = value-key.map(k => item.at(k))

    move-to((x, 0))

    let sum = 0
    for (sub-idx, sub) in sub-values.enumerate() {
      move-to((x, sum))
      rect((x - bar-width / 2, sum),
           (rel: (bar-width, sub)),
           ..bar-style(sub-idx))
      sum += sub
    }
  }

  let stacked100-draw-bar(idx, x, item, ..style) = {
    let sum = value-key.map(k => item.at(k)).sum()
    for k in value-key {
      item.at(k) *= 100 / sum
    }

    stacked-draw-bar(idx, x, item, ..style)
  }

  let draw-data = (
    if mode == "basic" {basic-draw-bar} else
    if mode == "clustered" {clustered-draw-bar} else
    if mode == "stacked" {stacked-draw-bar} else
    if mode == "stacked100" {stacked100-draw-bar}
  )

  group(ctx => {
    let style = util.merge-dictionary(columnchart-default-style,
      styles.resolve(ctx.style, (:), root: "columnchart"))

    axes.scientific(size: size,
                    left: y,
                    right: none,
                    bottom: x,
                    top: none,
                    frame: "set",
                    ..style.axes)
    if data.len() > 0 {
      if type(bar-style) != "function" { bar-style = ((i) => bar-style) }

      axes.axis-viewport(size, x, y, {
        for (i, row) in data.enumerate() {
          draw-data(i, i, row)
        }
      })
    }
  })
}

#let radarchart(data,
                labels: none,
                value-key: auto,
                mode: "basic",
                size: 1,
                step: auto,
                data-style: palette.red) = {
  import draw: *

  if value-key == auto {
    if data.len() > 0 {
      value-key = (..range(data.first().len()))
    }
  }

  if type(size) != "array" {
    size = (size, size)
  }

  assert(type(value-key) == "array",
    message: "Argument value-key must be of type array")
  assert(value-key.len() >= 2,
    message: "Data needs to have at least 2 dimensions")

  let num-axes = value-key.len()

  let max-value = calc.max(..data.map(
    t => calc.max(..value-key.map(k => t.at(k)))))

  let axis-list = (
    for n in range(num-axes) {
      ((
        key: value-key.at(n),
        translate: (v) => {
          let angle = 90deg - 360deg / num-axes * n
          (v * calc.cos(angle), v * calc.sin(angle))
        }
      ),)
    }
  )

  if step == auto {
    step = axes.find-max-n-ticks(0, max-value, n: 7)
    if step == none {
      step = max-value / 7
    }
  }
  let num-steps = int(max-value / step)

  if type(data-style) != "function" {
    data-style = (i) => { data-style }
  }

  group(ctx => {
    let style = util.merge-dictionary(radarchart-default-style,
      styles.resolve(ctx.style, (:), root: "radarchart"))

    set-viewport((0, 0), size, bounds: (2 * max-value, 2 * max-value, 1))
    translate((max-value, max-value, 0))

    let scaling = (size.at(0) / (2 * max-value), size.at(1) / (2 * max-value))

    for i in range(axis-list.len()) {
      line((0, 0), (axis-list.at(i).translate)(max-value), ..style.grid)

      for n in range(num-steps + 1) {
        let v = step * n
        line((axis-list.at(calc.rem(i - 1, num-axes)).translate)(v),
             (axis-list.at(i).translate)(v), ..style.grid)
      }
    }

    for n in range(num-steps + 1) {
      let v = step * n
      content((axis-list.at(0).translate)(v), $#v$,
        anchor: "bottom-right",
        padding: style.label-padding / scaling.at(0))
    }

    let enum-keys = value-key.enumerate()
    for (i, item) in data.enumerate() {
      let pts = enum-keys.map(
        ((i, k)) => (axis-list.at(i).translate)(item.at(k)))

      let item-style = util.merge-dictionary(style, data-style(i))
      let mark-radius = (
        item-style.mark.size / scaling.at(0),
        item-style.mark.size / scaling.at(1)
      )

      // Fill data polygon
      //line(..pts, close: true, ..item-style)
       
      // Draw data points
      for pt in pts {
        circle(pt, ..item-style.mark, radius: mark-radius)
      }
    }
  })
}
