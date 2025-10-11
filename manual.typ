#import "/src/lib.typ" as cetz

#import "/docs/style.typ": show-type
#import "/docs/typlodocus/extractor.typ"

#set heading(numbering: "1.")

#let modules = (
  // Canvas
  "src/canvas.typ",

  // Draw
  "src/draw/util.typ",
  "src/draw/shapes.typ",
  "src/draw/styling.typ",
  "src/draw/grouping.typ",
  "src/draw/projection.typ",
  "src/draw/transformations.typ",

  // Libs
  "src/lib/angle.typ",
  "src/lib/tree.typ",
  "src/lib/decorations/path.typ",
  "src/lib/decorations/brace.typ",
  "src/lib/palette.typ",

  // Internals
  "src/coordinate.typ",
  "src/styles.typ",
  "src/process.typ",
  "src/drawable.typ",
  "src/anchor.typ",
  "src/mark.typ",
  "src/bezier.typ",
  "src/aabb.typ",
  "src/hobby.typ",
  "src/intersection.typ",
  "src/path-util.typ",
  "src/util.typ",
  "src/complex.typ",
  "src/vector.typ",
  "src/matrix.typ",
)

#let docs = modules.map(filename => {
  (filename, extractor.extract-doc-comments(read(filename).split("\n")))
}).to-dict()

// Generate query metadata
#metadata(docs) <metadata>

/// Show a function signature annoted with types from the docstring
#let show-annotated-signature(signature, comment) = block({
  set par(leading: 0.35em)

  let name = signature.name

  let arguments = signature.arguments.map(arg => {
    let comment-arg = comment.arguments.find(comment-arg => {
      comment-arg.name == arg.name
    })
    if comment-arg == none {
      comment-arg = (types: (), name: name)
    }

    let types = comment-arg.types
    if types == none { types = () }

    if arg.has-default {
      raw(arg.name + ":") + [ ] + types.map(show-type).join([ ])
    } else {
      raw(arg.name) + [ ] + types.map(show-type).join([ ])
    }
  })

  let result = if comment.result != () {
    [ #sym.arrow.r ] + comment.result.map(r => show-type(r.type)).join([ or ])
  } else {
    []
  }

  text(blue, raw(name)) + raw("(") + [\ ] + arguments.map(v => h(1em) + v).join([,\ ]) + [\ ] + raw(")") + result
})

/// Render an example side-by-side with its source code.
#let render-example(code, vertical: false) = {
  let columns = if vertical {
    (1fr,)
  } else {
    (1fr, 2fr,)
  }

  let align = if vertical {
    (x, y) => (center + top, left + top).at(y)
  } else {
    (x, y) => (center + horizon, left + top).at(x)
  }

  let stroke = 1pt + gray
  let line = if vertical { table.hline } else { table.vline }

  block(radius: 2pt, stroke: stroke, {
    table(columns: columns, align: align, stroke: none,
      cetz.canvas({
        let preamble = "import cetz.draw: *\n"
        eval(preamble + code, mode: "code", scope: (
          cetz: cetz,
        ))
      }),
      line(stroke: (paint: gray, thickness: 1pt, dash: "dashed")),
      raw(code, lang: "typc"),
    )
  })
}

#show raw.where(lang: "example"): it => render-example(it.text)
#show raw.where(lang: "example-vertical"): it => render-example(it.text, vertical: true)
#show regex("type:([\w-]+)"): it => show-type(it.text.replace("type:", ""))

#let show-docstring(comment, level) = {
  let text = comment.text
  let arguments = comment.arguments
  let result = comment.result

  set heading(outlined: false, offset: level)

  block([
    #eval(text, mode: "markup", scope: (
      cetz: cetz,
    ))
  ])

  if arguments != () {
    heading("Parameters")
    list(..arguments.map(arg => {
      let types = arg.types
      if types == none { types = ("any",) }
      block(
        strong(raw(arg.name)) + [ ]
        + types.map(show-type).join([ ]) + [\ ]
        + eval(arg.text, mode: "markup")
      )
    }))
  }

  if result.any(r => r.text != "") {
    heading("Result")

    let show-result(r) = if r.text != "" {
      let type = r.type
      if type == none { type = "any" }
      block(
        show-type(type) + [\ ] + eval(r.text, mode: "markup")
      )
    }

    if result.len() > 1 {
      list(..result.map(show-result))
    } else {
      show-result(result.first())
    }
  }
}

/// Show a single module/file
#let show-module(name, level: 3) = {
  for item in docs.at(name) {
    if item.at("signature", default: none) == none {
      continue
    }

    let function-name = item.signature.name
    if function-name.starts-with("_") {
      continue
    }

    [#heading(function-name, level: level) #label(function-name)]
    show-annotated-signature(item.signature, item.comment)
    show-docstring(item.comment, level)
  }
}


#columns(2, outline(depth: 4))
#pagebreak()

= Overview
CeTZ, ein Typst Zeichenpaket, is a drawing package for Typst.
Its API is similar to Processing but with relative coordinates
and anchors from TikZ. You also won't have to worry about
accidentally drawing over other content as the canvas will
automatically resize. And remember: up is positive!

= Getting Started
== Usage
This is the minimal starting point in a `.typ` file:
```typst
#import "@preview/cetz:0.4.2"
#cetz.canvas({
  import cetz.draw: *
  ...
})
```

Note that draw functions are imported inside the scope of the canvas block.
This is recommended as some draw functions override Typst's
functions such as @line[`line`].

== Examples
From this point on only the code inside the
canvas block will be shown in examples unless specified otherwise.

```example
circle((0, 0))
line((1,-1), (2,1))
```

= Basics
The following chapters are about the basic and core concepts of CeTZ.
They are recommended reading for basic usage.

== Custom Types
Many CeTZ functions expect data in certain formats which we will call types.
Note that these are actually made up of Typst primitives.

/ type\:coordinate: A position on the canvas specified by any
  coordinate system. See @coordinate-systems[Coordinate Systems].
/ type\:number: Any of type:float, type:int or type:length
/ type\:style: Represents options passed to draw functions that
  affect how elements are drawn. They are normally taken in the form of
  named arguments to the draw functions or sometimes can be a dictionary
  for a single argument.

== The Canvas
The @canvas[canvas] function is what handles all of the logic and
processing in order to produce drawings. It's usually called with
a code block `{ ... }` as argument. The content of the curly braces is the
body of the canvas. Import all the draw functions you need at the top of
the body:
```typst
#cetz.canvas({
  import cetz.draw: *
})
```

You can now call the draw functions within the body and they'll
produce some graphics! Typst will evaluate the code block and pass the
result to the canvas function for rendering.

The canvas does not have typical width and height parameters.
Instead its size will grow and shrink to fit the drawn graphic.

By default $1$ coordinate unit is $1 "cm"$, this can be changed by setting the
`length:` parameter.

== Styling <styling>
You can style draw elements by passing the relevant named arguments
to their draw functions. All elements that draw something have
stroke and fill styling unless said otherwise.

/ fill: type:color or type:none (default: `none`) \
  How to fill the drawn element.
/ stroke: type:none or type:auto or type:length or type:color or type:dictionary or type:stroke (default: `black`) \
  How to stroke the border or the path of the draw element. #link("https://typst.app/docs/reference/visualize/line/#parameters-stroke")[See Typst's line documentation for more details.]

== Coordinate Systems <coordinate-systems>

= API
== Canvas
#show-module("src/canvas.typ")

== Shapes
#show-module("src/draw/shapes.typ")

== Styling
#show-module("src/draw/styling.typ")

== Grouping
#show-module("src/draw/grouping.typ")

== Transformations
#show-module("src/draw/transformations.typ")

== Projection
#show-module("src/draw/projection.typ")

== Utility
#show-module("src/draw/util.typ")

== Libraries
=== Angle
#show-module("src/lib/angle.typ", level: 4)

=== Tree
#show-module("src/lib/tree.typ", level: 4)

=== Decorations
==== Path Decorations
#show-module("src/lib/decorations/path.typ", level: 5)

==== Braces
#show-module("src/lib/decorations/brace.typ", level: 5)

=== Palette
#show-module("src/lib/palette.typ", level: 4)

=== Internals
==== Coordinate
#show-module("src/coordinate.typ", level: 5)

==== Styles
#show-module("src/styles.typ", level: 5)

==== Process
#show-module("src/process.typ", level: 5)

==== Complex
#show-module("src/complex.typ", level: 5)

==== Vector
#show-module("src/vector.typ", level: 5)

==== Matrix
#show-module("src/matrix.typ", level: 5)

==== Drawable
#show-module("src/drawable.typ", level: 5)

==== Anchor
#show-module("src/anchor.typ", level: 5)

==== Mark
#show-module("src/mark.typ", level: 5)

==== Bezier
#show-module("src/bezier.typ", level: 5)

==== AABB
#show-module("src/aabb.typ", level: 5)

==== Hobby
#show-module("src/hobby.typ", level: 5)

==== Intersection
#show-module("src/hobby.typ", level: 5)

==== Path-Util
#show-module("src/path-util.typ", level: 5)

==== Util
#show-module("src/util.typ", level: 5)
