#import "canvas.typ": canvas

#let example(body, source) = {
  table(
    columns: (auto, auto),
    stroke: none,
    body,
    source
  )
}

#set page(
  numbering: "1/1",
  header: align(right)[The `canvas` package],
)

#set heading(numbering: "1.")

#align(center, text(16pt)[*The `canvas` package*])

#let linkurl(url, t) = {
  link(url)[#underline(text(fill: blue, t))]
}

#align(center)[
  Johannes Wolf and fenjalien \
  #linkurl("https://github.com/johannes-wolf/typst-canvas", "https://github.com/johannes-wolf/typst-canvas") \
  #linkurl("https://github.com/fenjalien/typst-canvas", "https://github.com/fenjalien/typst-canvas")
]

#set par(justify: true)

#outline(indent: true)
#pagebreak(weak: true)

= Introduction

This package provides a way to draw stuff using a similar API to #linkurl("https://processing.org/", "Processing") but with relative coordinates and anchors from #linkurl("https://tikz.dev/", "Tikz"). You also won't have to worry about accidentally drawing over other content as the canvas will automatically resize. And remember up is negative!

= Usage

This is the minimal starting point:
  ```typ
  #import "typst-canvas/canvas.typ": canvas

  #canvas({
    import "typst-canvas/draw.typ": *
    ...
  })
  ```
Note that draw functions are imported inside the scope of the `canvas` block. This is recommended as draw functions override Typst's functions such as `line`.

== Coordinates
There are four different ways to specify coordinates.
  + Absolute: `(x,y)` \
    "`x` units to the right and `y` units down from the origin."
  + Relative: `(rel: (x,y))` \
    "`x` units to the right and `y` units down from the previous coordinate."
  + Previous: `()` \
    "The previous coordinate."
  + Anchor: `(node: "name", at: "example")` or `"name.example"` \
    "The position of anchor `"example"` on node with name `"name"`." \
    See @anchors

== Anchors <anchors>
Anchors are named positions relative to named elements. 

To use an anchor of an element, you must give the element a name using the `name` parameter.
#example(
  canvas(background: gray.lighten(75%), {
    import "draw.typ": *
    circle((0,0), name: "circle")
    fill(red)
    stroke(none)
    circle("circle.left", radius: 0.3)
  }),
  [
    ```typ
    #canvas({
      import "draw.typ": *
      // Name the circle
      circle((0,0), name: "circle")
      
      // Draw a smaller red circle at "circle"'s left anchor
      fill(red)
      stroke(none)
      circle("circle.left", radius: 0.3)
    })
    ```
  ]
)

All elements will have default anchors based on its bounding box, they are: `center`, `left`, `right`, `above` and `below`. Some elements will have their own anchors.

Elements can be placed relative to its own anchors.
#example(
  canvas(background: gray.lighten(75%), {
    import "draw.typ": *
    circle((0,0), anchor: "left")
    fill(red)
    stroke(none)
    circle((0,0), radius: 0.3)
  }),
  [
    ```typ
    #canvas({
      import "draw.typ": *
      // An element does not have to be named 
      // in order to use its own anchors.
      circle((0,0), anchor: "left")

      // Draw a smaller red circle at the origin
      fill(red)
      stroke(none)
      circle("circle.left", radius: 0.3)
    })
    ```
  ]
)

#v(1cm)

= Reference
#set terms(indent: 4em)
```typ
#canvas(background: none, length: 1cm, debug: false, body)
```
  / `background`: A `color` to be used for the background of the canvas.
  / `length`: The `length` used to specify what 1 coordinate unit is.
  / `debug`: Shows the bounding boxes of each element when `true`.
  / `body`: A code block in which functions from `draw.typ` have been called.

== Elements

== Styles