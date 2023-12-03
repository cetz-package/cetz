#import "util.typ"
#import "sample.typ"
#import "../../draw.typ"
#import "../../process.typ"
#import "../../util.typ"

/// Add an annotation to the plot
///
/// An annotation is a sub-canvas that uses the plots coordinates specified
/// by its x and y axis.
///
/// #example(```
/// import cetz.plot
/// plot.plot(size: (2,2), x-tick-step: none, y-tick-step: none, {
///   plot.add(domain: (0, 2*calc.pi), calc.sin)
///   plot.add-annotation({
///     rect((0, -1), (calc.pi, 1), fill: rgb(50,50,200,50))
///     content((calc.pi, 0), [Here])
///   })
/// })
/// ```)
///
/// Bounds calculation is done naively, therefore fixed size content _can_ grow
/// out of the plot. You can adjust the padding manually to adjust for that. The
/// feature of solving the correct bounds for fixed size elements might be added
/// in the future.
///
/// - body (drawable): Elements to draw
/// - axes (axes): X and Y axis names
/// - resize (bool): If true, the plots axes get adjusted to contain the annotation
/// - padding (none,number,dictionary): Annotation padding that is used for axis
///   adjustment
/// - background (bool): If true, the annotation is drawn behind all plots, in the background.
///   If false, the annotation is drawn above all plots.
#let add-annotation(body, axes: ("x", "y"), resize: true, padding: none, background: false) = {
  ((
    type: "annotation",
    body: body,
    axes: axes,
    resize: resize,
    background: background,
    padding: util.as-padding-dict(padding),
  ),)
}

// Returns the adjusted axes for the annotation object
//
// -> array Tuple of x and y axis
#let calc-annotation-domain(ctx, x, y, annotation) = {
  if not annotation.resize {
    return (x, y)
  }

  let (ctx: ctx, bounds: bounds, drawables: _) = process.many(ctx, annotation.body)
  if bounds == none {
    return (x, y)
  }

  let (x-min, y-max, ..) = bounds.low
  y-max *= -1
  let (x-max, y-min, ..) = bounds.high
  y-min *= -1

  x-min -= annotation.padding.left
  x-max += annotation.padding.right
  y-min -= annotation.padding.bottom
  y-max += annotation.padding.top

  x.min = calc.min(x.min, x-min)
  x.max = calc.max(x.max, x-max)
  y.min = calc.min(y.min, y-min)
  y.max = calc.max(y.max, y-max)

  return (x, y)
}
