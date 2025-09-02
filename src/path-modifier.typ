// Shorten or extend a path.
#let _shorten-path(ctx, style, path) = {
  import "path-util.typ": shorten-to

  let shorten = style.at("shorten", default: (0, 0))
  if type(shorten) != array {
    shorten = (shorten, shorten)
  }

  // Early exit on zero lengths
  if shorten.all(v => v in (0, 0%, 0pt)) {
    return none
  }

  // Do not attempt to shorten/extend closed paths
  let (origin, closed, segments) = path.first()
  if closed or segments == () {
    return none
  }

  return shorten-to(path, shorten, ignore-subpaths: true)
}


#let builtin = (
  shorten: _shorten-path,
)

/// Apply all enabled modifiers onto a path.
///
/// - ctx (context):
/// - style (style):
/// - path (path, array): A list of paths or a single path
/// -> path|array
#let apply-modifiers(ctx, style, path) = {
  if type(path) == array {
    return path.map(p => apply-modifiers(ctx, style, p))
  }

  let all-modifiers = ctx.at("path-modifiers", default: ())
  let enabled-modifiers = style.at("modifiers", default: ())

  for name in enabled-modifiers {
    assert(name in all-modifiers,
      message: "No modifier named '" + name + "' registered.")

    let new-path = (all-modifiers.at(name))(ctx, style, path.segments)
    if new-path != none {
      path.segments = new-path
    }
  }

  return path
}
