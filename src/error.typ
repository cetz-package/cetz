/// Add a backtrace entry for a single element
///
/// - ctx (Context): The current context
/// - element (string): The elements type (e.g. circle)
/// - name (none,string): The elements name
/// -> context
#let add-element-backtrace(ctx, element, name) = {
  let message = "element: " + element
  if name != none {
    message += ", name: " + name
  }

  ctx.backtrace.push(message)
  return ctx
}

#let _get-backtrace-string(ctx) = {
  if ctx != none and ctx.backtrace != () {
    return ". Backtrace: " + ctx.backtrace.rev().join("; ")
  }
  return ""
}

/// Panic but with cetz backtrace
#let panic(ctx, message) = {
  std.panic(message + _get-backtrace-string(ctx))
}

/// Assert but with cetz backtrace
#let assert(ctx, cond, message: "") = {
  std.assert(cond, message: message + _get-backtrace-string(ctx))
}
