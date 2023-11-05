#import "../axes.typ"
#import "../palette.typ"
#import "../../draw.typ"
#import "../../util.typ"
#import "../../styles.typ"


#let barchart-default-style = (
  axes: (tick: (length: 0))
)

#import "barcol-common.typ": *


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
/// - x-decimals (int): Number of x axis tick decimals
/// - x-format (string,function): X axis tick format, `"float"`, `"sci"`
///                               or a callback of the form `float => content`.
/// - x-min (number,auto): X axis minimum value
/// - x-max (number,auto): X axis maximum value
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
              x-decimals: 1,
              x-format: "float",
              x-min: auto,
              x-max: auto,
              x-label: none,
              y-label: none,
              ) = {
  import draw: *

  assert(mode in barchart-modes,
    message: "Invalid barchart mode")
  assert(type(label-key) in (int, str))
  if mode == "basic" {
    assert(type(value-key) in (int, str))
  } else {
    assert(type(value-key) == array)
  }

  if size.at(1) == auto {
    size.at(1) = (data.len() + 1)
  }

  let max-value = (barchart-max-value-fn.at(mode))(data, value-key)
  if x-max != auto {
    max-value = x-max
  }
  let min-value = (barchart-min-value-fn.at(mode))(data, value-key)
  if x-min != auto {
    min-value = x-min
  }

  let y-tic-list = data.enumerate().map(((i, t)) => {
    (i, t.at(label-key))
  })

  let x-unit = x-unit
  if x-unit == auto {
    x-unit = if mode == "stacked100" {[%]} else []
  }
  
  let x = axes.axis(min: min-value, max: max-value,
                    label: x-label,
                    ticks: (grid: true, step: x-tick-step,
                            minor-step: none,
                            unit: x-unit, decimals: x-decimals,
                            format: x-format, list: x-ticks))
  let y = axes.axis(min: data.len(), max: -1,
                    label: y-label,
                    ticks: (grid: true,
                            step: none,
                            minor-step: none,
                            list: y-tic-list))

  let basic-draw-bar(idx, y, item, ..style) = {
    rect(
      (0, y - bar-width / 2),
      (rel: (item.at(value-key), bar-width)),
      ..bar-style(idx)
    )
  }

  let clustered-draw-bar(idx, y, item, ..style) = {
    let y-offset = bar-width / 2
    let sub-values = value-key.map(k => item.at(k))
    let bar-width = bar-width / sub-values.len()

    for (sub-idx, sub) in sub-values.enumerate() {
      rect(
        (0, y - y-offset + sub-idx * bar-width),
        (rel: (sub, bar-width)),
        ..bar-style(sub-idx)
      )
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

    axes.scientific(
      size: size,
      left: y,
      right: none,
      bottom: x,
      top: none,
      frame: "set",
      ..style.axes
    )
    if data.len() > 0 {
      if type(bar-style) != function { bar-style = ((i) => bar-style) }
      axes.axis-viewport(size, x, y, {
        for (i, row) in data.enumerate() {
          draw-data(i, i, row)
        }
      })
    }
  })
}