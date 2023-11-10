#import "@preview/cetz:0.2.0"

#set page(width: auto, height: auto, margin: .5cm)

#cetz.canvas({
  import cetz.draw: *

  let chart(..values, name: none) = {
    let values = values.pos()

    let offset = 0
    let total = values.fold(0, (s, v) => s + v.at(0))

    let segment(from, to) = {
      merge-path(close: true, {
        line((0, 0), (rel: (360deg * from, 1)))
        arc((), start: from * 360deg, stop: to * 360deg, radius: 1)
      })
    }

    group(name: name, {
      stroke((paint: black, join: "round"))

      let i = 0
      for v in values {
        fill(v.at(1))
        let value = v.at(0) / total

        // Draw the segment
        segment(offset, offset + value)

        // Place an anchor for each segment
        anchor(v.at(2), (offset * 360deg + value * 180deg, .75))

        offset += value
      } 
    })
  }

  // Draw the chart
  chart((10, red, "red"),
        (3, blue, "blue"),
        (1, green, "green"),
        name: "chart")
  
  set-style(mark: (fill: white, start: "o", stroke: black),
            content: (padding: .1))

  // Draw annotations
  line("chart.red", ((), "-|", (2, 0)))
  content((), [Red], anchor: "west")

  line("chart.blue", (1, -1), ((), "-|", (2,0)))
  content((), [Blue], anchor: "west")

  line("chart.green", ((), "-|", (2,0)))
  content((), [Green], anchor: "west")
})
