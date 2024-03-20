#import "/src/process.typ"
#import "/src/drawable.typ"
#import "/src/styles.typ"
#import "/src/path-util.typ": expand-segments

#let wasm = plugin("/plugin/cetz.wasm")

#let _clip(a, b, mode: "union", name: none, ..style) = {
  assert(mode in ("union", "intersection", "difference", "xor", "divide"),
    message: "Invalid clip mode")

  (ctx => {
    let style = styles.resolve(ctx.style, merge: style.named())
    let (drawables: a-drawables, ..) = process.many(ctx, a)
    let (drawables: b-drawables, ..) = process.many(ctx, b)

    let mode_data = cbor.encode(mode)

    let a_data = cbor.encode(a-drawables.map(expand-segments))
    let b_data = cbor.encode(b-drawables.map(expand-segments))

    let res = cbor.decode(wasm.clip_path(a_data,
                                         b_data,
                                         mode_data))
    let clipped = ()
    for sub-path in res {
      clipped.push(drawable.path(sub-path,
        stroke: style.stroke, fill: style.fill, close: true))
    }

    return (
      ctx: ctx,
      drawables: clipped,
    )
  },)
}

/// Return a union path(s) between paths a and b.
///
/// A union path is a path that uses the outer contour of both paths.
///
/// - a (element): Path a
/// - b (element): Path b
/// -> element
#let union-path = _clip.with(mode: "union")

/// Return the intersection path(s) between paths a and b
///
/// - a (element): Path a
/// - b (element): Path b
/// -> element
#let intersection-path = _clip.with(mode: "intersection")

/// Return the difference path(s) between paths a and b
///
/// - a (element): Path a
/// - b (element): Path b
/// -> element
#let difference-path = _clip.with(mode: "difference")
