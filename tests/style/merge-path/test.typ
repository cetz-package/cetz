#import "/src/lib.typ": *
#import draw: *

#let merged(..style) = merge-path(close: true, {
  line((0, 0), (1, 0))
  line((1, 0), (1, 1))
}, ..style)

#let drawables(body) = process.many(make-ctx(), body).drawables

// Named styles apply to the merged path, not its constituent lines.
#let paths = drawables({
  set-style(merge-path: (stroke: red, fill: blue, fill-rule: "even-odd"))
  merged()
  line((0, 0), (1, 0))
})
#assert.eq(paths.at(0).stroke.paint, red)
#assert.eq(paths.at(0).fill, blue)
#assert.eq(paths.at(0).fill-rule, "even-odd")
#assert.eq(paths.at(1).stroke.paint, black)
#assert.eq(paths.at(1).fill, none)
#assert.eq(paths.at(1).fill-rule, "non-zero")

// Missing or auto-valued named styles inherit the top-level style.
#for style in ((:), (stroke: auto, fill: auto, fill-rule: auto, mark: auto)) {
  let path = drawables({
    set-style(stroke: blue + 2pt, fill: yellow, fill-rule: "even-odd")
    set-style(merge-path: style)
    merged()
  }).first()
  assert.eq(path.stroke.paint, blue)
  assert.eq(path.stroke.thickness, 2pt)
  assert.eq(path.fill, yellow)
  assert.eq(path.fill-rule, "even-odd")
}

// Inline styles take precedence, and stroke dictionaries still merge.
#let path = drawables({
  set-style(stroke: 2pt, fill: yellow)
  set-style(merge-path: (stroke: red, fill: blue, fill-rule: "even-odd"))
  merged(stroke: green, fill: none, fill-rule: "non-zero")
}).first()
#assert.eq(path.stroke.paint, green)
#assert.eq(path.stroke.thickness, 2pt)
#assert.eq(path.fill, none)
#assert.eq(path.fill-rule, "non-zero")

// Marks can be inherited, set under the named style, or disabled inline.
#context {
  for named in (false, true) {
    let paths = drawables({
      if named {
        set-style(merge-path: (mark: (end: "|")))
      } else {
        set-style(mark: (end: "|"))
      }
      merged()
    })
    assert.eq(paths.filter(d => drawable.TAG.mark in d.tags).len(), 1)
  }
  let paths = drawables({
    set-style(merge-path: (mark: (end: "|")))
    merged(mark: none)
  })
  assert.eq(paths.len(), 1)
  assert.eq(paths.first().tags, ())
}
