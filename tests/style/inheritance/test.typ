#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#import draw: set-style, get-ctx, set-ctx

#let base = (my-key: "base")
#let merge = (my-merged-key: "merged")

#let debug-style(..args) = {
  get-ctx(ctx => {
    let style = cetz.styles.resolve(ctx.style, ..args)

    draw.content((0,0), [#repr(style)])
  })
}

#let assert-style-eq(key, value, base: base, merge: merge, root: none) = {
  get-ctx(ctx => {
    let style = cetz.styles.resolve(ctx.style, base: base, merge: merge, root: root)

    assert.eq(type(style), dictionary)

    if style.at(key) != value {
      panic(style)
    }
    assert.eq(style.at(key), value)
  })
}

// Test basic override behavior
#test-case({
  assert-style-eq("my-key", "base")

  // Set the style value.
  set-style(my-key: 1)
  assert-style-eq("my-key", 1)

  // Override the current style value.
  set-style(my-key: 2)
  assert-style-eq("my-key", 2)

  // Reset to the current base style by passing auto.
  set-style(my-key: auto)
  assert-style-eq("my-key", "base")
})

// Test merged style (override)
#test-case({
  // Use the default merge.
  assert-style-eq("my-merged-key", "merged")

  // Merge another dictionary.
  assert-style-eq("my-merged-key", "override", merge: (my-merged-key: "override"))
})

// Test custom root
#test-case({
  // Use a custom root.
  set-style(my-root: (my-key: "root"))
  assert-style-eq("my-key", "root", root: "my-root")

  // Fallback to the base value.
  set-style(my-root: (my-key: auto))
  assert-style-eq("my-key", "base", root: "my-root")

  // Fallback to the base even if existing in the
  // current style (but at root level!) value.
  set-style(stroke: "wrong-value")
  assert-style-eq("stroke", "base", root: "my-root", base: (stroke: "base"))
})

#test-case({
  import draw: *

  let next(body) = {
    translate((0,-.2,0))
    group(body)
  }

  next({
    line((0,0), (1,0))
  })
  next({
    set-style(stroke: blue)
    line((0,0), (1,0))
  })
  next({
    line((0,0), (1,0), stroke: blue)
  })
  next({
    // Blue arrow
    set-style(stroke: blue)
    line((0,0), (1,0), mark: (end: ">"))
  })
  next({
    // Blue arrow
    line((0,0), (1,0), mark: (end: ">"), stroke: blue)
  })
  next({
    // Blue + Green arrow head
    line((0,0), (1,0), mark: (end: ">", stroke: green), stroke: blue)
  })
  next({
    // Blue + Yellow arrow head
    set-style(mark: (stroke: yellow))
    line((0,0), (1,0), mark: (end: ">"), stroke: blue)
  })
  next({
    // Blue + Green arrow head
    set-style(mark: (stroke: yellow), stroke: red)
    line((0,0), (1,0), mark: (end: ">", stroke: green), stroke: blue)
  })
  next({
    // Blue + Yellow/Green arrow head
    set-style(mark: (stroke: yellow, fill: auto), stroke: blue, fill: blue)
    line((0,0), (1,0), mark: (end: ">"), fill: green, stroke: green)
  })
  next({
    // Blue arrow
    set-style(stroke: red)
    line((0,0), (1,0), mark: (end: ">"), stroke: blue)
  })
})
