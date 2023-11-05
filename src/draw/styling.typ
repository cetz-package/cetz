#import "/src/util.typ"

#let set-style(..style) = {
  assert.eq(
    style.pos().len(),
    0,
    message: "set-style takes no positional arguments",
  )
  
  (ctx => {
    ctx.style = util.merge-dictionary(ctx.style, style.named())
    
    return (ctx: ctx)
  },)
}

#let fill(fill) = set-style(fill: fill)
#let stroke(stroke) = set-style(stroke: stroke)
