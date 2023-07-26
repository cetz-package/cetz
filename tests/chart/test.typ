#set page(width: auto, height: auto)
#import "../../lib.typ"
#import lib: *

#let data1 = (
  ([15-24], 20.0),
  ([25-29], 17.2),
  ([30-34], 14.2),
  ([35-44], 29.3),
  ([45-54], 22.5),
  ([55+],   18.4),
).rev()

#let data2 = (
  ([15-24], 18.0, 20.1, 23.0, 17.0),
  ([25-29], 16.3, 17.6, 19.4, 15.3),
  ([30-34], 14.0, 15.3, 13.9, 18.7),
  ([35-44], 35.5, 26.5, 29.4, 25.8),
  ([45-54], 25.0, 20.6, 22.4, 22.0),
  ([55+],   19.9, 18.2, 19.2, 16.4),
).rev()

#box(stroke: 2pt + red, canvas({
  chart.barchart(mode: "basic",
                 size: (9, auto),
                 value-key: 1,
                 label-key: 0,
                 bar-width: .7,
                 x-tick-step: 5,
                 x-label: [x],
                 y-label: [y],
                 data1)
}))

#box(stroke: 2pt + red, canvas({
  chart.barchart(mode: "clustered",
                 size: (9, auto),
                 label-key: 0,
                 value-key: (..range(1, 5)),
                 bar-width: .9,
                 data2)
}))

#box(stroke: 2pt + red, canvas({
  chart.barchart(mode: "stacked",
                 size: (9, auto),
                 label-key: 0,
                 value-key: (..range(1, 5)),
                 bar-width: .7,
                 bar-style: palette.blue,
                 data2)
}))

#box(stroke: 2pt + red, canvas({
  chart.barchart(mode: "stacked100",
                 size: (9, auto),
                 label-key: 0,
                 value-key: (..range(1, 5)),
                 bar-width: .7,
                 bar-style: palette.blue,
                 data2)
}))
