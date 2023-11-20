#import "/src/lib/plot.typ"
#import "/src/draw.typ"
#import "/src/styles.typ"

#let boxwhisker-default-style = (
  axes: (tick: (length: 0)),
  box-width: 0.75,
  whisker-width: 0.5,
  mark-size: 0.15,
)

/// Add one or more box or whisker plots.
///
/// #example(```
///   cetz.chart.boxwhisker(size: (2,2), label-key: none,
///     y-min: 0, y-max: 70, y-tick-step: none,
///     (x: 1, min: 15, max: 60,
///      q1: 25, q2: 35, q3: 50))
/// ```)
///
/// *Style Root*: boxwhisker
///
/// - data (array, dictionary): Dictionary or array of dictionaries containing the
///   needed entries to plot box and whisker plot.
///
///   See `plot.add-boxwhisker` for more details.
///
///   *Examples:*
///   - ```typc
///     (x: 1                   // Location on x-axis
/// outliers: (7, 65, 69), // Optional outliers
/// min: 15, max: 60       // Minimum and maximum
/// q1: 25,                // Quartiles: Lower
/// q2: 35,                //            Median
/// q3: 50)                //            Upper
///   ```
/// - size (array) : Size of chart. If the second entry is auto, it automatically scales to accommodate the number of entries plotted
/// - label-key (integer, string): Index in the array where labels of each entry is stored
/// - mark (string): Mark to use for plotting outliers. Set `none` to disable. Defaults to "x"
/// - ..plot-args (any): Additional arguments are passed to `plot.plot`
#let boxwhisker(data,
                size: (1, auto),
                label-key: 0,
                mark: "*",
                ..plot-args
                ) = {
  if type(data) == dictionary { data = (data,) }

  if type(size) != array {
    size = (size, auto)
  }
  if size.at(1) == auto {
    size.at(1) = (data.len() + 1)
  }

  let x-tick-list = data.enumerate().map(((i, t)) => {
    (i + 1, if label-key != none { t.at(label-key, default: i) } else { [] })
  })

  draw.group(ctx => {
    let style = styles.resolve(ctx.style, (:), root: "boxwhisker", base: boxwhisker-default-style)
    draw.set-style(..style)

    plot.plot(
      size: size,
      axis-style: "scientific-auto",
      x-tick-step: none,
      x-ticks: x-tick-list,
      y-grid: true,
      x-label: none,
      y-label: none,
      ..plot-args,
      {
        for (i, row) in data.enumerate() {
          plot.add-boxwhisker(
            (x: i + 1, ..row),
            box-width: style.box-width,
            whisker-width: style.whisker-width,
            style: (:),
            mark: mark,
            mark-size: style.mark-size
          )
        }
      })
  })
}
