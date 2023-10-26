#import "../../draw.typ"
#import "../../util.typ"

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
/// - axes (array): Name of the axes to use ("x", "y"), note that not all
///                 plot styles are able to display a custom axis!
/// - style (style): Style to use, can be used with a palette function
/// - box-width (float): Width from edge-to-edge of the box of the box and whisker in plot units. Defaults to 0.75
/// - whisker-width (float): Width from edge-to-edge of the whisker of the box and whisker in plot units. Defaults to 0.5
/// - mark (string): Mark to use for plotting outliers. Set `none` to disable. Defaults to "x"
/// - mark-size (float): Size of marks for plotting outliers. Defaults to 0.15
#let add-boxwhisker(
    data,
    axes: ("x", "y"),
    style: (:),
    box-width: 0.75,
    whisker-width: 0.5,
    mark: "*",
    mark-size: 0.15
) = {

    if type(data) == array {
        for it in data{
            add-boxwhisker(
                it,
                axes:axes,
                style: style,
                box-width: box-width,
                whisker-width: whisker-width,
                mark: mark,
                mark-size: mark-size
            )
        }
        return
    }

    assert( "x" in data, message: "Specify the x value at which to display the box and whisker")
    assert( "min" in data, message: "Specify the q1, the minimum excluding outliers")
    assert( "q1" in data, message: "Specify the q1, the lower quartile")
    assert( "q2" in data, message: "Specify the q2, the median")
    assert( "q3" in data, message: "Specify the q3, the upper quartile")
    assert( "max" in data, message: "Specify the q1, the minimum excluding outliers")

    // Calculate y-domain

    let max-value = calc.max(
        0,data.max,
        ..data.at("outliers", default: (0,))
    )

    let min-value = calc.min(
        0,data.min,
        ..data.at("outliers", default: (0,))
    )

    let max-value = util.max(data.max, ..data.at("outliers", default: ()))
    let min-value = util.min(data.min, ..data.at("outliers", default: ()))

    let prepare(self, ctx) = {
        return self
    }

    let stroke(self, ctx) = {
        let data = self.bw-data

        // Box
        draw.rect((data.x - box-width / 2, data.q1),
             (data.x + box-width / 2, data.q3),
             ..self.style)

        // Mean
        draw.line((data.x - box-width / 2, data.q2),
             (data.x + box-width / 2, data.q2),
            ..self.style)

        // whiskers
        let whisker(x, start, end) = {
            draw.line((x, start),(x, end))
            draw.line((x - whisker-width / 2, end),(x + whisker-width / 2, end))
        }

        whisker(data.x, data.q3, data.max)
        whisker(data.x, data.q1, data.min)
    }

    ((
        type: "boxwhisker",
        axes: axes,
        bw-data: data,
        style: style,
        plot-prepare: prepare,
        plot-stroke: stroke,
        x-domain: (
            data.x - calc.max(whisker-width, box-width), 
            data.x + calc.max(whisker-width, box-width)),
        y-domain: (min-value, max-value),
    ) + (if "outliers" in data { (
        data: data.outliers.map(it=>(data.x, it)),
        mark: mark,
        mark-size: mark-size,
        mark-style: (:)
    ) }),)
}