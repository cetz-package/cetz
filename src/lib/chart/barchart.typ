#import "/src/lib/palette.typ"
#import "/src/lib/plot.typ"
#import "/src/draw.typ"
#import "/src/styles.typ"

#let barchart-default-style = (
  axes: (tick: (length: 0)),
  bar-width: .8,
  y-inset: 1,
)

/// Draw a bar chart. A bar chart is a chart that represents data with
/// rectangular bars that grow from left to right, proportional to the values
/// they represent. For examples see @barchart-examples.
///
/// *Style root*: `barchart`.
///
/// The `barchart` function is a wrapper of the `plot` API. Arguments passed
/// to `..plot-args` are passed to the `plot.plot` function.
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
/// - x-unit (content,auto): Tick suffix added to each tick label
/// - y-label (content,none): Y axis label
/// - x-label (content,none): x axis label
/// - ..plot-args (any): Arguments to pass to `plot.plot`
#let barchart(data,
              label-key: 0,
              value-key: 1,
              mode: "basic",
              size: (auto, 1),
              bar-style: palette.red,
              x-label: none,
              x-unit: auto,
              y-label: none,
              ..plot-args
              ) = {
  assert(type(label-key) in (int, str))
  if mode == "basic" {
    assert(type(value-key) in (int, str))
  } else {
    assert(type(value-key) == array)
  }

  if type(value-key) != array {
    value-key = (value-key,)
  }

  if type(size) != array {
    size = (size, auto)
  }
  if size.at(1) == auto {
    size.at(1) = (data.len() + 1)
  }

  let y-tic-list = data.enumerate().map(((i, t)) => {
    (i, t.at(label-key))
  })

  let x-unit = x-unit
  if x-unit == auto {
    x-unit = if mode == "stacked100" {[%]} else []
  }

  data = data.enumerate().map(((i, d)) => {
    (i, ..value-key.map(k => d.at(k)))
  })

  draw.group(ctx => {
    let style = styles.resolve(ctx.style, (:),
      root: "barchart", base: barchart-default-style)
    draw.set-style(..style)


    let y-inset = calc.max(style.y-inset, style.bar-width / 2)
    plot.plot(size: size,
              axis-style: "scientific-auto",
              x-label: x-label,
              x-grid: true,
              y-label: y-label,
              y-min: -y-inset,
              y-max: data.len() + y-inset - 1,
              y-tick-step: none,
              y-ticks: y-tic-list,
              plot-style: bar-style,
              ..plot-args,
    {
      plot.add-bar(data,
        mode: mode,
        bar-width: style.bar-width,
        axes: ("y", "x"))
    })
  })
}
