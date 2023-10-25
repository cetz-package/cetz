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
    if y-max == auto { y-max = max-value }

    let min-value = calc.min(
        0, 
        ..data.map(t => t.max),
        ..data.map(t => calc.min(..t.at("outliers", default: (0,))))
    )
    if y-min == auto { y-min = min-value}

    let x-tic-list = data.enumerate().map(((i, t)) => {
        (i + 1, t.at(label-key, default: i))
    })

    plot.plot(
        size: size,
        x-tick-step: none,
        x-ticks: x-tic-list,
        y-min: y-min,
        y-max: y-max,
        x-max: data.len() + 1,
        ..arguments,
        {
            for (i, row) in data.enumerate() {
                plot.add-boxwhisker(
                    ( x: i + 1, ..row), 
                    box-width: box-width,
                    whisker-width: whisker-width,
                    style: (:)
                )
            }
        }
    )

}