#set page(width: auto, height: auto)
#import "/src/lib.typ": *
#import "/tests/helper.typ": *

#test-case({
  import draw: *

  let default-style = (
    stroke: black,
    fill: blue,
  )

  set-ctx(ctx => {
    ctx.style.insert("my-pkg", (
      element: (
        stroke: auto,
        fill: green,
      )
    ))
    return ctx
  })

  let assert-fill(eq) = {
    get-ctx(ctx => {
      let style = styles.resolve(ctx.style, root: ("my-pkg", "element"), base: default-style)
      assert.eq(style.fill, eq)
    })
  }

  scope({
    set-style(my-pkg: (element: (fill: auto)))
    assert-fill(blue)
  })
  scope({
    set-style(my-pkg: (element: (fill: red)))
    assert-fill(red)
  })
  scope({
    set-style(element: (fill: red))
    assert-fill(green)
  })
})

#test-case({
  let style = styles.resolve(
    (my-pkg: (element: (stroke: auto))),
    root: ("my-pkg", "element"),
    base: (my-pkg: (element: (fill: blue))),
    merge: (my-pkg: (element: (fill: red))),
  )

  assert.eq(style.fill, red)
  assert.eq(style.stroke, auto)
})
