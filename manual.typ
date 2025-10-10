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

#let show-docstring(comment, level) = {
  let text = comment.text
  let arguments = comment.arguments
  let result = comment.result

  show raw.where(lang: "example"): it => render-example(it.text)
  show raw.where(lang: "example-vertical"): it => render-example(it.text, vertical: true)
  show regex("type:([\w-]+)"): it => show-type(it.text.replace("type:", ""))
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
#let show-module(name, level: 2) = {
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

= Canvas
#show-module("src/canvas.typ")

= Shapes
#show-module("src/draw/shapes.typ")

= Styling
#show-module("src/draw/styling.typ")

= Grouping
#show-module("src/draw/grouping.typ")

= Transformations
#show-module("src/draw/transformations.typ")

= Projection
#show-module("src/draw/projection.typ")

= Utility
#show-module("src/draw/util.typ")

= Libraries
== Angle
#show-module("src/lib/angle.typ", level: 3)

== Tree
#show-module("src/lib/tree.typ", level: 3)

== Decorations
=== Path Decorations
#show-module("src/lib/decorations/path.typ", level: 4)

=== Braces
#show-module("src/lib/decorations/brace.typ", level: 4)

== Palette
#show-module("src/lib/palette.typ", level: 3)

== Internals
=== Coordinate
#show-module("src/coordinate.typ", level: 4)

=== Styles
#show-module("src/styles.typ", level: 4)

=== Process
#show-module("src/process.typ", level: 4)

=== Complex
#show-module("src/complex.typ", level: 4)

=== Vector
#show-module("src/vector.typ", level: 4)

=== Matrix
#show-module("src/matrix.typ", level: 4)

=== Drawable
#show-module("src/drawable.typ", level: 4)

=== Anchor
#show-module("src/anchor.typ", level: 4)

=== Mark
#show-module("src/mark.typ", level: 4)

=== Bezier
#show-module("src/bezier.typ", level: 4)

=== AABB
#show-module("src/aabb.typ", level: 4)

=== Hobby
#show-module("src/hobby.typ", level: 4)

=== Intersection
#show-module("src/hobby.typ", level: 4)

=== Path-Util
#show-module("src/path-util.typ", level: 4)

=== Util
#show-module("src/util.typ", level: 4)
