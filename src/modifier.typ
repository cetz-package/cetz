#import "/src/path-util.typ"

/// A path modifier is a function that accepts a contex, style and
/// a single drawable and returns either a single replacement drawable,
/// or an dictionary with the keys `replacement` (single drawable) and `decoration` (list of drawables)
/// that contain a replacement and/or additional drawable to render.
///
/// Arguments:
///   - ctx (context):
///   - style (styles):
///   - drawable (drawable): Single drawable to modify/decorate
///   - close (bool): Boolean if the drawable is closed
///
/// Example:
/// ```typ
/// (ctx, style, drawable, close) => {
///   // ... modify the drawable ...
///   return (replacement: ..., decoration: ...)
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
/// -> List of elements
#let apply-modifier-fn(ctx, style, elem, fn, close) = {
  assert(type(fn) == function,
    message: "Path modifier must be of type function.")

  let new-elements = ()
  if "segments" in elem {
    let begin = style.at("begin", default: 0%)
    let end = style.at("end", default: 0%)

    let (head, mid, tail) = slice-segments(elem.segments, begin, end)
    let close = close and head == () and tail == ()
    let result = (fn)(ctx, style, mid, close)
    if type(result) != dictionary {
      result = (replacement: result)
    } else {
      new-elements += result.at("decoration", default: ())
    }

    let replace = result.at("replacement", default: none)
    if replace != none {
      let replacement-elem = elem
      replacement-elem.segments = head + replace + tail

      if replacement-elem.segments != () {
        new-elements.insert(0, replacement-elem)
      }
    } else {
      if head != () {
        let head-elem = elem
        head-elem.segments = head

        new-elements.insert(0, head-elem)
      }

      if tail != () {
        let tail-elem = elem
        tail-elem.segments = tail

        new-elements.push(tail-elem)
      }
    }
  }

  return new-elements
}

/// Apply a path modifier to a list of drawables
#let apply-path-modifier(ctx, style, drawables, close) = {
  if type(drawables) != array {
    drawables = (drawables,)
  }

  let fns = if type(style.modifier) == array {
    style.modifier
  } else {
    (style.modifier,)
  }.map(n => {
    let name = if type(n) == dictionary {
      n.at("name", default: none)
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

  // Unset modifiers to prevent unwanted recursion
  style.modifier = ()

  // Apply function on all drawables
  for fn in fns.filter(v => v.fn != none) {
    let new = ()
    for i in range(0, drawables.len()) {
      new += apply-modifier-fn(ctx, fn.style, drawables.at(i), fn.fn, close)
    }
    drawables = new
  }

  return drawables
}
