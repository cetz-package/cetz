#set page(width: auto, height: auto)
#import "/src/lib.typ": *

#box(stroke: 2pt + red, canvas(length: 1cm, {
  import draw: *
  set-ctx(ctx => {
    ctx.my-custom-attribute = "123"
    return ctx
  })

  get-ctx(ctx => {
    set-style(stroke: green)
    content((0, 0), ctx.my-custom-attribute, frame: "rect")
  })

  // Note that the set-style is _not_ scoped!
  circle((0,0))
}))
