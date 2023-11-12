// Library for drawing springs
#import "/src/draw.typ"
#import "/src/styles.typ"
#import "/src/coordinate.typ"
#import "/src/vector.typ"

#let default-style = (
  /// Number of windings
  N: 10,
  /// width of the spring in the direction of the springs normal
  width: 1,
  stroke: auto,
)

/// Draw a zig-zag spring between two points
///
/// The number of windings can be controlled via the `N` style key,
/// and the width via `width`.
///
/// - start (coordinate): Start point
/// - end (coordinate): End point
/// - name: (none,string): Element name
/// - ..style: (style): Style
#let zigzag(start, end, name: none, ..style) = draw.group(name: name, ctx => {
  let style = styles.resolve(ctx, style.named(),
    base: default-style, root: "spring")

  let N = style.N
  assert(N > 0,
    message: "N must be greater than zero")

  let (_, start, end) = coordinate.resolve(ctx, start, end)
  let dir = vector.sub(end, start)
  let norm-a = vector.scale(vector.norm((-dir.at(1), dir.at(0), dir.at(2))), style.width / 2)
  let norm-b = vector.scale(norm-a, -1)

  let pts = ()
  for i in range(0, N, step: 1) {
    let a = vector.add(start, vector.scale(dir, (i+0) / N))
    let b = vector.add(start, vector.scale(dir, (i+1) / N))
    let s = vector.sub(b, a)
    if i == 0 {
      pts.push(a)
    }
    pts.push(vector.add(vector.add(a, norm-a), vector.scale(s, 1/4)))
    pts.push(vector.add(vector.add(a, norm-b), vector.scale(s, 3/4)))
    if i >= N - 1 {
      pts.push(b)
    }
  }
  draw.line(..pts, ..style, close: false, fill: none)
})

/// Draw a stretched sine spring
///
/// The number of windings can be controlled via the `N` style key,
/// and the width via `width`.
///
/// - start (coordinate): Start point
/// - end (coordinate): End point
/// - name: (none,string): Element name
/// - ..style: (style): Style
#let sine(start, end, name: none, ..style) = draw.group(name: name, ctx => {
  let style = styles.resolve(ctx, style.named(),
    base: default-style, root: "spring")

  let N = style.N
  assert(N > 0,
    message: "N must be greater than zero")

  let (_, start, end) = coordinate.resolve(ctx, start, end)
  let dir = vector.sub(end, start)
  let norm-a = vector.scale(vector.norm((-dir.at(1), dir.at(0), dir.at(2))), style.width / 2)
  let norm-b = vector.scale(norm-a, -1)

  draw.merge-path({
    for i in range(0, 2 * N, step: 2) {
      let a = vector.add(start, vector.scale(dir, (i+0) / N / 2))
      let m = vector.add(start, vector.scale(dir, (i+1) / N / 2))
      let b = vector.add(start, vector.scale(dir, (i+2) / N / 2))
      let s = vector.sub(b, a)
      draw.bezier-through(a, vector.add(vector.add(a, norm-a), vector.scale(s, 1/4)), m)
      draw.bezier-through(m, vector.add(vector.add(a, norm-b), vector.scale(s, 3/4)), b)
    }
  }, ..style, close: false, fill: none)
})
