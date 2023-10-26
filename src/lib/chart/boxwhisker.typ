#import "../palette.typ"
#import "../plot.typ"
#import "../../draw.typ"
#import "../../canvas.typ"

#let boxwhisker-default-style = (
  axes: (tick: (length: -0.1)),
  grid: none,
)

/// Add one or more box or whisker plots
///
/// - data (array, dictionary): dictionary or array of dictionaries containing the
///                             needed entries to plot box and whisker plot.
///
///                           *Examples:*
///                           - ```( x: 1 // Location on x-axis
///                                  outliers: (7, 65, 69), // Optional
///                                  min: 15, max: 60 // Minimum and maximum
///                                  q1: 25, // Quartiles
///                                  q2: 35,
///                                  q3: 50
///                                 )```
/// - size (array) : Size of chart. If the second entry is auto, it automatically scales to accomodate the number of entries plotted
/// - y-min (float) : Lower end of y-axis range. If auto, defaults to lowest outlier or lowest min.
/// - y-max (float) : Upper end of y-axis range. If auto, defaults to greatest outlier or greatest max.
/// - label-key (integer, string): Index in the array where labels of each entry is stored
/// - box-width (float): Width from edge-to-edge of the box of the box and whisker in plot units. Defaults to 0.75
/// - whisker-width (float): Width from edge-to-edge of the whisker of the box and whisker in plot units. Defaults to 0.5
/// - mark (string): Mark to use for plotting outliers. Set `none` to disable. Defaults to "x"
/// - mark-size (float): Size of marks for plotting outliers. Defaults to 0.15
/// - ..arguments (variadic): Additional arguments are passed to `plot.plot`
#let boxwhisker( data,
                 size: (1, auto),
                 y-min: auto,
                 y-max: auto,
                 label-key: 0,
                 box-width: 0.75,
                 whisker-width: 0.5,
                 mark: "*",
                 mark-size: 0.15,
                 ..arguments
                 ) = {
    // import draw: *

    if type(data) == dictionary { data = (data,) }

    if size.at(1) == auto {size.at(1) = (data.len() + 1)}

    let x-tic-list = data.enumerate().map(((i, t)) => {
        (i + 1, t.at(label-key, default: i))
    })

    plot.plot(
        size: size,
        x-tick-step: none,
        x-ticks: x-tic-list,
        y-min: y-min,
        y-max: y-max,
        x-label: none,
        ..arguments,
        {
            for (i, row) in data.enumerate() {
                plot.add-boxwhisker(
                    ( x: i + 1, ..row), 
                    box-width: box-width,
                    whisker-width: whisker-width,
                    style: (:),
                    mark: mark,
                    mark-size: mark-size
                )
            }
        }
    )

}