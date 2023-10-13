#import "src/lib.typ"
#import "src/styles.typ"
#import "@preview/tidy:0.1.0"
#import lib: *

// This is a wrapper around typs-doc show-module that
// strips all but one function from the module first.
// As soon as typst-doc supports examples, this is no longer
// needed.
#let show-module-fn(module, fn, ..args) = {
  module.functions = module.functions.filter(f => f.name == fn)
  tidy.show-module(module, ..args.pos(), ..args.named(),
                   show-module-name: false,
                   show-outline: false)
}

#let canvas-background = gray.lighten(75%)

// String that gets prefixed to every example code
// for compilation only!
#let example-preamble = "import lib.draw: *;"
#let example-scope = (cetz: lib, lib: lib)

#let example(source, ..args, vertical: false) = {
  let picture = canvas(eval(example-preamble + source.text,
                            scope: example-scope), ..args)
  block(if vertical {
    align(
      center, 
      stack(
        dir: ttb,
        spacing: 1em,
        block(width: 100%,
          picture,
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
      picture,
      source
    )
  }, breakable: false)
}

// Usage:
//   ```example
//   /* canvas drawing code */
//   ```
#show raw.where(lang: "example"): text => {
  example(raw(text.text, lang: "typc"))
}

#let def-arg(term, t, default: none, description) = {
  if type(t) == str {
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

#set heading(numbering: (..num) => if num.pos().len() < 4 { numbering("1.1", ..num) })
#set terms(indent: 1em)
#show link: set text(blue)

#align(center, text(16pt)[*The `CeTZ` package*])

#align(center)[
  #link("https://github.com/johannes-wolf")[Johannes Wolf] and #link("https://github.com/fenjalien")[fenjalien] \
  https://github.com/johannes-wolf/cetz \
  Version #lib.version.map(v => str(v)).join(".")
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
  #import "@local/cetz:0.1.2"
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
```example
// Name the circle
circle((0,0), name: "circle")

// Draw a smaller red circle at "circle"'s left anchor
fill(red)
stroke(none)
circle("circle.left", radius: 0.3)
```

All elements will have default anchors based on their bounding box, they are: `center`, `left`, `right`, `above`/`top` and `below`/`bottom`, `top-left`, `top-right`, `bottom-left`, `bottom-right`. Some elements will have their own anchors.

Elements can be placed relative to their own anchors.
```example
// An element does not have to be named 
// in order to use its own anchors.
circle((0,0), anchor: "left")

// Draw a smaller red circle at the origin
fill(red)
stroke(none)
circle((0,0), radius: 0.3)
```

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
#def-arg("stroke", [`<none>` or `<auto>` or `<length>` \ or `<color>` or `<dictionary>` or `<stroke>`], default: "black + 1pt", [How to stroke the border or the path of the draw element. See Typst's line documentation for more details: https://typst.app/docs/reference/visualize/line/#parameters-stroke])

```example
// Draws a red circle with a blue border
circle((0, 0), fill: red, stroke: blue)
// Draws a green line
line((0, 0), (1, 1), stroke: green)
```

Instead of having to specify the same styling for each time you want to draw an element, you can use the `set-style` function to change the style for all elements after it. You can still pass styling to a draw function to override what has been set with `set-style`. You can also use the `fill()` and `stroke()` functions as a shorthand to set the fill and stroke respectively.

```example
// Draws an empty square with a black border
rect((-1, -1), (1, 1))

// Sets the global style to have a fill of red and a stroke of blue
set-style(stroke: blue, fill: red)
circle((0,0))

// Draws a green line despite the global stroke is blue
line((), (1,1), stroke: green)
```

When using a dictionary for a style, it is important to note that they update each other instead of overriding the entire option like a non-dictionary value would do. For example, if the stroke is set to `(paint: red, thickness: 5pt)` and you pass `(paint: blue)`, the stroke would become `(paint: blue, thickness: 5pt)`.

```example
// Sets the stroke to red with a thickness of 5pt
set-style(stroke: (paint: red, thickness: 5pt))
// Draws a line with the global stroke
line((0,0), (1,0))
// Draws a blue line with a thickness of 5pt because dictionaries update the style
line((0,0), (1,1), stroke: (paint: blue))
// Draws a yellow line with a thickness of 1pt because other values override the style
line((0,0), (0,1), stroke: yellow)
```

You can also specify styling for each type of element. Note that dictionary values will still update with its global value, the full hierarchy is `function > element type > global`. When the value of a style is `auto`, it will become exactly its parent style.

```example
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
```

```example
// Its a nice drawing okay
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
```

== Elements
#let draw-module = tidy.parse-module(read("src/draw.typ"), name: "Draw")

#show-module-fn(draw-module, "line")
```example
line((-1.5, 0), (1.5, 0))
line((0, -1.5), (0, 1.5))
```

==== Styling

#def-arg("mark", `<dictionary> or <auto>`, default: auto, [The styling to apply to marks on the line, see `mark`])

#show-module-fn(draw-module, "rect")
```example
rect((0,0), (1,1))
rect((-1.5, 1.5), (1.5, -1.5))
```

#show-module-fn(draw-module, "arc")
```example
arc((0,0), start: 45deg, stop: 135deg)
arc((0,-0.5), start: 45deg, delta: 90deg, mode: "CLOSE")
arc((0,-1), stop: 135deg, delta: 90deg, mode: "PIE")
```

==== Styling

#def-arg("radius", `<number> or <array>`, default: 1, [The radius of the arc. This is also a global style shared with circle!])
#def-arg("mode", `<string>`, default: `"OPEN"`, [The options are "OPEN" (the default, just the arc), "CLOSE" (a circular segment) and "PIE" (a circular sector).])

#show-module-fn(draw-module, "circle")
```example
circle((0,0))
// Draws an ellipse
circle((0,-2), radius: (0.75, 0.5))
```

#show-module-fn(draw-module, "circle-through")
```example
let (a, b, c) = ((0,0), (2,-.5), (1,1))
line(a, b, c, close: true, stroke: gray)
circle-through(a, b, c, name: "c")
circle("c.center", radius: .05, fill: red)
```

==== Styling

#def-arg("radius", `<number> or <length> or <array of <number> or <length>>`, default: "1", [The circle's radius. If an array is given an ellipse will be drawn where the first item is the `x` radius and the second item is the `y` radius. This is also a global style shared with arc!])

#show-module-fn(draw-module, "bezier")
```example
let (a, b, c) = ((0, 0), (2, 0), (1, 1))
line(a, c,  b, stroke: gray)
bezier(a, b, c)

let (a, b, c, d) = ((0, -1), (2, -1), (.5, -2), (1.5, 0))
line(a, c, d, b, stroke: gray)
bezier(a, b, c, d)
```

#show-module-fn(draw-module, "bezier-through")
```example
let (a, b, c) = ((0, 0), (1, 1), (2, -1))
line(a, b, c, stroke: gray)
bezier-through(a, b, c, name: "b")

// Show calculated control points
line(a, "b.ctrl-0", "b.ctrl-1", c, stroke: gray)
```

#show-module-fn(draw-module, "content")
```example
content((0,0), [Hello World!])
```

```example
let (a, b) = ((1,0), (3,1))

line(a, b)
content((a, .5, b), angle: b, [Text on a line], anchor: "bottom")
```

```example
content((0,0), (2,1), par(justify: false)[This is a long text.], frame: "rect",
  fill: gray, stroke: none)
```

==== Styling
This draw element is not affected by fill or stroke styling.

#def-arg("padding", `<length>`, default: 0em, "")

#show-module-fn(draw-module, "catmull")
```example
catmull((0,0), (1,1), (2,-1), (3,0), tension: .4, stroke: blue)
catmull((0,0), (1,1), (2,-1), (3,0), tension: .5, stroke: red)
```

#show-module-fn(draw-module, "grid")
```example
grid((0,0), (3,2), help-lines: true)
```


#show-module-fn(draw-module, "mark")
```example
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
```

==== Styling

#def-arg("symbol", `<string>`, default: ">", [The type of mark to draw when using the `mark` function.])
#def-arg("start", `<string>`, [The type of mark to draw at the start of a path.])
#def-arg("end", `<string>`, [The type of mark to draw at the end of a path.])
#def-arg("size", `<number>`, default: "0.15", [The size of the marks.])
#def-arg("angle", `<angle>`, default: 45deg, [Angle for triangle style marks ("<" and ">")])

== Path Transformations <path-transform>

#show-module-fn(draw-module, "merge-path")
```example
// Merge two different paths into one
merge-path({
  line((0, 0), (1, 0))
  bezier((), (0, 0), (1,1), (0,1))
}, fill: white)
```

#show-module-fn(draw-module, "group")
```example
// Create group
group({
  stroke(5pt)
  scale(.5); rotate(45deg)
  rect((-1,-1),(1,1))
})
rect((-1,-1),(1,1))
```

#show-module-fn(draw-module, "anchor")
```example
group(name: "g", {
  circle((0,0))
  anchor("x", (.4,.1))
})
circle("g.x", radius: .1)
```

#show-module-fn(draw-module, "copy-anchors")
```example
group(name: "g", {
  rotate(45deg)
  rect((0,0), (1,1), name: "r")
  copy-anchors("r")
})
circle("g.top", radius: .1, fill: black)
```

#show-module-fn(draw-module, "place-anchors")
```typc
place-anchors(name: "demo",
              bezier((0,0), (3,0), (1,-1), (2,1)),
              (name: "a", pos: .15),
              (name: "mid", pos: .5))
circle("demo.a", radius: .1, fill: black)
circle("demo.mid", radius: .1, fill: black)
```

#show-module-fn(draw-module, "place-marks")
```example
place-marks(bezier-through((0,0), (1,1), (2,0)),
            (mark: "|", size: .1, pos: 0),
            (mark: "o", size: .2, pos: .5),
            (mark: ">", size: .3, pos: 1),
            fill: black)
```

#show-module-fn(draw-module, "intersections")
```example
intersections("demo", {
  circle((0, 0))
  bezier((0,0), (3,0), (1,-1), (2,1))
  line((0,-1), (0,1))
  rect((1.5,-1),(2.5,1))
})
for-each-anchor("demo", (name) => {
  circle("demo." + name, radius: .1, fill: black)
})
```

== Layers

You can use layers to draw elements below or on top of other elements by using layers
with a higher or lower index. When rendering, all draw commands are sorted by their layer (0 being the default).

#show-module-fn(draw-module, "on-layer")
```example
// Draw something behind text
set-style(stroke: none)
content((0, 0), [This is an example.], name: "text")
on-layer(-1, {
  circle("text.top-left", radius: .3, fill: red)
  circle("text.bottom", radius: .4, fill: green)
  circle("text.top-right", radius: .2, fill: blue)
})
```


== Transformations
All transformation functions push a transformation matrix onto the current transform stack.
To apply transformations scoped use a `group(...)` object.

Transformation martices get multiplied in the following order:
$ M_"world" = M_"world" dot M_"local" $


#show-module-fn(draw-module, "translate")
```example
// Outer rect
rect((0,0), (2,2))
// Inner rect
translate((.5,.5,0))
rect((0,0), (1,1))
```

#show-module-fn(draw-module, "set-origin")
```example
// Outer rect
rect((0,0), (2,2), name: "r")
// Move origin to top edge
set-origin("r.above")
circle((0, 0), radius: .1)
```

#show-module-fn(draw-module, "set-viewport")
```example
rect((0,0), (2,2))
set-viewport((0,0), (2,2), bounds: (10, 10))
circle((5,5))
```

#show-module-fn(draw-module, "rotate")
```example
// Rotate on z-axis
rotate((z: 45deg))
rect((-1,-1), (1,1))
// Rotate on y-axis
rotate((y: 80deg))
circle((0,0))
```

#show-module-fn(draw-module, "scale")
```example
// Scale x-axis
scale((x: 1.8))
circle((0,0))
```

== Context Modification

The context of a canvas holds the canvas' internal state like style and transformation.
Note that the fields of the context of a canvas are considered private and therefore
unstable. You can add custom values to the context, but in order to prevent naming
conflicts with future CeTZ versions, try to assign unique names.

#show-module-fn(draw-module, "set-ctx")
```example
// Setting a custom transformation matrix
set-ctx(ctx => {
  let mat = ((1, 0, .5, 0),
             (0, 1, 0, 0),
             (0, 0, 1, 0),
             (0, 0, 0, 1))
  ctx.transform = mat
  return ctx
})
circle((z: 0), fill: red)
circle((z: 1), fill: blue)
circle((z: 2), fill: green)
```

#show-module-fn(draw-module, "get-ctx")
```example
// Print the transformation matrix
get-ctx(ctx => {
  content((), [#repr(ctx.transform)])
})
```

= Coordinate Systems <coordinate-systems>
A _coordinate_ is a position on the canvas on which the picture is drawn. They take the form of dictionaries and the following sub-sections define the key value pairs for each system. Some systems have a more implicit form as an array of values and `CeTZ` attempts to infer the system based on the element types.


== XYZ <coordinate-xyz>
Defines a point `x` units right, `y` units upward, and `z` units away.

#def-arg("x", [`<number>` or `<length>`], default: 0, [The number of units in the `x` direction.])
#def-arg("y", [`<number>` or `<length>`], default: 0, [The number of units in the `y` direction.])
#def-arg("z", [`<number>` or `<length>`], default: 0, [The number of units in the `z` direction.])

The implicit form can be given as an array of two or three `<number>` or `<length>`, as in `(x,y)` and `(x,y,z)`.

```example
line((0,0), (x: 1))
line((0,0), (y: 1))
line((0,0), (z: 1))

// Implicit form
line((0, -2), (1, -2))
line((0, -2), (0, -1, 0))
line((0, -2), (0, -2, 1))
```

== Previous <previous>
Use this to reference the position of the previous coordinate passed to a draw function. This will never reference the position of a coordinate used in to define another coordinate. It takes the form of an empty array `()`. The previous position initially will be `(0, 0, 0)`.

```example
line((0,0), (1, 1))

// Draws a circle at (1,1)
circle(())
```

== Relative <coordinate-relative>
Places the given coordinate relative to the previous coordinate. Or in other words, for the given coordinate, the previous coordinate will be used as the origin. Another coordinate can be given to act as the previous coordinate instead.

#def-arg("rel", `<coordinate>`, "The coordinate to be place relative to the previous coordinate.")
#def-arg("update", `<bool>`, default: true, "When false the previous position will not be updated.")
#def-arg("to", `<coordinate>`, default: (), "The coordinate to treat as the previous coordinate.")

In the example below, the red circle is placed one unit below the blue circle. If the blue circle was to be moved to a different position, the red circle will move with the blue circle to stay one unit below.

```example
circle((0, 0), stroke: blue)
circle((rel: (0, -1)), stroke: red)
```

== Polar
Defines a point a `radius` distance away from the origin at the given `angle`.

#def-arg("angle", `<angle>`, [The angle of the coordinate. An angle of `0deg` is to the right, a degree of `90deg` is upward. See https://typst.app/docs/reference/layout/angle/ for details.])
#def-arg("radius", `<number> or <length> or <array of length or number>`, [The distance from the origin. An array can be given, in the form `(x, y)` to define the `x` and `y` radii of an ellipse instead of a circle.])

```example
line((0,0), (angle: 30deg, radius: 1cm))
```

The implicit form is an array of the angle then the radius `(angle, radius)` or `(angle, (x, y))`. 

```example
line((0,0), (30deg, 1), (60deg, 1), 
     (90deg, 1), (120deg, 1), (150deg, 1), (180deg, 1))
```

== Barycentric
In the barycentric coordinate system a point is expressed as the linear combination of multiple vectors. The idea is that you specify vectors $v_1$, $v_2$ ..., $v_n$ and numbers $alpha_1$, $alpha_2$, ..., $alpha_n$. Then the barycentric coordinate specified by these vectors and numbers is $ (alpha_1 v_1 + alpha_2 v_1 + dots.c + alpha_n v_n)/(alpha_1 + alpha_2 + dots.c + alpha_n) $

#def-arg("bary", `<dictionary>`, [A dictionary where the key is a named element and the value is a `<float>`. The `center` anchor of the named element is used as $v$ and the value is used as $a$.])

```example
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
```

== Anchor
Defines a point relative to a named element using anchors, see @anchors.

#def-arg("name", `<string>`, [The name of the element that you wish to use to specify a coordinate.])
#def-arg("anchor", `<string>`, [An anchor of the element. If one is not given a default anchor will be used. On most elements this is `center` but it can be different.])

You can also use implicit syntax of a dot separated string in the form `"name.anchor"`.

```example
line((0,0), (3,2), name: "line")
circle("line.end", name: "circle")
rect("line.start", "circle.left")
```

== Tangent
This system allows you to compute the point that lies tangent to a shape. In detail, consider an element and a point. Now draw a straight line from the point so that it "touches" the element (more formally, so that it is _tangent_ to this element). The point where the line touches the shape is the point referred to by this coordinate system.

#def-arg("element", `<string>`, [The name of the element on whose border the tangent should lie.])
#def-arg("point", `<coordinate>`, [The point through which the tangent should go.])
#def-arg("solution", `<integer>`, [Which solution should be used if there are more than one.])

A special algorithm is needed in order to compute the tangent for a given shape. Currently it does this by assuming the distance between the center and top anchor (See @anchors) is the radius of a circle. 

```example
grid((0,0), (3,2), help-lines: true)

circle((3,2), name: "a", radius: 2pt)
circle((1,1), name: "c", radius: 0.75)
content("c", $ c $, anchor: "top-right", padding: .1)

stroke(red)
line("a", (element: "c", point: "a", solution: 1),
     "c", (element: "c", point: "a", solution: 2),
     close: true)
```

== Perpendicular
Can be used to find the intersection of a vertical line going through a point $p$ and a horizontal line going through some other point $q$.

#def-arg("horizontal", `<coordinate>`, [The coordinate through which the horizontal line passes.])
#def-arg("vertical", `<coordinate>`, [The coordinate through which the vertical line passes.])

You can use the implicit syntax of `(horizontal, "-|", vertical)` or `(vertical, "|-", horizontal)`

```example
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
```

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

```example
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
```

```example
grid((0,0), (3,3), help-lines: true)
line((1,0), (3,2))
line((1,0), ((1, 0), 1, 10deg, (3,2)))
fill(red)
stroke(none)
circle(((1, 0), 0.5, 10deg, (3, 2)), radius: 2pt)
```

```example
grid((0,0), (4,4), help-lines: true)

fill(black)
stroke(none)
let n = 16
for i in range(0, n+1) {
  circle(((2,2), i / 8, i * 22.5deg, (3,2)), radius: 2pt)
}
```

You can even chain them together!

```example
grid((0,0), (3, 2), help-lines: true)
line((0,0), (3,2))
stroke(red)
line(((0,0), 0.3, (3,2)), (3,0))
fill(red)
stroke(none)
circle(
  ( // a
    (((0, 0), 0.3, (3, 2))),
    0.7,
    (3,0)
  ),
  radius: 2pt
)
```

```example
grid((0,0), (3, 2), help-lines: true)
line((1,0), (3,2))
for (l, c) in ((0cm, "0cm"), (1cm, "1cm"), (15mm, "15mm")) {
  content(((1,0), l, (3,2)), box(fill: white, $ #c $))
}
```

== Function
An array where the first element is a function and the rest are coordinates will cause the function to be called with the resolved coordinates. The resolved coordinates have the same format as the implicit form of the 3-D XYZ coordinate system, @coordinate-xyz.

The example below shows how to use this system to create an offset from an anchor, however this could easily be replaced with a relative coordinate with the `to` argument set, @coordinate-relative.

```example
circle((0, 0), name: "c")
fill(red)
circle((v => cetz.vector.add(v, (0, -1)), "c.right"), radius: 0.3)
```

= Utility

#show-module-fn(draw-module, "for-each-anchor")
```example
// Label nodes anchors
rect((0, 0), (2,2), name: "my-rect")
for-each-anchor("my-rect", (name) => {
  if not name in ("above", "below", "default") {

  content((), box(inset: 1pt, fill: white, text(8pt, [#name])),
          angle: -45deg)
  }
})
```

= Libraries

== Tree
#let tree-module = tidy.parse-module(read("src/lib/tree.typ"), name: "Tree")

With the tree library, CeTZ provides a simple tree layout algorithm.

#tidy.show-module(tree-module, show-module-name: false)
```example
import cetz.tree

let data = ([Root], ([A], [A-A], [A-B]), ([B], [B-A]))
tree.tree(data, content: (padding: .1), line: (stroke: blue))
```

```example
import cetz.tree

let data = ([Root], ([\*], [A-A], [A-B]), ([B], [B-A]))
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
```

=== Node <tree-node>

A tree node is an array of nodes. The first array item represents the
current node, all following items are direct children of that node.
The node itselfes can be of type `content` or `dictionary` with a key `content`.

== Plot
#let plot-module = tidy.parse-module(read("src/lib/plot.typ"), name: "Plot")
#let plot-module-line = tidy.parse-module(read("src/lib/plot/line.typ"),
  name: "Plot - Line")
#let plot-module-contour = tidy.parse-module(read("src/lib/plot/contour.typ"),
  name: "Plot - Contour")
#let plot-module-boxwhisker = tidy.parse-module(read("src/lib/plot/boxwhisker.typ"),
  name: "Plot - Boxwhisker")
#let plot-module-sample = tidy.parse-module(read("src/lib/plot/sample.typ"),
  name: "Plot - Sample")

The library `plot` of CeTZ allows plotting 2D data.

=== Types

Types commonly used by function of the `plot` library:
/ `domain`: Tuple representing a functions domain as closed interval.
            Example domains are: `(0, 1)` for $[0, 1]$ or
            `(-calc.pi, calc.pi)` for $[-pi, pi]$.

#tidy.show-module(plot-module, show-module-name: false)
#tidy.show-module(plot-module-line, show-module-name: false)
#tidy.show-module(plot-module-contour, show-module-name: false)
#tidy.show-module(plot-module-boxwhisker, show-module-name: false)
#tidy.show-module(plot-module-sample, show-module-name: false)

=== Examples

```example
import cetz.plot
plot.plot(size: (3,2), x-tick-step: 180, y-tick-step: 1,
          x-unit: $degree$, {
  plot.add(domain: (0, 360), x => calc.sin(x * 1deg))
})
```

```example
import cetz.plot
plot.plot(size: (3,2), x-tick-step: 180, y-tick-step: 1,
          x-unit: $degree$, y-max: .5, {
  plot.add(domain: (0, 360), x => calc.sin(x * 1deg))
  plot.add(domain: (0, 360), x => calc.cos(x * 1deg),
           samples: 10, mark: "x", style: (mark: (stroke: blue)))
})
```

```example
import cetz.plot
import cetz.palette

// Axes can be styled!
// Set the tick length to .1:
set-style(axes: (tick: (length: .1)))

// Plot something
plot.plot(size: (3,3), x-tick-step: 1, axis-style: "left", {
  for i in range(0, 3) {
    plot.add(domain: (-4, 2),
      x => calc.exp(-(calc.pow(x + i, 2))),
      fill: true, style: palette.tango)
  }
})
```

```example
import cetz.plot
plot.plot(size: (3,2), x-tick-step: 1, y-tick-step: 1, {
  let z(x, y) = {
    (1 - x/2 + calc.pow(x,5) + calc.pow(y,3)) * calc.exp(-(x*x) - (y*y))
  }
  plot.add-contour(x-domain: (-2, 3), y-domain: (-3, 3),
                   z, z: (.1, .4, .7), fill: true)
})
```

=== Styling <plot.style>

The following style keys can be used (in addition to the standard keys)
to style plot axes. Individual axes can be styled differently by
using their axis name as key below the `axes` root.

```typc
set-style(axes: ( /* Style for all axes */ ))
set-style(axes: (bottom: ( /* Style axis "bottom" */)))
```

Axis names to be used for styling:
- School-Book and Left style:
  - `x`: X-Axis
  - `y`: Y-Axis
- Scientific style:
  - `left`: Y-Axis
  - `right`: Y2-Axis
  - `bottom`: X-Axis
  - `top`: X2-Axis

==== Default `scientific` Style
#raw(repr(axes.default-style))

==== Default `school-book` Style
#raw(repr(axes.default-style-schoolbook))

== Chart
#let chart-module = tidy.parse-module(read("src/lib/chart.typ"), name: "Chart")
#let chart-boxwhisker-module = tidy.parse-module(read("src/lib/chart/boxwhisker.typ"), name: "Chart - Boxwhisker")

With the `chart` library it is easy to draw charts.

Supported charts are:
- `barchart(..)` and `columnchart(..)`: A chart with horizontal/vertical growing bars
  - `mode: "basic"`: (default): One bar per data row
  - `mode: "clustered"`: Multiple grouped bars per data row
  - `mode: "stacked"`: Multiple stacked bars per data row
  - `mode: "stacked100"`: Multiple stacked bars relative to the sum of a data row
- `boxwhisker(..)`: A box-plot chart

#tidy.show-module(chart-module, show-module-name: false)

=== Examples -- Bar Chart <barchart-examples>
==== Basic
#example(vertical: true,
```typc
import cetz.chart
let data = (("A", 10), ("B", 20), ("C", 13))
chart.barchart(size: (10, auto), x-tick-step: 10, data)
```)

==== Clustered
#example(vertical: true,
```typc
import cetz.chart
let data = (("A", 10, 12, 22), ("B", 20, 1, 7), ("C", 13, 8, 9))
chart.barchart(size: (10, auto), mode: "clustered",
               x-tick-step: 10, value-key: (..range(1, 4)), data)
```)

==== Stacked
#example(vertical: true,
```typc
import cetz.chart
let data = (("A", 10, 12, 22), ("B", 20, 1, 7), ("C", 13, 8, 9))
chart.barchart(size: (10, auto), mode: "stacked",
               x-tick-step: 10, value-key: (..range(1, 4)), data)
```)

=== Examples -- Column Chart <columnchart-examples>
==== Basic, Clustered and Stacked
#example(vertical: true,
```typc
import cetz.chart
// Left
let data = (("A", 10), ("B", 20), ("C", 13))
group(name: "a", {
  anchor("default", (0,0))
  chart.columnchart(size: (auto, 4), data)
})
// Center
let data = (("A", 10, 12, 22), ("B", 20, 1, 7), ("C", 13, 8, 9))
set-origin("a.bottom-right")
group(name: "b", anchor: "bottom-left", {
  anchor("default", (0,0))
  chart.columnchart(size: (auto, 4),
    mode: "clustered", value-key: (1,2,3), data)
})
// Right
let data = (("A", 10, 12, 22), ("B", 20, 1, 7), ("C", 13, 8, 9))
set-origin("b.bottom-right")
group(name: "c", anchor: "bottom-left", {
  anchor("default", (0,0))
  chart.columnchart(size: (auto, 4),
    mode: "stacked", value-key: (1,2,3), data)
})
```)

#tidy.show-module(chart-boxwhisker-module, show-module-name: false)

=== Styling

Charts share their axis system with plots and therefore can be
styled the same way, see @plot.style.

==== Default `barchart` Style
#raw(repr(chart.barchart-default-style))

==== Default `columnchart` Style
#raw(repr(chart.columnchart-default-style))

== Palette <palette>
#let palette-module = tidy.parse-module(read("src/lib/palette.typ"), name: "Palette")

A palette is a function that returns a style for an index.
The palette library provides some predefined palettes.

#tidy.show-module(palette-module, show-module-name: false)

#let show-palette(p) = {
  canvas({
    import lib.draw: *
    for i in range(p("len")) {
      if calc.rem(i, 10) == 0 { move-to((rel: (0, -.5))) }
      rect((), (rel: (1,.5)), name: "r", ..p(i))
      move-to("r.bottom-right")
    }
  })
} 

=== List of predefined palettes
- `gray` #show-palette(palette.gray)
- `red` #show-palette(palette.red)
- `blue` #show-palette(palette.blue)
- `rainbow` #show-palette(palette.rainbow)
- `tango-light` #show-palette(palette.tango-light)
- `tango` #show-palette(palette.tango)
- `tango-dark` #show-palette(palette.tango-dark)

== Angle <angle>
#let angle-module = tidy.parse-module(read("src/lib/angle.typ"), name: "Angle")

The `angle` function of the angle module allows drawing angles with an optional label.

#tidy.show-module(angle-module, show-module-name: false)

```example
import cetz.angle: angle
let (a, b, c) = ((0,0), (-1,1), (1.5,0))
line(a, b)
line(a, c)
set-style(angle: (radius: 1, label-radius: .5), stroke: blue)
angle(a, c, b, label: $alpha$, mark: (end: ">"), stroke: blue)
set-style(stroke: red)
angle(a, b, c, label: n => $#{n/1deg} degree$,
  mark: (end: ">"), stroke: red, inner: false)
```

==== Default `angle` Style
#raw(repr(angle.default-style))

== Decorations <decorations>
#let decorations-module = tidy.parse-module(read("src/lib/decorations.typ"), name: "Decorations")

Various pre-made shapes and lines.

#show-module-fn(decorations-module, "brace")
```example
import cetz.decorations: brace
let text = text.with(size: 12pt, font: "Linux Libertine")

brace((0, 0), (4, -.5), pointiness: 25deg, outer-pointiness: auto, amplitude: .8, debug: true)
brace((0, -.5), (0, -3.5), name: "brace")
content("brace.content", [$P_1$])

// styling can be passed to the underlying `merge-path` call
brace((1, -3), (4, -3), amplitude: 1, pointiness: .5, stroke: orange + 2pt, fill: maroon, close: true, name: "saloon")
content((rel: (0, -.15), to: "saloon.center"), text(fill: orange, smallcaps[*Saloon*]))

// as part of another path
set-origin((2, -5))
merge-path({
  brace((+1, .5), (+1, -.5), amplitude: .3, pointiness: .5)
  brace((-1, -.5), (-1, .5), amplitude: .3, pointiness: .5)
}, fill: white, close: true)
content((0, 0), text(size: 10pt)[Hello, World!])

brace((-1.5, -2.5), (2, -2.5), pointiness: 1, outer-pointiness: 1, stroke: olive, fill: green, name: "hill")
content((rel: (.3, .1), to: "hill.center"), text[*εїз*])
```

==== Styling

#def-arg("amplitude", `<number>`, default: .7, [Determines how much the brace rises above the base line.])
#def-arg("pointiness", `<number> or <angle>`, default: 15deg, [How pointy the spike should be. #0deg or `0` for maximum pointiness, #90deg or `1` for minimum.])
#def-arg("outer-pointiness", `<number> or <angle> or <auto>`, default: 0, [How pointy the outer edges should be. #0deg or `0` for maximum pointiness (allowing for a smooth transition to a straight line), #90deg or `1` for minimum. Setting this to #auto will use the value set for `pointiness`.])
#def-arg("content-offset", `<number>`, default: .3, [Offset of the `content` anchor from the spike.])
#def-arg("debug-text-size", `<length>`, default: 6pt, [Font size of displayed debug points when `debug` is #true.])

==== Default `brace` Style
#decorations.brace-default-style

#show-module-fn(decorations-module, "flat-brace")
```example
import cetz.decorations: flat-brace

flat-brace((), (x: 5))
flat-brace((0, 0), (5, 0), flip: true, aspect: .3)
flat-brace((), (rel: (-2, -1)), name: "a")
flat-brace((), (0, 0), amplitude: 1, curves: 1.5, outer-curves: .5)
content("a.content", [$P_2$])

flat-brace((0, -3), (5, -3), debug: true, amplitude: 1, aspect: .4, curves: (1.5, .9, 1, .1), outer-curves: (1, .3, .1, .7))

// triangle and square braces
flat-brace((0, -4), (2.4, -4), curves: (auto, 0, 0, 0))
flat-brace((2.6, -4), (5, -4), curves: 0)

merge-path(close: true, fill: white, {
  move-to((.5, -6))
  flat-brace((), (rel: (1, 1)))
  flat-brace((), (rel: (2, 0)), flip: true, name: "top")
  flat-brace((), (rel: (1, -1)))
  flat-brace((), (rel: (-1, -1)))
  flat-brace((), (rel: (-2, 0)), flip: true, name: "bottom")
  flat-brace((), (rel: (-1, 1)))
})
content(("top.spike", .5, "bottom.spike"), [Hello, World!])
```

==== Styling

#def-arg("amplitude", `<number>`, default: decorations.flat-brace-default-style.amplitude, [Determines how much the brace rises above the base line.])
#def-arg("aspect", `<number>`, default: decorations.flat-brace-default-style.aspect, [Determines the fraction of the total length where the spike will be placed.])
#block(breakable: false, def-arg("curves", `<array> or <number>`, default: decorations.flat-brace-default-style.curves, [
  Customizes the control points of the curved parts.
  Setting a single number is the same as setting ```typc (num, auto, auto, auto)```.
  Setting any item to #auto will use its default value.
  The first item specifies the curve widths as a fraction of the amplitude.
  The second item specifies the length of the green and blue debug lines as a fraction of the curve's width.
  The third item specifies the vertical offset of the red and purple debug lines as a fraction of the curve's height.
  The fourth item specifies the horizontal offset of the red and purple debug lines as a fraction of the curve's width.
]))
#def-arg("outer-curves", `<array> or <number> or <auto>`, default: decorations.flat-brace-default-style.outer-curves, [
  Customizes the control points of just the outer two curves (just the blue and purple debug lines).
  Overrides settings from `curves`.
  Setting the entire value or individual items to #auto uses the values from `curves` as fallbacks.
])
#def-arg("content-offset", `<number>`, default: decorations.flat-brace-default-style.content-offset, [Offset of the `content` anchor from the spike.])
#def-arg("debug-text-size", `<length>`, default: decorations.flat-brace-default-style.debug-text-size, [Font size of displayed debug points when `debug` is #true.])

==== Default `flat-brace` Style
#decorations.flat-brace-default-style

= Advanced Functions

== Coordinate

#let coord-module = tidy.parse-module(read("src/coordinate.typ"), name: "Coordinate")
#show-module-fn(coord-module, "resolve")

```example
line((0,0), (1,1), name: "l")
get-ctx(ctx => {
  // Get the vector of coordinate "l.center"
  content("l", [#cetz.coordinate.resolve(ctx, "l.center").at(1)], frame: "rect",
          stroke: none, fill: white)
})
```

== Styles

#let style-module = tidy.parse-module(read("src/styles.typ"), name: "Styles")
#show-module-fn(style-module, "resolve")

```example
get-ctx(ctx => {
  // Get the current line style
  content((0,0), [#cetz.styles.resolve(ctx.style, (:), root: "line")],
          frame: "rect",
          stroke: none, fill: white)
})
```

