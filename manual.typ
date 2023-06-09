#import "canvas.typ": canvas

#let canvas-background = gray.lighten(75%)

#let example(body, source, ..args, vertical: false) = {
  block(if vertical {
    align(
      center, 
      stack(
        dir: ttb,
        spacing: 1em,
        block(
          canvas(body, ..args),
          fill: canvas-background,
          inset: 1em
        ),
        align(left, source)
      )
    )
  } else {
    table(
      columns: (auto, auto),
      stroke: none,
      fill: (x,y) => (canvas-background, none).at(x),
      align: (x,y) => (center, left).at(x),
      canvas(body, ..args),
      source
    )
  }, breakable: false)
}

#let def-arg(term, type, default: none, description) = {
  stack(dir: ltr, [/ #term: #type \ #description], align(right, if default != none {[(default: #default)]}))
  
}

#let br() = {
  v(0.5cm)
  line(length: 100%)
}

#set page(
  numbering: "1/1",
  header: align(right)[The `canvas` package],
)

#set heading(numbering: "1.")
#set terms(indent: 1em)

#align(center, text(16pt)[*The `canvas` package*])

#let linkurl(url, t) = {
  link(url)[#underline(text(fill: blue, t))]
}

#align(center)[
  #linkurl("https://github.com/johannes-wolf", "Johannes Wolf") and #linkurl("https://github.com/fenjalien","fenjalien") \
  #linkurl("https://github.com/johannes-wolf/typst-canvas", "https://github.com/johannes-wolf/typst-canvas")
]

#set par(justify: true)

#outline(indent: true, depth: 3)
#pagebreak(weak: true)

= Introduction

This package provides a way to draw stuff using a similar API to #linkurl("https://processing.org/", "Processing") but with relative coordinates and anchors from #linkurl("https://tikz.dev/", "Tikz"). You also won't have to worry about accidentally drawing over other content as the canvas will automatically resize. And remember: up is positive!

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

== Argument Types
Argument types in this document are formatted in `monospace` and encased in angle brackets `<>`. Types such as `<integer>` and `<content>` are the same as Typst but additional are required:
  / `<coordinate>`: Any coordinate system. See @coordinate-systems.
  / `<number>`: `<integer> or <float>`

== Anchors <anchors>
Anchors are named positions relative to named elements. 

To use an anchor of an element, you must give the element a name using the `name` argument.
#example({
    import "draw.typ": *
    circle((0,0), name: "circle")
    fill(red)
    stroke(none)
    circle("circle.left", radius: 0.3)
  },
  [```typ
  #canvas({
    import "typst-canvas/draw.typ": *
    // Name the circle
    circle((0,0), name: "circle")
    
    // Draw a smaller red circle at "circle"'s left anchor
    fill(red)
    stroke(none)
    circle("circle.left", radius: 0.3)
  })
  ```]
)

All elements will have default anchors based on their bounding box, they are: `center`, `left`, `right`, `above`/`top` and `below`/`bottom`, `top-left`, `top-right`, `bottom-left`, `bottom-right`. Some elements will have their own anchors.

Elements can be placed relative to their own anchors.
#example({
    import "draw.typ": *
    circle((0,0), anchor: "left")
    fill(red)
    stroke(none)
    circle((0,0), radius: 0.3)
  },
  [```typ
  #canvas({
    import "typst-canvas/draw.typ": *
    // An element does not have to be named 
    // in order to use its own anchors.
    circle((0,0), anchor: "left")

    // Draw a smaller red circle at the origin
    fill(red)
    stroke(none)
    circle((0,0), radius: 0.3)
  })
  ```]
)


= Draw Function Reference

== Canvas
```typ
#canvas(background: none, length: 1cm, debug: false, body)
```
#def-arg("background", `<color>`, default: "none", "A color to be used for the background of the canvas.")
#def-arg("length", `<length>`, default: "1cm", "Used to specify what 1 coordinate unit is.")
#def-arg("debug", `<bool>`, default: "false", "Shows the bounding boxes of each element when `true`.")
#def-arg("body", none, [A code block in which functions from `draw.typ` have been called.])

== Styling <styling>
The fill and stroke of drawn elements can be set globally by using the `fill(color)` and `stroke(stroke)` functions. See the fill and stroke parameters of Typst's path function to see the types accepted (#text(blue)[https://typst.app/docs/reference/visualize/path/]). You can set the fill and stroke of individual elements by using their `fill` and `stroke` arguments.

#example({
    import "draw.typ": *

    fill(red)
    stroke(none)
    rect((0,0), (1,1))

    line((0, -1.5), (0.5, -0.5), (1, -1.5), close: true, fill: blue, stroke: (dash: "dashed"))

    circle((0.5, -2.5), radius: 0.5, fill: green)
  },
  [
  ```typ
  #canvas({
    import "typst-canvas/draw.typ": *
    // Set the global fill to red
    fill(red)
    // Set no global stroke
    stroke(none)
    // Draws a red rectangle
    rect((0,0), (1,1))
    // Draws a blue triangle with dashed edges
    line((0, -1.5), (0.5, -0.5), (1, -1.5), 
      close: true, fill: blue, stroke: (dash: "dashed"))
    // Draws a green circle
    circle((0.5, -2.5), radius: 0.5, fill: green)
  })
  ```])

== Elements

=== Line
Draws a line (a direct path between two points) to the canvas. If multiplie coordinates are given, a line is drawn between each consecutive one.

```typ
#line(..pts, mark-begin: none, mark-end: none, mark-size: auto, name: none, fill: auto, stroke: auto)
```
#def-arg("..pts", `<arguments of coordinates>`, [Coordinates to draw the lines between. A minimum of two must be given.])
#def-arg("mark-begin", `<string>`, [The type of arrow to draw at the start of the line. See @arrow-heads.])
#def-arg("mark-end", `<string>`, [The type of arrow to draw at the end of the line.])
#def-arg("mark-size", `<number>`, default: "0.15", [The size of the marks.])
#def-arg("name", `<string>`, [Sets the name of element for use with anchors.])
#def-arg("fill", [`none` or `auto` or `<color>`], default: auto, [Sets the fill of the path of lines. If `auto` the global fill is used. See @styling.])
#def-arg("stroke", [`none` or `auto` or `<length>` or `<color>` or `<color>` or `<dictionary>` \ or `<stroke>`], default: auto, [Sets the stroke of the lines. If `auto` the global stroke is used. See @styling.])

#example({
    import "draw.typ": *
    line((-1.5, 0), (1.5, 0))
    line((0, -1.5), (0, 1.5))
  },
  [
  ```typ
  #canvas({
    import "typst-canvas/draw.typ": *
    line((-1.5, 0), (1.5, 0))
    line((0, -1.5), (0, 1.5))
  })
  ```])

=== Rectangle
Draws a rectangle to the canvas.

```typ
#rect(a, b, name: none, fill: auto, stroke: auto)
```
#def-arg("a", `<coordinate>`, [The top left coordinate of the rectangle.])
#def-arg("b", `<coordinate>`, [The bottom right coordinate of the rectangle.])

#example({
    import "draw.typ": *
    rect((-1.5, 1.5), (1.5, -1.5))
  },
  [```typ
  #canvas({
    import "typst-canvas/draw.typ": *
    rect((-1.5, 1.5), (1.5, -1.5))
  })
  ```])

=== Arc
Draws an arc to the canvas. Exactly two of the three values `start`, `stop`, and `delta` should be defined.
```typ
#arc(position, start: auto, stop: auto, delta: auto, radius: 1, name: none, anchor: none, fill: auto, stroke: auto, mode: "OPEN")
```
#def-arg("position", `<coordinate>`, [The coordinate to start drawing the arc from.])
#def-arg("start", `<angle>`, [The angle to start the arc.])
#def-arg("stop", `<angle>`, [The angle to stop the arc.])
#def-arg("delta", `<angle>`, [The angle that is added to start or removed from stop.])
#def-arg("radius", `<number>`, [The radius of the arc.])
#def-arg("mode", `<string>`, [The options are "OPEN" (the default, just the arc), "CLOSE" (a circular segment) and "PIE" (a circular sector).])

#example({
    import "draw.typ": *
    arc((0,0), start: 45deg, stop: 135deg)
    arc((0,-0.5), start: 45deg, delta: 90deg, mode: "CLOSE")
    arc((0,-1), stop: 135deg, delta: 90deg, mode: "PIE")
  },
  [```typ
  #canvas({
    import "typst-canvas/draw.typ": *
    arc((0,0), start: 45deg, stop: 135deg)
    arc((0,-0.5), start: 45deg, delta: 90deg, mode: "CLOSE")
    arc((0,-1), stop: 135deg, delta: 90deg, mode: "PIE")
  })
  ```]
)

=== Circle
Draws a circle to the canvas. An ellipse can be drawn by passing an array of length two to the `radius` argument to specify its `x` and `y` radii.

```typ
#circle(center, radius: 1, name: none, anchor: none, fill: auto, stroke: auto)
```
#def-arg("center", `<coordinate>`, [The coordinate of the circle's origin.])
#def-arg("radius", `<number> or <length> or <array of <number> or <length>>`, default: "1", [The circle's radius. If an array is given an ellipse will be drawn where the first item is the `x` radius and the second item is the `y` radius.])

#example({
    import "draw.typ": *
    circle((0,0))
    circle((0,-2), radius: (0.75, 0.5))
  },
  [```typ
  #canvas({
    import "typst-canvas/draw.typ": *
    circle((0,0))
    // Draws an ellipse
    circle((0,-2), radius: (0.75, 0.5))
  })
  ```]
)

=== Bezier
Draws a bezier curve with 1 or 2 control points to the canvas.

```typ
#bezier(start, end, ..ctrl, samples: 100, name: none, fill: auto, stroke: auto)
```
#def-arg("start", `<coordinate>`, "The coordinate to start drawing the bezier curve from.")
#def-arg("end", `<coordinate>`, "The coordinate to draw the bezier curve to.")
#def-arg("..ctrl", `<coordinate>`, "An array of one or two coordinates to specify the contorl points of the bezier curve.")
#def-arg("samples", `<integer>`, "The number of lines used to construct the curve.")

#example({
    import "draw.typ": *
    bezier((0, 0), (2, 0), (1, 1))
    bezier((0, -1), (2, -1), (.5, -2), (1.5, 0))
  },
  [```typ
  #canvas({
    import "typst-canvas/draw.typ": *
    bezier((0, 0), (2, 0), (1, 1))
    bezier((0, -1), (2, -1), (.5, -2), (1.5, 0))
  })
  ```]
)

=== Content
Draws a content block to the canvas.

```typ
#content(pt, ct, angle: 0deg, name: none, anchor: none)
```
#def-arg("pt", `<coordinate>`, "The coordinate of the center of the content block.")
#def-arg("ct", `<content>`, "The content block.")
#def-arg("angle", `<angle>`, [The angle to rotate the content block by. Uses Typst's `rotate` function.])

#example({
    import "draw.typ": *
    content((0,0), [Hello World!])
  },
  [```typ
  #canvas({
    import "typst-canvas/draw.typ": *
    content((0,0), [Hello World!])
  })
  ```]
)

=== Grid
Draws a grid to the canavas.

```typ
#grid(from, to, step: 1, help-lines: false, name: none, fill: auto, stroke: auto)
```
#def-arg("from", `<coordinate>`, "Specifies the bottom left position of the grid.")
#def-arg("to", `<coordinate>`, "Specifies the top right position of the grid.")
#def-arg("step", `<number> or <length> or <array of <number> or <length>>`, [The stepping in both $x$ and $y$ directions. An array can be given to specify the stepping for each direction.])
#def-arg("help-lines", `<bool>`, default: "false", [Styles the grid to look "subdued" by using thin gray lines (`0.2pt + gray`)])

#example({
    import "draw.typ": *
    grid((0,0), (3,3), help-lines: true)
  },
  [```typ
  #canvas({
    import "typst-canvas/draw.typ": *
    grid((0,0), (3,2), help-lines: true)
  })
  ```]
)

== Arrow Heads <arrow-heads>
Arrow heads -- _marks_ -- can be drawn using the `arrow-head` function
or as start/end marks of paths (`line`). Arrow heads are filled using the
current fill color.

#example({
  import "draw.typ": *
  stroke((paint: gray, dash: "dotted"))
  line((1,-1), (1, 5))
  stroke(black); fill(black)
  line((0, 0), (1, 0), mark-end: ">", mark-size: .5)
  line((0, 1), (1, 1), mark-end: "<", mark-size: .5)
  line((0, 2), (1, 2), mark-end: "|", mark-size: .5)
  line((0, 3), (1, 3), mark-end: "o", mark-size: .5)
  line((0, 4), (1, 4), mark-end: "<>", mark-size: .5)
},
[```typ
  #canvas({
    import "typst-canvas/draw.typ": *
    stroke((paint: gray, dash: "dotted"))
    line((1,-1), (1, 5))
    stroke(black); fill(black)
    line((0, 4), (1, 4), mark-end: "<>")
    line((0, 3), (1, 3), mark-end: "o")
    line((0, 2), (1, 2), mark-end: "|")
    line((0, 1), (1, 1), mark-end: "<")
    line((0, 0), (1, 0), mark-end: ">")
  })
  ```]
)

= Coordinate Systems <coordinate-systems>
A _coordinate_ is a position on the canvas on which the picture is drawn. They take the form of dictionaries and the following sub-sections define the key value pairs for each system. Some systems have a more implicit form as an array of values and `typst-canvas` attempts to infer the system based on the element types.


== XYZ <coordinate-xyz>
Defines a point `x` units right, `y` units upward, and `z` units away.

#def-arg("x", [`<number>` or `<length>`], default: 0, [The number of units in the `x` direction.])
#def-arg("y", [`<number>` or `<length>`], default: 0, [The number of units in the `y` direction.])
#def-arg("z", [`<number>` or `<length>`], default: 0, [The number of units in the `z` direction.])

The implicit form can be given as an array of two or three `<number>` or `<length>`, as in `(x,y)` and `(x,y,z)`.

#example(
  {
    import "draw.typ": *
    line((0, 0), (x: 1))
    line((0, 0), (y: 1))
    line((0, 0), (z: 1))

    // Implicit form
    line((0, -2), (1, -2))
    line((0, -2), (0, -1, 0))
    line((0, -2), (0, -2, 1))
  },
  [```typ
  #import "typst-canvas/canvas.typ": canvas
  #canvas({
    import "typst-canvas/draw.typ": *

    line((0,0), (x: 1))
    line((0,0), (y: 1))
    line((0,0), (z: 1))

    // Implicit form
    line((0, -2), (1, -2))
    line((0, -2), (0, -1, 0))
    line((0, -2), (0, -2, 1))
  })
  ```]
)


== Previous <previous>
Use this to reference the position of the previous coordinate passed to a draw function. This will never reference the position of a coordinate used in to define another coordinate. It takes the form of an empty array `()`. The previous position initially will be `(0, 0, 0)`.

#example(
  {
    import "draw.typ": *
    line((0,0), (1, 1))
    circle(())
  },
  [```typ
  #import "typst-canvas/canvas.typ": canvas
  #canvas({
    import "typst-canvas/draw.typ": *
    line((0,0), (1, 1))

    // Draws a circle at (1,1)
    circle(())
  })
  ```]
)

== Relative <coordinate-relative>
Places the given coordinate relative to the previous coordinate. Or in other words, for the given coordinate, the previous coordinate will be used as the origin. Another coordinate can be given to act as the previous coordinate instead.

#def-arg("rel", `<coordinate>`, "The coordinate to be place relative to the previous coordinate.")
#def-arg("update", `<bool>`, default: true, "When false the previous position will not be updated.")
#def-arg("to", `<coordinate>`, default: (), "The coordinate to treat as the previous coordinate.")

In the example below, the red circle is placed one unit below the blue circle. If the blue circle was to be moved to a different position, the red circle will move with the blue circle to stay one unit below.

#example({
  import "draw.typ": *
  stroke(blue)
  circle(())
  stroke(red)
  circle((rel: (0, -1)))
  },
  [```typ
  #import "typst-canvas/canvas.typ": canvas
  #canvas({
    import "typst-canvas/draw.typ": *
    stroke(blue)
    circle((0,0))
    stroke(red)
    circle((rel: (0, -1)))
  })
  ```]
)

== Polar
Defines a point a `radius` distance away from the origin at the given `angle`. An angle of zero degrees. An angle of zero degrees is to the right, a degree of 90 is upward.

#def-arg("angle", `<angle>`, [The angle of the coordinate.])
#def-arg("radius", `<number> or <length> or <array of length or number>`, [The distance from the origin. An array can be given, in the form `(x, y)` to define the `x` and `y` radii of an ellipse instead of a circle.])

#example(
  {
    import "draw.typ": *
    line((0,0), (angle: 30deg, radius: 1cm))
  },
  [```typ
  #import "typst-canvas/canvas.typ": canvas
  #canvas({
    import "typst-canvas/draw.typ": *
    line((0,0), (angle: 30deg, radius: 1cm))
  })
  ```]
)

The implicit form is an array of the angle then the radius `(angle, radius)` or `(angle, (x, y))`. 

#example(
  {
    import "draw.typ": *
    line((0,0), (30deg, 1), (60deg, 1), (90deg, 1), (120deg, 1), (150deg, 1), (180deg, 1),)
  },
  [```typ
  #import "typst-canvas/canvas.typ": canvas
  #canvas({
    import "typst-canvas/draw.typ": *
    line((0,0), (30deg, 1), (60deg, 1), 
      (90deg, 1), (120deg, 1), (150deg, 1), (180deg, 1))
  })
  ```]
)

== Barycentric
In the barycentric coordinate system a point is expressed as the linear combination of multiple vectors. The idea is that you specify vectors $v_1$, $v_2$ ..., $v_n$ and numbers $alpha_1$, $alpha_2$, ..., $alpha_n$. Then the barycentric coordinate specified by these vectors and numbers is $ (alpha_1 v_1 + alpha_2 v_1 + dots.c + alpha_n v_n)/(alpha_1 + alpha_2 + dots.c + alpha_n) $

#def-arg("bary", `<dictionary>`, [A dictionary where the key is a named element and the value is a `<float>`. The `center` anchor of the named element is used as $v$ and the value is used as $a$.])

#example(
  vertical: true,
  {
    import "draw.typ": *
    circle((90deg, 3), radius: 0, name: "content")
    circle((210deg, 3), radius: 0, name: "structure")
    circle((-30deg, 3), radius: 0, name: "form")

    for (c, a) in (("content", "bottom"), ("structure", "top-right"), ("form", "top-left")) {
      content(c, box(c + " oriented", inset: 5pt), anchor: a)
    }

    stroke(gray + 1.2pt)
    line("content", "structure", "form", close: true)

    for (c, s, f, cont) in (
      (0.5, 0.1, 1, "PostScript"),
      (1, 0, 0.4, "DVI"),
      (0.5, 0.5, 1, "PDF"),
      (0, 0.25, 1, "CSS"),
      (0.5, 1, 0, "XML"),
      (0.5, 1, 0.4, "HTML"),
      (1, 0.2, 0.8, "LaTeX"),
      (1, 0.6, 0.8, "TeX"),
      (0.8, 0.8, 1, "Word"),
      (1, 0.05, 0.05, "ACII")
    ) {
      content((bary: (content: c, structure: s, form: f)), cont)
    }
  },
  [```typ
  #import "typst-canvas/canvas.typ": canvas
  #canvas({
    import "typst-canvas/draw.typ": *
    circle((90deg, 3), radius: 0, name: "content")
    circle((210deg, 3), radius: 0, name: "structure")
    circle((-30deg, 3), radius: 0, name: "form")

    for (c, a) in (
      ("content", "bottom"), 
      ("structure", "top-right"), 
      ("form", "top-left")
    ) {
      content(c, box(c + " oriented", inset: 5pt), anchor: a)
    }

    stroke(gray + 1.2pt)
    line("content", "structure", "form", close: true)

    for (c, s, f, cont) in (
      (0.5, 0.1, 1, "PostScript"),
      (1, 0, 0.4, "DVI"),
      (0.5, 0.5, 1, "PDF"),
      (0, 0.25, 1, "CSS"),
      (0.5, 1, 0, "XML"),
      (0.5, 1, 0.4, "HTML"),
      (1, 0.2, 0.8, "LaTeX"),
      (1, 0.6, 0.8, "TeX"),
      (0.8, 0.8, 1, "Word"),
      (1, 0.05, 0.05, "ACII")
    ) {
      content((bary: (content: c, structure: s, form: f)), cont)
    }
  })
  ```]
)

== Anchor
Defines a point relative to a named element using anchors, see @anchors.

#def-arg("name", `<string>`, [The name of the element that you wish to use to specify a coordinate.])
#def-arg("anchor", `<string>`, [An anchor of the element. If one is not given a default anchor will be used. On most elements this is `center` but it can be different.])

You can also use implicit syntax of a dot seperated string in the form `"name.anchor"`.

#example(
  {
    import "draw.typ": *

    line((0,0), (3,2), name: "line")
    circle("line.end", name: "circle")
    rect("line.start", "circle.left")
  },
  [```typ
  #import "typst-canvas/canvas.typ": canvas

  #canvas({
    import "typst-canvas/draw.typ": *
    line((0,0), (3,2), name: "line")
    circle("line.end", name: "circle")
    rect("line.start", "circle.left")
  })
  ```]
)

== Tangent
This system allows you to compute the point that lies tangent to a shape. In detail, consider an element and a point. Now draw a straight line from the point so that it "touches" the element (more formally, so that it is _tangent_ to this element). The point where the line touches the shape is the point referred to by this coordinate system.

#def-arg("element", `<string>`, [The name of the element on whose border the tangent should lie.])
#def-arg("point", `<coordinate>`, [The point through which the tangent should go.])
#def-arg("solution", `<integer>`, [Which solution should be used if there are more than one.])

A special algorithm is needed in order to compute the tangent for a given shape. Currently it does this by assuming the distance between the center and top anchor (See @anchors) is the radius of a circle. 

#example(
  {
    import "draw.typ": *

    grid((0,0), (3,2), help-lines: true)

    circle((3,2), name: "a", radius: 2pt)
    circle((1,1), name: "c", radius: 0.75)
    content("c", $ c $)

    stroke(red)
    line(
      "a",
      (element: "c", point: "a", solution: 1),
      "c",
      (element: "c", point: "a", solution: 2),
      close: true
    )
  },
  [```typ
  #import "typst-canvas/canvas.typ": canvas

  #canvas({
    import "typst-canvas/draw.typ": *
    grid((0,0), (3,2), help-lines: true)

    circle((3,2), name: "a", radius: 2pt)
    circle((1,1), name: "c", radius: 0.75)
    content("c", $ c $)

    stroke(red)
    line(
      "a",
      (element: "c", point: "a", solution: 1),
      "c",
      (node: "c", point: "a", solution: 2),
      close: true
    )
  })
  ```]
)

== Perpendicular
Can be used to find the intersection of a vertical line going through a point $p$ and a horizontal line going through some other point $q$.

#def-arg("horizontal", `<coordinate>`, [The coordinate through which the horizontal line passes.])
#def-arg("vertical", `<coordinate>`, [The coordinate through which the vertical line passes.])

You can use the implicit syntax of `(horizontal, "-|", vertical)` or `(vertical, "|-", horizontal)`

#example(
  {
    import "draw.typ": *

    content((30deg, 1), $ p_1 $, name: "p1")
    content((75deg, 1), $ p_2 $, name: "p2")

    line((-0.2, 0), (1.2, 0), name: "xline")
    content("xline.end", $ q_1 $, anchor: "left")
    line((2, -0.2), (2, 1.2), name: "yline")
    content("yline.end", $ q_2 $, anchor: "bottom")

    line("p1", (horizontal: (), vertical: "xline"))
    line("p1", (vertical: (), horizontal: "yline"))
    // Implicit form
    line("p2", ((), "|-", "xline"))
    line("p2", ((), "-|", "yline"))
  },
  [```typ
  #import "typst-canvas/canvas.typ": canvas

  #canvas({
    import "typst-canvas/draw.typ": *
    content((30deg, 1), $ p_1 $, name: "p1")
    content((75deg, 1), $ p_2 $, name: "p2")

    line((-0.2, 0), (1.2, 0), name: "xline")
    content("xline.end", $ q_1 $, anchor: "left")
    line((2, -0.2), (2, 1.2), name: "yline")
    content("yline.end", $ q_2 $, anchor: "bottom")

    line("p1", (horizontal: (), vertical: "xline"))
    line("p2", (horizontal: (), vertical: "xline"))
    line("p1", (vertical: (), horizontal: "yline"))
    line("p2", (vertical: (), horizontal: "yline"))
  })
  ```]
)

== Interpolation
Use this to linearly interpolate between two coordinates `a` and `b` with a given factor `number`. If `number` is a `<length>` the position will be at the given distance away from `a` towards `b`. 
An angle can also be given for the general meaning: "First consider the line from `a` to `b`. Then rotate this line by `angle` around point `a`. Then the two endpoints of this line will be `a` and some point `c`. Use this point `c` for the subsequent computation."

#def-arg("a", `<coordinate>`, [The coordinate to interpolate from.])
#def-arg("b", `<coordinate>`, [The coordinate to interpolate to.])
#def-arg("number", [`<number>` or `<length>`], [The factor to interpolate by or the distance away from `a` towards `b`.])
#def-arg("angle", `<angle>`, default: 0deg, "")

Can be used implicitly as an array in the form `(a, number, b)` or `(a, number, angle, b)`.

#example(
  {
    import "draw.typ": *
    grid((0,0), (3,3), help-lines: true)
    line((0,0), (2,2))
    for i in (0, 0.2, 0.5, 0.9, 1, 1.5) {
      content(((0,0), i, (2,2)), [#i])
    }
  },
  [```typ
  #import "typst-canvas/canvas.typ": canvas
  #canvas({
    import "typst-canvas/draw.typ": *
    grid((0,0), (3,3), help-lines: true)
    
    line((0,0), (2,2))
    
    for i in (0, 0.2, 0.5, 0.9, 1, 1.5) {
      content(((0,0), i, (2,2)), [#i])
    }
  })
  ```]
)

#example(
  {
    import "draw.typ": *
    grid((0,0), (3,3), help-lines: true)
    line((1,0), (3,2))
    line((1,0), ((1, 0), 1, 10deg, (3,2)))

    fill(red)
    stroke(none)
    circle(((1, 0), 0.5, 10deg, (3, 2)), radius: 2pt)
  },
  [```typ
  #import "typst-canvas/canvas.typ": canvas
  #canvas({
    import "typst-canvas/draw.typ": *
    grid((0,0), (3,3), help-lines: true)
    line((1,0), (3,2))
    line((1,0), ((1, 0), 1, 10deg, (3,2)))
    fill(red)
    stroke(none)
    circle(((1, 0), 0.5, 10deg, (3, 2)), radius: 2pt)}
  })
  ```]
)

#example(
  {
    import "draw.typ": *
    grid((0,0), (4,4), help-lines: true)

    fill(black)
    stroke(none)
    let n = 16
    for i in range(0, n+1) {
      circle(((2,2), i / 8, i * 22.5deg, (3,2)), radius: 2pt)
    }
  },
  [```typ
  #import "typst-canvas/canvas.typ": canvas
  #canvas({
    import "typst-canvas/draw.typ": *
    grid((0,0), (4,4), help-lines: true)

    fill(black)
    stroke(none)
    let n = 16
    for i in range(0, n+1) {
      circle(((2,2), i / 8, i * 22.5deg, (3,2)), radius: 2pt)
    }
  })
  ```]
)

You can even chain them together!

#example(
  {
    import "draw.typ": *
    grid((0,0), (3, 2), help-lines: true)
    line((0,0), (3,2))
    stroke(red)
    line(((0,0), 0.3, (3,2)), (3,0))
    fill(red)
    stroke(none)
    circle(
      (
        // a
        (((0, 0), 0.3, (3, 2))),
        0.7,
        (3,0)
      ),
      radius: 2pt
    )
 },
  [```typ
  #import "typst-canvas/canvas.typ": canvas
  #canvas({
    import "typst-canvas/draw.typ": *
    grid((0,0), (3, 2), help-lines: true)
    line((0,0), (3,2))
    stroke(red)
    line(((0,0), 0.3, (3,2)), (3,0))
    fill(red)
    stroke(none)
    circle(
      (
        // a
        (((0, 0), 0.3, (3, 2))),
        0.7,
        (3,0)
      ),
      radius: 2pt
    )
  })
  ```]
)

#example(
  {
    import "draw.typ": *
    grid((0,0), (3, 2), help-lines: true)
    line((1,0), (3,2))
    for (l, c) in ((0cm, "0cm"), (1cm, "1cm"), (15mm, "15mm")) {
      content(((1,0), l, (3,2)), $ #c $)
    }
 },
  [```typ
  #import "typst-canvas/canvas.typ": canvas
  #canvas({
    import "typst-canvas/draw.typ": *
    grid((0,0), (3, 2), help-lines: true)
    line((1,0), (3,2))
    for (l, c) in ((0cm, "0cm"), (1cm, "1cm"), (15mm, "15mm")) {
      content(((1,0), l, (3,2)), $ #c $)
    }
  })
  ```]
)

== Function
An array where the first element is a function and the rest are coordinates will cause the function to be called with the resolved coordinates. The resolved coordinates have the same format as the implicit form of the 3-D XYZ coordinate system, @coordinate-xyz.

The example below shows how to use this system to create an offset from an anchor, however this could easily be replaced with a relative coordinate with the `to` argument set, @coordinate-relative.

#example(
  {
    import "draw.typ": *
    circle((0, 0), name: "c")
    fill(red)
    circle((v => vector.add(v, (0, -1)), "c.right"), radius: 0.3)
 },
  [```typ
  #import "typst-canvas/canvas.typ": canvas
  #import "typst-canvas/vector.typ"
  #canvas({
    import "typst-canvas/draw.typ": *
    circle((0, 0), name: "c")
    fill(red)
    circle((v => vector.add(v, (0, -1)), "c.right"), radius: 0.3)
  })
  ```]
)
