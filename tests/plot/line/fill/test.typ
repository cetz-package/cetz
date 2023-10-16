#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#let size = (6, 4)
#let f(x, y: 0) = y + calc.sin(x * 1deg)

/* Epigraph/Hypograph */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: size,
    x-tick-step: none,
    y-tick-step: none,
    {
      plot.add(domain: (-360, 360), epigraph: true, f)
      plot.add(domain: (-360, 360), hypograph: true, f)
    })
}))

/* Upper Half */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: size,
    x-tick-step: none,
    y-tick-step: none,
    y-min: 0,
    {
      plot.add(domain: (-360, 360), epigraph: true, f)
      plot.add(domain: (-360, 360), hypograph: true, f)
    })
}))

/* Lower Half */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: size,
    x-tick-step: none,
    y-tick-step: none,
    y-max: 0,
    {
      plot.add(domain: (-360, 360), epigraph: true, f)
      plot.add(domain: (-360, 360), hypograph: true, f)
    })
}))

/* To Y=0 Clipped on Y<1 */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: size,
    x-tick-step: none,
    y-tick-step: none,
    y-min: -1, y-max: 1,
    {
      plot.add(domain: (-360, 360), fill: true, f.with(y: -.5))
    })
}))

/* To Y=0 */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: size,
    x-tick-step: none,
    y-tick-step: none,
    y-min: -1, y-max: 1,
    {
      plot.add(domain: (-360, 360), fill: true, f)
    })
}))

/* To Y=0 Clipped on Y>1 */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: size,
    x-tick-step: none,
    y-tick-step: none,
    y-min: -1, y-max: 1,
    {
      plot.add(domain: (-360, 360), fill: true, f.with(y: +.5))
    })
}))

/* To Y=0 Offset +1.5 */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: size,
    x-tick-step: none,
    y-tick-step: none,
    y-min: 0, y-max: 1,
    {
      plot.add(domain: (-360, 360), fill: true, f.with(y: +1.5))
    })
}))

/* To Y=0 Offset -1.5 */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: size,
    x-tick-step: none,
    y-tick-step: none,
    y-min: -1, y-max: 0,
    {
      plot.add(domain: (-360, 360), fill: true, f.with(y: -1.5))
    })
}))

/* To Y=0 Out of range */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: size,
    x-tick-step: none,
    y-tick-step: none,
    y-min: 1, y-max: 2,
    {
      plot.add(domain: (-360, 360), fill: true, f)
    })
}))

/* Epigraph Full Fill */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: size,
    x-tick-step: none,
    y-tick-step: none,
    y-min: 1, y-max: 2,
    {
      plot.add(domain: (-360, 360), epigraph: true, f)
    })
}))

/* Hypograph Full Fill */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: size,
    x-tick-step: none,
    y-tick-step: none,
    y-min: -2, y-max: -1,
    {
      plot.add(domain: (-360, 360), hypograph: true, f)
    })
}))

/* Epigraph No Fill */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: size,
    x-tick-step: none,
    y-tick-step: none,
    y-min: -2, y-max: -1,
    {
      plot.add(domain: (-360, 360), epigraph: true, f)
    })
}))

/* Hypograph No Fill */
#box(stroke: 2pt + red, canvas({
  import draw: *

  plot.plot(size: size,
    x-tick-step: none,
    y-tick-step: none,
    y-min: 1, y-max: 2,
    {
      plot.add(domain: (-360, 360), hypograph: true, f)
    })
}))
