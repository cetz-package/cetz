#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import chart: piechart

#let colors = gradient.linear(rgb("FFCCE5"), rgb("660033"))

// Outset items
#box(stroke: 2pt + red, canvas({
  import draw: *
  piechart(range(1,11), outset: 3, outset-offset: 25%, slice-style: colors)
}))

// Outset items + inner radius
#box(stroke: 2pt + red, canvas({
  import draw: *
  piechart(range(1,11), outset: 3, inner-radius: .5, outset-offset: 25%, slice-style: colors)
}))

// Outset items + arc shape
#box(stroke: 2pt + red, canvas({
  import draw: *
  piechart(range(1,5), outset-offset: 25%, slice-style: colors,
    start: 0deg, stop: 180deg)
}))

// Outset items + inner radius
#box(stroke: 2pt + red, canvas({
  import draw: *
  piechart(range(1,5), inner-radius: .5, outset-offset: 25%, slice-style: colors,
    start: 45deg, stop: 135deg)
}))

// Rotated Values
#box(stroke: 2pt + red, canvas({
  piechart(range(1,11), slice-style: colors, outer-label: (angle: auto, content: "VALUE"))
}))

// Rotated Percentages
#box(stroke: 2pt + red, canvas({
  piechart(range(10, 60, step: 10), slice-style: colors, outer-label: (angle: auto, content: "%"))
}))

// Inner Values
#box(stroke: 2pt + red, canvas({
  piechart(range(1,11), slice-style: colors, inner-label: (content: "VALUE"), radius: 2)
}))

// Inner Percentages
#box(stroke: 2pt + red, canvas({
  piechart(range(10, 60, step: 10), slice-style: colors, inner-label: (content: "%"), radius: 2)
}))

// Gap as canvas size
#box(stroke: 2pt + red, canvas({
  piechart(range(1,11), gap: .1, slice-style: colors)
}))

// Gap as canvas size + inner radius
#box(stroke: 2pt + red, canvas({
  piechart(range(1,11), gap: .1, inner-radius: .5, slice-style: colors)
}))

// Gap as angle
#box(stroke: 2pt + red, canvas({
  piechart(range(1,11), gap: 5deg, slice-style: colors, outer-label: (angle: auto))
}))

// Anchors
#box(stroke: 2pt + red, canvas({
  import draw: *
  piechart(range(1,11), slice-style: colors, name: "c", inner-radius: .5)
  for-each-anchor("c", n => {
    circle("c." + n, radius: .05)
  })
}))

// Keys
#box(stroke: 2pt + red, canvas({
  piechart(((value: 1, label: [One], o: false),
            (value: 1, label: [Two], o: true)), slice-style: colors,
    value-key: "value", label-key: "label", outer-label: (content: "LABEL", radius: 150%), outset-key: "o")
}))

// Keys
#box(stroke: 2pt + red, canvas({
  piechart(((value: 1, label: [One]),
            (value: 1, label: [Two],   o: 2%),
            (value: 1, label: [Three], o: 4%),
            (value: 1, label: [Four], o: 6%),
            (value: 1, label: [Five], o: 8%),
            (value: 1, label: [Six], o: 10%),
            (value: 1, label: [Seven], o: 12%),
            (value: 1, label: [Eight], o: 14%),),
            slice-style: colors,
    value-key: "value", label-key: "label", outer-label: (content: "LABEL", radius: 150%), outset-key: "o")
}))

// Clockwise rotation
#box(stroke: 2pt + red, canvas({
  import draw: *
  piechart(range(1,4), clockwise: true, slice-style: (green, yellow, red))
}))

// Counter clockwise rotation
#box(stroke: 2pt + red, canvas({
  import draw: *
  piechart(range(1,4), clockwise: false, slice-style: (green, yellow, red))
}))
