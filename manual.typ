#import "lib.typ"
#import "styles.typ"
#import lib: *

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

#let def-arg(term, t, default: none, description) = {
  if type(t) == "string" {
    t = t.replace("?", "|none")
    t = `<` + t.split("|").map(s => {
      if s == "b" {
        `boolean`
      } else if s == "s" {
        `string`
      } else if s == "i" {
        `integer`
      } else if s == "f" {
        `float`
      } else if s == "c" {
        `coordinate`
      } else if s == "d" {
        `dictionary`
      } else if s == "a" {
        `array`
      } else if s == "n" {
        `number`
      } else {
        raw(s)
      }
    }).join(`|`) + `>`
  }

  stack(dir: ltr, [/ #term: #t \ #description], align(right, if default != none {[(default: #default)]}))
}

#set page(
  numbering: "1/1",
  header: align(right)[The `CeTZ` package],
)

#set heading(numbering: "1.")
#set terms(indent: 1em)
#show link: set text(blue)

#let STYLING = heading(level: 4, numbering: none)[Styling]

#align(center, text(16pt)[*The `CeTZ` package*])

#align(center)[
  #link("https://github.com/johannes-wolf")[Johannes Wolf] and #link("https://github.com/fenjalien")[fenjalien] \
  https://github.com/johannes-wolf/typst-canvas
]

#set par(justify: true)

#outline(indent: true, depth: 3)
#pagebreak(weak: true)

= Introduction

This package provides a way to draw stuff using a similar API to #link("https://processing.org/")[Processing] but with relative coordinates and anchors from #link("https://tikz.dev/")[Ti#[_k_]Z]. You also won't have to worry about accidentally drawing over other content as the canvas will automatically resize. And remember: up is positive!

The name CeTZ is a recursive acronym for "CeTZ, ein Typst Zeichenpacket" (german for "CeTZ, a Typst drawing package") and is pronounced like the word "Cats".

= Usage

This is the minimal starting point:
  ```typ
  #import "@local/cetz:0.0.1"
  #cetz.canvas({
    import cetz.draw: *
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
[```typc
// Name the circle
circle((0,0), name: "circle")

// Draw a smaller red circle at "circle"'s left anchor
fill(red)
stroke(none)
circle("circle.left", radius: 0.3)
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
[```typc
// An element does not have to be named 
// in order to use its own anchors.
circle((0,0), anchor: "left")

// Draw a smaller red circle at the origin
fill(red)
stroke(none)
circle((0,0), radius: 0.3)
```]
)

= Draw Function Reference

== Canvas
```typc
canvas(background: none, length: 1cm, debug: false, body)
```
#def-arg("background", `<color>`, default: "none", "A color to be used for the background of the canvas.")
#def-arg("length", `<length>`, default: "1cm", "Used to specify what 1 coordinate unit is.")
#def-arg("debug", `<bool>`, default: "false", "Shows the bounding boxes of each element when `true`.")
#def-arg("body", none, [A code block in which functions from `draw.typ` have been called.])

== Styling <styling>
You can style draw elements by passing the relevant named arguments to their draw functions. All elements have stroke and fill styling unless said otherwise.

#def-arg("fill", [`<color>` or `<none>`], default: "none", [How to fill the draw element.])
#def-arg("stroke", [`<none>` or `<auto>` or `<length>` \ or `<color>` or `<dicitionary>` or `<stroke>`], default: "black + 1pt", [How to stroke the border or the path of the draw element. See Typst's line documentation for more details: https://typst.app/docs/reference/visualize/line/#parameters-stroke])

#example({
    import "draw.typ": *
    // Draws a red circle with a blue border
    circle((), fill: red, stroke: blue)
    // Draws a green line
    line((), (1,1), stroke: green)
  },
  [```typc
  cetz.canvas({
    import cetz.draw: *
    // Draws a red circle with a blue border
    circle((0, 0), fill: red, stroke: blue)
    // Draws a green line
    line((0, 0), (1, 1), stroke: green)
  })
  ```]
)

Instead of having to specify the same styling for each time you want to draw an element, you can use the `set-style` function to change the style for all elements after it. You can still pass styling to a draw function to override what has been set with `set-style`. You can also use the `fill()` and `stroke()` functions as a shorthand to set the fill and stroke respectively.

#example({
    import "draw.typ": *
    // Shows styling is applied after
    rect((-1, -1), (1, 1))
    // Shows how `set-style` works
    set-style(stroke: blue, fill: red)
    circle((0,0))

    // Shows that styling can be overridden
    line((), (1,1), stroke: green)
  },
  [```typc
  cetz.canvas({
    import cetz.draw: *
    // Draws an empty square with a black border
    rect((-1, -1), (1, 1))

    // Sets the global style to have a fill of red and a stroke of blue
    set-style(stroke: blue, fill: red)
    circle((0,0))

    // Draws a green line despite the global stroke is blue
    line((), (1,1), stroke: green)
  })
  ```]
)

When using a dictionary for a style, it is important to note that they update each other instead of overriding the entire option like a non-dictionary value would do. For example, if the stroke is set to `(paint: red, thickness: 5pt)` and you pass `(paint: blue)`, the stroke would become `(paint: blue, thickness: 5pt)`.

#example({
    import "draw.typ": *
    set-style(stroke: (paint: red, thickness: 5pt))
    line((0,0), (1,0))
    line((0,0), (1,1), stroke: (paint: blue))
    line((0,0), (0,1), stroke: yellow)
  },
  [```typc
  canvas({
    import cetz.draw: *
    // Sets the stroke to red with a thickness of 5pt
    set-style(stroke: (paint: red, thickness: 5pt))
    // Draws a line with the global stroke
    line((0,0), (1,0))
    // Draws a blue line with a thickness of 5pt because dictionaries update the style
    line((0,0), (1,1), stroke: (paint: blue))
    // Draws a yellow line with a thickness of 1pt because other values override the style
    line((0,0), (0,1), stroke: yellow)
  })
  ```]
)

You can also specify styling for each type of element. Note that dictionary values will still update with its global value, the full hierarchy is `function > element type > global`. When the value of a style is `auto`, it will become exactly its parent style.

#example({
    import "draw.typ": *
    set-style(
      fill: green,
      stroke: (thickness: 5pt),
      rect: (stroke: (dash: "dashed"), fill: blue), 
    )
    rect((0,0), (1,1))
    circle((0.5, -1.5))
    rect((0,-3), (1, -4), stroke: (thickness: 1pt))
  },
  [
  ```typc
  canvas({
    import cetz.draw: *
    set-style(
      // Global fill and stroke
      fill: green,
      stroke: (thickness: 5pt),
      // Stroke and fill for only rectangles
      rect: (stroke: (dash: "dashed"), fill: blue), 
    )
    rect((0,0), (1,1))
    circle((0.5, -1.5))
    rect((0,-3), (1, -4), stroke: (thickness: 1pt))
  })
  ```])

#example({
    import "draw.typ": *
    set-style(
      rect: (
        fill: red,
        stroke: none
      ),
      line: (
        fill: blue,
        stroke: (dash: "dashed")
      ),
    )
    rect((0,0), (1,1))

    line((0, -1.5), (0.5, -0.5), (1, -1.5), close: true)

    circle((0.5, -2.5), radius: 0.5, fill: green)
  },
  [
  ```typc
  // Its a nice drawing okay
  cetz.canvas({
    import cetz.draw: *
    set-style(
      rect: (
        fill: red,
        stroke: none
      ),
      line: (
        fill: blue,
        stroke: (dash: "dashed")
      ),
    )
    rect((0,0), (1,1))

    line((0, -1.5), (0.5, -0.5), (1, -1.5), close: true)

    circle((0.5, -2.5), radius: 0.5, fill: green)
  })
  ```])

== Elements

=== Line
Draws a line (a direct path between two points) to the canvas. If multiplie coordinates are given, a line is drawn between each consecutive one.

```typc
line(..pts, name: none, close: false, ..styling)
```
#def-arg("..pts", `<arguments of coordinates>`, [Coordinates to draw the lines between. A minimum of two must be given.])
#def-arg("name", `<string>`, [Sets the name of element for use with anchors.])
#def-arg("close", `<bool>`, default: false, [When `true` a straight line is drawn from the last coordinate to the first coordinate, essentially "closing" the shape.])

#example({
    import "draw.typ": *
    line((-1.5, 0), (1.5, 0))
    line((0, -1.5), (0, 1.5))
  },
  [
  ```typc
  canvas({
    import cetz.draw: *
    line((-1.5, 0), (1.5, 0))
    line((0, -1.5), (0, 1.5))
  })
  ```])

#STYLING

#def-arg("mark", `<dictionary> or <auto>`, default: auto, [The styling to apply to marks on the line, see @marks.])

=== Rectangle
Draws a rectangle to the canvas.

```typc
rect(a, b, name: none, anchor: none, ..styling)
```
#def-arg("a", `<coordinate>`, [The top left coordinate of the rectangle.])
#def-arg("b", `<coordinate>`, [The bottom right coordinate of the rectangle.])

#example({
    import "draw.typ": *
    rect((-1.5, 1.5), (1.5, -1.5))
  },
  [```typc
  canvas({
    import cetz.draw: *
    rect((-1.5, 1.5), (1.5, -1.5))
  })
  ```])

=== Arc
Draws an arc to the canvas. Exactly two of the three values `start`, `stop`, and `delta` should be defined. You can set the radius of the arc by setting the `radius` style option. You can also draw an elliptical arc by passing an array where the first number is the radius in the x direction and the second number is the radius in the y direction.

```typc
arc(position, start: auto, stop: auto, delta: auto, name: none, anchor: none,)
```
#def-arg("position", `<coordinate>`, [The coordinate to start drawing the arc from.])
#def-arg("start", `<angle>`, [The angle to start the arc.])
#def-arg("stop", `<angle>`, [The angle to stop the arc.])
#def-arg("delta", `<angle>`, [The angle that is added to start or removed from stop.])

#example({
    import "draw.typ": *
    arc((0,0), start: 45deg, stop: 135deg)
    arc((0,-0.5), start: 45deg, delta: 90deg, mode: "CLOSE")
    arc((0,-1), stop: 135deg, delta: 90deg, mode: "PIE")
  },
  [```typc
  cetz.canvas({
    import cetz.draw: *
    arc((0,0), start: 45deg, stop: 135deg)
    arc((0,-0.5), start: 45deg, delta: 90deg, mode: "CLOSE")
    arc((0,-1), stop: 135deg, delta: 90deg, mode: "PIE")
  })
  ```]
)

#STYLING

#def-arg("radius", `<number> or <array>`, default: 1, [The radius of the arc. This is also a global style shared with circle!])
#def-arg("mode", `<string>`, default: `"OPEN"`, [The options are "OPEN" (the default, just the arc), "CLOSE" (a circular segment) and "PIE" (a circular sector).])


=== Circle
Draws a circle to the canvas. An ellipse can be drawn by passing an array of length two to the `radius` argument to specify its `x` and `y` radii.

```typc
circle(center, name: none, anchor: none)
```
#def-arg("center", `<coordinate>`, [The coordinate of the circle's origin.])

#example({
    import "draw.typ": *
    circle((0,0))
    circle((0,-2), radius: (0.75, 0.5))
  },
  [```typc
  cetz.canvas({
    import cetz.draw: *
    circle((0,0))
    // Draws an ellipse
    circle((0,-2), radius: (0.75, 0.5))
  })
  ```]
)

#STYLING

#def-arg("radius", `<number> or <length> or <array of <number> or <length>>`, default: "1", [The circle's radius. If an array is given an ellipse will be drawn where the first item is the `x` radius and the second item is the `y` radius. This is also a global style shared with arc!])

=== Bezier
Draws a bezier curve with 1 or 2 control points to the canvas.

```typc
bezier(start, end, ..ctrl-style)
```
#def-arg("start", `<coordinate>`, "The coordinate to start drawing the bezier curve from.")
#def-arg("end", `<coordinate>`, "The coordinate to draw the bezier curve to.")
#def-arg("..ctrl-style", `<coordinates>`, "An argument sink for the control points and styles. Its positional part should be of one or two coordinates to specify the control points of the bezier curve.")

#example({
    import "draw.typ": *
    bezier((0, 0), (2, 0), (1, 1))
    bezier((0, -1), (2, -1), (.5, -2), (1.5, 0))
  },
  [```typc
  cetz.canvas({
    import cetz.draw: *
    bezier((0, 0), (2, 0), (1, 1))
    bezier((0, -1), (2, -1), (.5, -2), (1.5, 0))
  })
  ```]
)

=== Content
Draws a content block to the canvas.

```typc
content(pt, ct, angle: 0deg, name: none, anchor: none)
```
#def-arg("pt", `<coordinate>`, "The coordinate of the center of the content block.")
#def-arg("ct", `<content>`, "The content block.")
#def-arg("angle", `<angle|coordinate>`, [The angle to rotate the content block by. Uses Typst's `rotate` function. If passed a coordinate, the angle between `pt` and `angle` is used.])

#example({
    import "draw.typ": *
    content((0,0), [Hello World!])
  },
  [```typc
  cetz.canvas({
    import cetz.draw: *
    content((0,0), [Hello World!])
  })
  ```]
)

#example({
    import "draw.typ": *
    let (a, b) = ((1,0), (3,1))

    line(a, b)
    content((a, .5, b), angle: b, [Text on a line], anchor: "bottom")
  },
  [```typc
  cetz.canvas({
    import cetz.draw: *
    let (a, b) = ((1,0), (3,1))

    line(a, b)
    content((a, .5, b), angle: b, [Text on a line], anchor: "bottom")
  })
  ```]
)

#STYLING
This draw element is not affected by fill or stroke styling.

#def-arg("padding", `<length>`, default: 0em, "")

=== Grid
Draws a grid to the canavas.

```typc
grid(from, to, step: 1, help-lines: false, name: none)
```
#def-arg("from", `<coordinate>`, "Specifies the bottom left position of the grid.")
#def-arg("to", `<coordinate>`, "Specifies the top right position of the grid.")
#def-arg("step", `<number> or <length> or <array of <number> or <length>>`, [The stepping in both $x$ and $y$ directions. An array can be given to specify the stepping for each direction.])
#def-arg("help-lines", `<bool>`, default: "false", [Styles the grid to look "subdued" by using thin gray lines (`0.2pt + gray`)])

#example({
    import "draw.typ": *
    grid((0,0), (3,3), help-lines: true)
  },
  [```typc
  cetz.canvas({
    import cetz.draw: *
    grid((0,0), (3,2), help-lines: true)
  })
  ```]
)

=== Mark <marks>
Draws a mark or "arrow head", its styling influences marks being drawn on paths (e.g. lines).

```
#mark(from, to, ..style)
```

#example({
  import "draw.typ": *
  line((1, 0), (1, 6), stroke: (paint: gray, dash: "dotted"))
  set-style(mark: (fill: none))
  line((0, 6), (1, 6), mark: (end: "<"))
  line((0, 5), (1, 5), mark: (end: ">"))
  set-style(mark: (fill: black))
  line((0, 4), (1, 4), mark: (end: "<>"))
  line((0, 3), (1, 3), mark: (end: "o"))
  line((0, 2), (1, 2), mark: (end: "|"))
  line((0, 1), (1, 1), mark: (end: "<"))
  line((0, 0), (1, 0), mark: (end: ">"))
},
[```typc
  cetz.canvas({
    import cetz.draw: *
    line((1, 0), (1, 6), stroke: (paint: gray, dash: "dotted"))
    set-style(mark: (fill: none))
    line((0, 6), (1, 6), mark: (end: "<"))
    line((0, 5), (1, 5), mark: (end: ">"))
    set-style(mark: (fill: black))
    line((0, 4), (1, 4), mark: (end: "<>"))
    line((0, 3), (1, 3), mark: (end: "o"))
    line((0, 2), (1, 2), mark: (end: "|"))
    line((0, 1), (1, 1), mark: (end: "<"))
    line((0, 0), (1, 0), mark: (end: ">"))
  })
  ```]
)

#STYLING

#def-arg("symbol", `<string>`, default: ">", [The type of mark to draw when using the `mark` function.])
#def-arg("start", `<string>`, [The type of mark to draw at the start of a path.])
#def-arg("end", `<string>`, [The type of mark to draw at the end of a path.])
#def-arg("size", `<number>`, default: "0.15", [The size of the marks.])

== Path Transformations <path-transform>

=== Merge-Path

```typc
merge-path(body, ..style, close: false, name: none)
```
#def-arg("body", `<objects>`, [
  Elements to merge as one path
])
#def-arg("close", `<bool>`, [
  Auto close the path using a straight line
])
#def-arg("name", `<string>`, [
  Element name
])

#example({
import "draw.typ": *
merge-path({
  line((0, 0), (1, 0))
  bezier((), (0, 0), (1,1), (0,1))
}, fill: white)
}, ```typc
// Merge two different paths into one
merge-path({
  line((0, 0), (1, 0))
  bezier((), (0, 0), (1,1), (0,1))
}, fill: white)
```)

== Groups <groups>
Groups allow scoping context changes such as setting stroke-style, fill and transformations.
```typc
group(content, name: none, anchor: none)
```

#example({
import "draw.typ": *
group({
  stroke(5pt)
  scale(.5); rotate(45deg)
  rect((-1,-1),(1,1))
})
rect((-1,-1),(1,1))
}, ```typc
// Create group
group({
  stroke(5pt)
  scale(.5); rotate(45deg)
  rect((-1,-1),(1,1))
})
rect((-1,-1),(1,1))
```)

=== Anchor

Defines a new anchor inside a group.

```typc
anchor(name, coordinate)
```

#def-arg("name", "s", [Name of the anchor])
#def-arg("coordinate", `<coordinate>`, [Position])

#example({
import "draw.typ": *
group(name: "g", {
  circle((0,0))
  anchor("x", (.4,.1))
})
circle("g.x", radius: .1)
}, ```typc
group(name: "g", {
  circle((0,0))
  anchor("x", (.4,.1))
})
circle("g.x", radius: .1)
```)

=== Copy-Anchors

Copy all anchors of element into current group.

```typc
copy-anchors(element, filter: none)
```

#def-arg("element", "s", [Target element name])
#def-arg("filter", "a?", [List of anchor names to copy, all if empty])

#example({
import "draw.typ": *
group(name: "g", {
  rotate(45deg)
  rect((0,0), (1,1), name: "r")
  copy-anchors("r")
})
circle("g.top", radius: .1)
}, ```typc
group(name: "g", {
  rotate(45deg)
  rect((0,0), (1,1), name: "r")
  copy-anchors("r")
})
circle("g.top", radius: .1)
```)

== Transformations
All transformation functions push a transformation matrix onto the current transform stack.
To apply transformations scoped use a `group(...)` object.

Transformation martices get multiplied in the following order:
$ M_"world" = M_"world" dot M_"local" $

=== Translate <translate>
```typc
translate(coordinate, pre: true)
```

#def-arg("coordinate", `<vector>`,
  [Coordinates to translate for])
#def-arg("pre", `<bool>`,
  [Specify multiplication order. If `true`, translation is multiplied
   in the order $M_"local" dot M_"world"$, otherwise the order
   $M_"world" dot M_"local"$ is used.])

#example({
import "draw.typ": *
rect((0,0), (2,2))
translate((.5,.5,0))
rect((0,0), (1,1))
}, ```typc
// Outer rect
rect((0,0), (2,2))
// Inner rect
translate((.5,.5,0))
rect((0,0), (1,1))
```)

=== Set Origin
```typc
set-origin(position)
```

#example({
import "draw.typ": *
rect((0,0), (2,2), name: "r")
set-origin("r.above")
circle((0, 0), radius: .1)
}, ```typc
// Outer rect
rect((0,0), (2,2), name: "r")
// Move origin to top edge
set-origin("r.above")
circle((0, 0), radius: .1)
```)

=== Set Viewport
```typc
set-viewport(from, to, bounds: (1, 1, 1))
```

#def-arg("from", `<coordinate>`,
  [First (bottom-right) coordinate of the viewport rect.])
#def-arg("to", `<coordinate>`,
  [Second (top-left) coordinate of the viewport rect.])
#def-arg("bounds", `<vector>`,
  [Viewport inner bounds. Negative bounds flip sides.])

#example({
  import "draw.typ": *
  rect((0,0), (2,2))
  set-viewport((0,0), (2,2), bounds: (10, 10))
  circle((5,5))
}, ```typc
rect((0,0), (2,2))
set-viewport((0,0), (2,2), bounds: (10, 10))
circle((5,5))
```)

=== Rotate
```typc
rotate(axis-dictionary)
rotate(z-angle)
```

#example({
  import "draw.typ": *
  rotate((z: 45deg))
  rect((-1,-1), (1,1))
  rotate((y: 80deg))
  circle((0,0))
}, ```typc
// Rotate on z-axis
rotate((z: 45deg))
rect((-1,-1), (1,1))
// Rotate on y-axis
rotate((y: 80deg))
circle((0,0))
```)

=== Scale
```typc
#scale(axis-dictionary)
#scale(factor)
```

#example({
  import "draw.typ": *
  scale((x: 1.8))
  circle((0,0))
}, ```typc
// Scale x-axis
scale((x: 1.8))
circle((0,0))
```)



= Coordinate Systems <coordinate-systems>
A _coordinate_ is a position on the canvas on which the picture is drawn. They take the form of dictionaries and the following sub-sections define the key value pairs for each system. Some systems have a more implicit form as an array of values and `CeTZ` attempts to infer the system based on the element types.


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
  [```typc
  #import "@local/cetz:0.0.1"
  #cetz.canvas({
    import cetz.draw: *

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
  [```typc
  #import "@local/cetz:0.0.1"
  #cetz.canvas({
    import cetz.draw: *
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
  circle((0, 0), stroke: blue)
  circle((rel: (0, -1)), stroke: red)
  },
  [```typc
  #import "@local/cetz:0.0.1"
  #cetz.canvas({
    import cetz.draw: *
    circle((0, 0), stroke: blue)
    circle((rel: (0, -1)), stroke: red)
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
  [```typc
  #import "@local/cetz:0.0.1"
  #cetz.canvas({
    import cetz.draw: *
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
  [```typc
  #import "@local/cetz:0.0.1"
  #cetz.canvas({
    import cetz.draw: *
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
      (1, 0.05, 0.05, "ASCII")
    ) {
      content((bary: (content: c, structure: s, form: f)), cont)
    }
  },
  [```typc
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
  (1, 0.05, 0.05, "ASCII")
) {
  content((bary: (content: c, structure: s, form: f)), cont)
}
  ```]
)

== Anchor
Defines a point relative to a named element using anchors, see @anchors.

#def-arg("name", `<string>`, [The name of the element that you wish to use to specify a coordinate.])
#def-arg("anchor", `<string>`, [An anchor of the element. If one is not given a default anchor will be used. On most elements this is `center` but it can be different.])

You can also use implicit syntax of a dot separated string in the form `"name.anchor"`.

#example(
  {
    import "draw.typ": *

    line((0,0), (3,2), name: "line")
    circle("line.end", name: "circle")
    rect("line.start", "circle.left")
  },
[```typc
import cetz.draw: *
line((0,0), (3,2), name: "line")
circle("line.end", name: "circle")
rect("line.start", "circle.left")
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
[```typc
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
```]
)

== Interpolation
Use this to linearly interpolate between two coordinates `a` and `b` with a given factor `number`. If `number` is a `<length>` the position will be at the given distance away from `a` towards `b`. 
An angle can also be given for the general meaning: "First consider the line from `a` to `b`. Then rotate this line by `angle` around point `a`. Then the two endpoints of this line will be `a` and some point `c`. Use this point `c` for the subsequent computation."

#def-arg("a", `<coordinate>`, [The coordinate to interpolate from.])
#def-arg("b", `<coordinate>`, [The coordinate to interpolate to.])
#def-arg("number", [`<number>` or `<length>`], [
  The factor to interpolate by or the distance away from `a` towards `b`.
])
#def-arg("angle", `<angle>`, default: 0deg, "")
#def-arg("abs", `<bool>`, default: false, [
  Interpret `number` as absolute distance, instead of a factor.
])

Can be used implicitly as an array in the form `(a, number, b)` or `(a, number, angle, b)`.

#example(
  {
    import "draw.typ": *
    grid((0,0), (3,3), help-lines: true)
    line((0,0), (2,2))
    for i in (0, 0.2, 0.5, 0.8, 1, 1.5) {
      content(((0,0), i, (2,2)),
              box(fill: white, inset: 1pt, [#i]))
    }
    line((1,0), (3,2))
    for i in (0, 0.5, 1, 2) {
      content((a: (1,0), number: i, abs: true, b: (3,2)),
              box(fill: white, inset: 1pt, text(red, [#i])))
    }
  },
[```typc
grid((0,0), (3,3), help-lines: true)

line((0,0), (2,2))
for i in (0, 0.2, 0.5, 0.8, 1, 1.5) { /* Relative distance */
  content(((0,0), i, (2,2)),
          box(fill: white, inset: 1pt, [#i]))
}

line((1,0), (3,2))
for i in (0, 0.5, 1, 2) { /* Absolute distance */
  content((a: (1,0), number: i, abs: true, b: (3,2)),
          box(fill: white, inset: 1pt, text(red, [#i])))
}
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
[```typc
grid((0,0), (3,3), help-lines: true)
line((1,0), (3,2))
line((1,0), ((1, 0), 1, 10deg, (3,2)))
fill(red)
stroke(none)
circle(((1, 0), 0.5, 10deg, (3, 2)), radius: 2pt)}
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
[```typc
grid((0,0), (4,4), help-lines: true)

fill(black)
stroke(none)
let n = 16
for i in range(0, n+1) {
  circle(((2,2), i / 8, i * 22.5deg, (3,2)), radius: 2pt)
}
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
[```typc
grid((0,0), (3, 2), help-lines: true)
line((1,0), (3,2))
for (l, c) in ((0cm, "0cm"), (1cm, "1cm"), (15mm, "15mm")) {
  content(((1,0), l, (3,2)), $ #c $)
}
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
[```typc
circle((0, 0), name: "c")
fill(red)
circle((v => cetz.vector.add(v, (0, -1)), "c.right"), radius: 0.3)
```]
)

= Utility

== For-Each-Anchor

```typc
for-each-anchor(node-name, callback)
```
#def-arg("node-name", `<string>`, [
  Target node name
])
#def-arg("callback", `<function>`, [
  Callback function acception the anchor name
])

#example({
  import "draw.typ": *
  rect((0, 0), (2,2), name: "my-rect")
  for-each-anchor("my-rect", (name) => {
    if not name in ("above", "below", "default") {

    content((), box(inset: 1pt, fill: white, text(8pt, [#name])),
            angle: -45deg)
    }
  })
}, ```typc
// Label nodes anchors
rect((0, 0), (2,2), name: "my-rect")
for-each-anchor("my-rect", (name) => {
  if not name in ("above", "below", "default") {

  content((), box(inset: 1pt, fill: white, text(8pt, [#name])),
          angle: -45deg)
  }
})
```)

= Libraries

== Tree

With the tree library, CeTZ provides a simple tree layout algorithm.

```typc
tree(root-node, draw-node: auto, draw-edge: auto,
  direction: "down", parent-position: "center", grow: 1,
  spread: 1, name: none, ..style)
```

#def-arg("root-node", "node",
  [Tree root node, see @tree-node])
#def-arg("draw-node", "function?",
  [Node render callback `(node, parent-name) => (draw, ..)`])
#def-arg("draw-edge", "function?",
  [Edge render callback `(source-name, target-name, target-node) => (draw, ..)`])
#def-arg("direction", "s",
  [Tree grow direction: "top", "bottom", "left" or "right"])
#def-arg("parent-position", "s",
  [Positioning of parent nodes: "begin", "center" or "end"])
#def-arg("grow", "f",
  [Direction grow factor])
#def-arg("spread", "f",
  [Sibling spread factor])
#def-arg("name", "s?",
  [Object name])
#def-arg("..style", "style",
  [Draw style])

#example({
  import "draw.typ": *
  import "tree.typ"
  let data = ([Root], ([A], [AA], [AB]), ([B], [BA]))
  tree.tree(data, content: (padding: .1), line: (stroke: blue))
}, ```typc
import "tree.typ"

let data = ([Root], ([A], [AA], [AB]), ([B], [BA]))
tree.tree(data, content: (padding: .1), line: (stroke: blue))
```)

#example({
  import "draw.typ": *
  import "tree.typ"
  let data = ([\*], ([A], [AA], [AB]), ([B], [BA]))
  tree.tree(data, content: (padding: .1), direction: "right",
          mark: (end: ">", fill: none),
          draw-node: (node, ..) => {
            circle((), radius: .35, fill: blue, stroke: none)
            content((), text(white, [#node.content]))
          },
          draw-edge: (from, to, ..) => {
            let (a, b) = (from + ".center",
                          to + ".center")

             line((a: a, b: b, abs: true, number: .35),
                  (a: b, b: a, abs: true, number: .35))
 })
}, ```typc
import "tree.typ"

let data = ([Root], ([\*], [AA], [AB]), ([B], [BA]))
tree.tree(data, content: (padding: .1), direction: "right",
          mark: (end: ">", fill: none),
          draw-node: (node, ..) => {
            circle((), radius: .35, fill: blue, stroke: none)
            content((), text(white, [#node.content]))
          },
          draw-edge: (from, to, ..) => {
            let (a, b) = (from + ".center",
                          to + ".center")

             draw.line((a: a, b: b, abs: true, number: .35),
                       (a: b, b: a, abs: true, number: .35))
          })
```)

=== Node <tree-node>

A tree node is an array of nodes. The first array item represents the
current node, all following items are direct children of that node.
The node itselfes can be ot type `content` or `dictionary` with a key `content`.

== Plot

The library `plot` of CeTZ allows plotting 2D data as linechart.

=== Plot <plot-function>

The `plot` function is an environment for plotting data.

```typc
plot(size: (width, height),
     axis-style: "scientific"
     ..options,
     body)
```

The ticks option dictionary supports the following keys:
#def-arg("size", "a",
  [Size of the plot])
#def-arg("axis-style", "s?",
  [Axis style, either "scientific" or "school-book"])
#def-arg("..options", "any",
  [Axis options in the form `<axis-name>-<option>`. The possible options are:
  #box[
  / label : The axis label
  / min: Axis min. value
  / max: Axis max. value
  / ticks: List of tick values or value/label tuples
  / tick-step: Tick step or `none`
  / minor-tick-step: Minor tick step or `none`
  / decimals: Number of tick label decimal digits
  / unit: Tick label suffix
  ]
])
#def-arg("body", "..",
  [Calls of `plot.add(..)`, see <plot-add>])

=== Plot-Add

The `plot.add` function adds plotting data into a plot environment.
It must be called from insides `plot({..})`.

If used with a callback, the `domain` must be specified!

```typc
add(domain: auto, hypograph: false, epigraph: false, fill: false,
    mark: none, mark-size: .2, mark-style: (:), samples: 100,
    style: (:), axes: ("x", "y"),
    data)
```

#def-arg("domain", "a|auto",
  [Range of x for sampled data])
#def-arg("hypograph", "b",
  [Fill graph below function])
#def-arg("epigraph", "b",
  [Fill graph above function])
#def-arg("fill", "b",
  [Fill graph to zero])
#def-arg("mark", "s?",
  [Mark symbol. Any of `("x", "o", "square", "triangle", "|", "-")`])
#def-arg("mark-size", "f?",
  [Size of mark symbol])
#def-arg("mark-style", "style?",
  [Style used for drawing marks. Note that this inherits the plots style])
#def-arg("style", "style",
  [Style used for drawing the graph])
#def-arg("samples", "i",
  [Number of samples to use (only if `data` is of type function)])
#def-arg("axes", "a",
  [Array of axis names to use])
#def-arg("data", "function|a",
  [Array of data points or function in the form `x => y`])

#example({
  import "draw.typ": *
  plot.plot(size: (2,2), x-tick-step: 180, y-tick-step: 1,
                         x-unit: $degree$, {
    plot.add(domain: (0, 360), x => calc.sin(x * 1deg))
  })
}, ```typc
plot.plot(size: (2,2), x-tick-step: 180, y-tick-step: 1,
          x-unit: $degree$, {
  plot.add(domain: (0, 360), x => calc.sin(x * 1deg))
})
```)

#example({
  import "draw.typ": *
  plot.plot(size: (2,2), x-tick-step: 180, y-tick-step: 1,
                         x-unit: $degree$, y-max: .5, {
    plot.add(domain: (0, 360), x => calc.sin(x * 1deg))
    plot.add(domain: (0, 360), x => calc.cos(x * 1deg),
             samples: 10, mark: "x", mark-style: (stroke: blue))
  })
}, ```typc
plot.plot(size: (2,2), x-tick-step: 180, y-tick-step: 1,
          x-unit: $degree$, y-max: .5, {
  plot.add(domain: (0, 360), x => calc.sin(x * 1deg))
  plot.add(domain: (0, 360), x => calc.cos(x * 1deg),
           samples: 10, mark: "x", mark-style: (stroke: blue))
})
```)

== Chart

With the `chart` library it is easy to draw charts.

=== Barchart

```typc
barchart(size: (width, height))
```

#def-arg("data", "a",
  [Data array of arrays or dictionaries])
#def-arg("label-key", "s|i",
  [Data item key to access an items label])
#def-arg("value-key", "s|i|a",
  [Data item key(s) to access an items value(s). For multi-value charts
   this must be an array of all keys, e.G. `(..range(1, 5))`])
#def-arg("mode", "s",
  [Barchart mode, one of "basic", "clustered" (bars next to each other), "stacked" (bar stacked) or "stacked100" (bars stacked but as percentage of their sum)])
#def-arg("size", "a",
  [The chart's size. Height can be set to `auto`.])
#def-arg("bar-width", "f",
  [Width of a bar or cluster of bars, with $1$ being leving no gap between
   values.])
#def-arg("bar-style", "function|style",
  [Style of bars, accepts a function of the form `index => style`. You canvas    use palettes from the `palette` library, see @palette.])
#def-arg("x-tick-step", "f",
  [X axis tick step])
#def-arg("x-ticks", "a",
  [X axis ticks list, a list of tick values or value/label tuples])
#def-arg("x-unit", "content",
  [X axis tick label suffix])
#def-arg("x-label", "content?",
  [X axis label])
#def-arg("y-label", "content?",
  [Y axis label])

=== Examples
==== Basic
#example({
  let data = (("A", 10), ("B", 20), ("C", 13))
  chart.barchart(size: (3, auto), x-tick-step: 10, data)
}, ```typc
let data = (("A", 10), ("B", 20), ("C", 13))
chart.barchart(size: (3, auto), x-tick-step: 10, data)
```)

==== Clustered
#example({
  let data = (("A", 10, 12, 22), ("B", 20, 1, 7), ("C", 13, 8, 9))
  chart.barchart(size: (3, auto), mode: "clustered",
                 x-tick-step: 10, value-key: (..range(1, 4)), data)
}, ```typc
let data = (("A", 10, 12, 22), ("B", 20, 1, 7), ("C", 13, 8, 9))
chart.barchart(size: (3, auto), mode: "clustered",
               x-tick-step: 10, value-key: (..range(1, 4)), data)
```)

==== Stacked
#example({
  let data = (("A", 10, 12, 22), ("B", 20, 1, 7), ("C", 13, 8, 9))
  chart.barchart(size: (3, auto), mode: "stacked",
                 x-tick-step: 10, value-key: (..range(1, 4)), data)
}, ```typc
let data = (("A", 10, 12, 22), ("B", 20, 1, 7), ("C", 13, 8, 9))
chart.barchart(size: (3, auto), mode: "clustered",
               x-tick-step: 10, value-key: (..range(1, 4)), data)
```)

== Palette <palette>

A palette is a function that returns a style for an index.
The palette library provides some predefined palettes.

The list of palettes:
- red
- blue
- rainbow
