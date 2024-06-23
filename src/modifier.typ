#import "/src/path-util.typ"

/// A path modifier is a function that accepts a contex, style and
/// a single drawable and returns a single (modified) drawable.
///
/// Example:
/// ```typ
/// (ctx, style, drawable) => {
///   // ... modify the drawable ...
///   return drawable
/// }
/// ```

// Function for slicing a path into three parts,
// a head, a mid section and a tail.
#let slice-segments(segments, start, end) = {
  let len = path-util.length(segments)
  if type(start) == ratio {
    start = len * start / 100%
  }
  if type(end) == ratio {
    end = len * end / 100%
  }

  let (head, mid, tail) = ((), segments, ())

  if start != 0 or end != len {
    mid = path-util.shorten-path(segments, start, end)
  }

  if start != 0 {
    head = path-util.shorten-path(segments, 0, len - start)
  }

  if end != len {
    tail = path-util.shorten-path(segments, len - end, 0)
  }

  return (head, mid, tail)
}

/// Apply a path modifier to a list of drawables
///
/// - ctx (context):
/// - style (style):
/// - elem (element): Single element
#let apply-modifier-fn(ctx, style, elem, fn, close) = {
  assert(type(fn) == function,
    message: "Path modifier must be of type function.")

  if "segments" in elem {
    let begin = style.at("begin", default: 0%)
    let end = style.at("end", default: 0%)

    let (head, mid, tail) = slice-segments(elem.segments, begin, end)
    let close = close and head == () and tail == ()
    elem.segments = head + (fn)(ctx, style, mid, close) + tail
  }

  return elem
}

/// Apply a path modifier to a list of drawables
#let apply-path-modifier(ctx, style, drawables, close) = {
  if type(drawables) != array {
    drawables = (drawables,)
  }

  let fns = if type(style.decoration) == array {
    style.decoration
  } else {
    (style.decoration,)
  }.map(n => {
    let name = if type(n) == dictionary {
      n.name
    } else {
      n
    }

    let extra-style = if type(n) == dictionary {
      n
    } else {
      (:)
    }

    let fn = if type(name) == str {
      assert(name in ctx.path-modifiers,
        message: "Unknown path-modifier: " + repr(n))
      ctx.path-modifiers.at(name)
    } else {
      name
    }

    (fn: fn, style: style + extra-style)
  })

  // Unset decorations to prevent unwanted recursion
  style.decoration = ()

  // Apply function on all drawables
  return drawables.map(d => {
    for fn in fns.filter(v => v.fn != none) {
      d = apply-modifier-fn(ctx, fn.style, d, fn.fn, close)
    }
    return d
  })
}
