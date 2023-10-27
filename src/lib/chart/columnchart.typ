#import "../axes.typ"
#import "../palette.typ"
#import "../../draw.typ"
#import "../../util.typ"
#import "../../styles.typ"

#let columnchart-default-style = (
  axes: (tick: (length: 0))
)

#import "barcol-common.typ": *


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
/// - y-decimals (int): Number of y axis tick decimals
/// - y-format (string,function): Y axis tick format, `"float"`, `"sci"`
///                               or a callback of the form `float => content`.
/// - y-min (number,auto): Y axis minimum value
/// - y-max (number,auto): Y axis maximum value
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
                 y-format: "float",
                 y-decimals: 1,
                 y-label: none,
                 y-min: auto,
                 y-max: auto,
                 ) = {
  import draw: *

  assert(mode in barchart-modes,
    message: "Invalid columnchart mode")
  assert(type(label-key) in (int, str))
  if mode == "basic" {
    assert(type(value-key) in (int, str))
  } else {
    assert(type(value-key) == array)
  }

  if size.at(0) == auto {
    size.at(0) = (data.len() + 1)
  }

  let max-value = (barchart-max-value-fn.at(mode))(data, value-key)
  if y-max != auto {
    max-value = y-max
  }
  let min-value = (barchart-min-value-fn.at(mode))(data, value-key)
  if y-min != auto {
    min-value = y-min
  }

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
  let y = axes.axis(min: min-value, max: max-value,
                    label: y-label,
                    ticks: (grid: true, step: y-tick-step,
                            minor-step: none,
                            unit: y-unit, decimals: y-decimals,
                            format: y-format, list: y-ticks))

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
      if type(bar-style) != function { bar-style = ((i) => bar-style) }

      axes.axis-viewport(size, x, y, {
        for (i, row) in data.enumerate() {
          draw-data(i, i, row)
        }
      })
    }
  })
}
