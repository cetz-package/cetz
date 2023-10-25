#import "../palette.typ"
#import "../plot.typ"
#import "../../draw.typ"
#import "../../canvas.typ"

#let boxwhisker-default-style = (
  axes: (tick: (length: -0.1)),
  grid: none,
)

#let boxwhisker( data,
                 size: (1, auto),
                 y-min: auto,
                 y-max: auto,
                 label-key: 0,
                 box-width: 0.75,
                 whisker-width: 0.5,
                 ..arguments
                 ) = {
    import draw: *

    if size.at(1) == auto {size.at(1) = (data.len() + 1)}

    let max-value = calc.max(
        0, 
        ..data.map(t => t.max),
        ..data.map(t => calc.max(..t.at("outliers", default: (0,))))
    )
    if y-max != auto { max-value = y-max }

    let min-value = calc.min(
        0, 
        ..data.map(t => t.max),
        ..data.map(t => calc.min(..t.at("outliers", default: (0,))))
    )
    if y-min != auto { min-value = y-min }

    let x-tic-list = data.enumerate().map(((i, t)) => {
        (i, t.at(label-key, default: i))
    })

    plot.plot(
        size: size,
        x-tick-step: auto,
        y-tick-step: auto,
        y-min: y-min,
        y-max: y-max,
        x-max: data.len() + 1,
        {
            for (i, row) in data.enumerate() {
                plot.add-boxwhisker(
                    ( x: i, ..row), 
                    box-width: box-width,
                    whisker-width: whisker-width,
                    style: (:)
                )
            }
        }
    )

/*
  let y-unit = y-unit
  if y-unit == auto {y-unit =  []}

  let x-axis = axes.axis(min: -1, max: data.len(),
                    label: x-label,
                    ticks: (grid: none,
                            step: none,
                            minor-step: none,
                            list: x-tic-list))
  let y-axis = axes.axis(min: min-value, max: max-value,
                    label: y-label,
                    ticks: (grid: none, step: y-tick-step,
                            minor-step: none,
                            unit: y-unit, decimals: 1,
                            list: y-ticks))

                            

  group(ctx => {
    let style = util.merge-dictionary(boxwhisker-default-style,
      styles.resolve(ctx.style, (:), root: "boxwhisker"))

    axes.scientific(size: size,
                    left: y-axis,
                    right: none,
                    bottom: x-axis,
                    top: none,
                    frame: "set",
                    ..style.axes)
    if data.len() > 0 {
      if type(bar-style) != function { bar-style = ((i) => bar-style) }

      axes.axis-viewport(size, x-axis, y-axis, {
        for (i, row) in data.enumerate() {
          draw-data(i, i, row)
        }
      })
    }
  })*/
}