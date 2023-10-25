#import "../../draw.typ"

#let add-boxwhisker(
    data,
    axes: ("x", "y"),
    style: (:),
    box-width: 0.75,
    whisker-width: 0.5,
    mark: "*",
    mark-size: 0.2
) = {
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

    let max-value = calc.min(
        0,data.min,
        ..data.at("outliers", default: (0,))
    )

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
        data: (if "outliers" in data {data.outliers.map(it=>(data.x, it))} else {none}),
        style: style,
        plot-prepare: prepare,
        plot-stroke: stroke,
        mark: (if "outliers" in data {mark}),
        mark-size: mark-size,
        mark-style: (:),
        x-domain: (
            data.x - calc.max(whisker-width, box-width), 
            data.x + calc.max(whisker-width, box-width)),
        y-domain: (min-value, max-value),
    ),)
}