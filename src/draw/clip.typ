#import "/src/drawable.typ"
#import "/src/styles.typ"
#import "/src/wasm.typ": call_wasm
#import "/src/anchor.typ" as anchor_
#import "/src/draw/path-ops.typ" as path-ops

#let cetz-core = plugin("/cetz-core/cetz_core.wasm")

/// Clips one or more path drawables by a closed clip region.
///
/// `clipping-region` may contain multiple closed path drawables. `body` may
/// resolve to one or more path drawables, each of which may contain both open
/// and closed subpaths.
///
/// With `mode: "inside"`, each path drawable in `body` is clipped independently.
/// Its stroke and fill are handled separately:
/// + If its `stroke` is not `none`, the result retains only the portions of all
///   its subpaths inside `clipping-region`.
/// + If its `fill` is not `none`:
///   - Its closed subpaths define that drawable's filled area according to
///     `body-fill-rule`. A Boolean intersection between that area and
///     `clipping-region` produces its filled output, which is a newly generated
///     path with a fill but no stroke.
///   - Its open subpaths do not participate in this Boolean operation and
///     produce no filled output.
///
/// ```example
/// clip(
///   { circle((0, 0), radius: 1) },
///   {
///     circle(
///       (0.6, 0.2),
///       radius: 0.75,
///       fill: rgb("#b7e4c7"),
///       stroke: 1.5pt + green,
///     )
///     line((-1.5, 0), (1.5, 0), stroke: 2pt + blue)
///   },
///   mode: "inside",
/// )
/// ```
///
/// - clipping-region (elements, str): Closed paths defining the clipping region.
/// - body (elements, str): One or more path drawables to clip.
/// - mode (string): `"inside"` keeps the part inside the clipping region; `"outside"` keeps the outside.
/// - clip-fill-rule (auto, string): `"non-zero"` or `"even-odd"`, the fill rule applied to `clipping-region`.
/// - body-fill-rule (auto, string): `"non-zero"` or `"even-odd"`, the fill rule applied to filled closed body subpaths.
/// - eps (auto, float): Numerical accuracy. `auto` uses an automatically determined value.
/// - ignore-marks (bool): Drop marks from the inputs.
/// - ignore-hidden (bool): Drop hidden elements from the inputs.
/// - name (none, string):
#let clip(
  clipping-region,
  body,
  mode: "inside",
  clip-fill-rule: auto,
  body-fill-rule: auto,
  eps: auto,
  ignore-marks: true,
  ignore-hidden: true,
  name: none,
) = {
  assert(
    mode in ("inside", "outside"),
    message: "clip: invalid mode " + repr(mode) + ". Expected \"inside\" or \"outside\".",
  )

  path-ops.validate-fill-rule("clip-fill-rule", clip-fill-rule)
  path-ops.validate-fill-rule("body-fill-rule", body-fill-rule)

  return (
    ctx => {
      let clip-drawables = path-ops.collect-path-drawables(
        ctx,
        clipping-region,
        ignore-marks: ignore-marks,
        ignore-hidden: ignore-hidden,
      )
      let body-drawables = path-ops.collect-path-drawables(
        ctx,
        body,
        ignore-marks: ignore-marks,
        ignore-hidden: ignore-hidden,
      )

      assert(
        body-drawables.len() > 0,
        message: "clip: body must resolve to at least one path drawable; got 0",
      )

      let clipping-region3d = clip-drawables.map(d => d.segments).join(default: ())
      let clip-wire-info = path-ops.path3d-to-wire2d(
        clipping-region3d,
        require-closed: true,
      )

      let base-style = styles.resolve(ctx.style)
      let resolved-clip-fill-rule = path-ops.infer-fill-rule(
        clip-fill-rule,
        clip-drawables.map(d => d.fill-rule),
        base-style.fill-rule,
      )

      let body-items = ()
      let batch-bodies = ()
      let any-output = false
      for body-drawable in body-drawables {
        let body-wire-info = path-ops.path3d-to-wire2d(
          body-drawable.segments,
        )

        path-ops.assert-same-plane(clip-wire-info.z, body-wire-info.z)

        let resolved-body-fill-rule = if body-fill-rule == auto {
          body-drawable.fill-rule
        } else {
          body-fill-rule
        }
        let need-area = body-drawable.fill != none
        let need-line = body-drawable.stroke != none
        any-output = any-output or need-area or need-line

        body-items.push((
          drawable: body-drawable,
          z: body-wire-info.z,
        ))
        batch-bodies.push((
          body: body-wire-info.wire,
          body_fill_rule: resolved-body-fill-rule,
          need_line: need-line,
          need_area: need-area,
        ))
      }

      if not any-output {
        return path-ops.empty-result(ctx, name)
      }

      let result = call_wasm(cetz-core.clip_path_batch_func, (
        clip_region: clip-wire-info.wire,
        bodies: batch-bodies,
        mode: mode,
        clip_fill_rule: resolved-clip-fill-rule,
        eps: if eps == auto { none } else { eps },
      ))
      assert(
        result.outputs.len() == body-items.len(),
        message: "clip: wasm returned " + repr(result.outputs.len()) + " outputs for " + repr(body-items.len()) + " inputs",
      )

      let drawables = ()
      for (idx, output) in result.outputs.enumerate() {
        let item = body-items.at(idx)
        let body-drawable = item.drawable
        let z0 = item.z

        if output.area_path != none {
          let path3d = path-ops.wire2d-to-path3d(output.area_path, z0)
          if path3d.len() > 0 {
            let d = drawable.path(
              fill: body-drawable.fill,
              fill-rule: body-drawable.fill-rule,
              stroke: none,
              tags: body-drawable.at("tags", default: ()),
              path3d,
            )
            drawables.push(d)
          }
        }

        if output.line_path != none {
          let path3d = path-ops.wire2d-to-path3d(output.line_path, z0)
          if path3d.len() > 0 {
            let d = drawable.path(
              fill: none,
              fill-rule: body-drawable.fill-rule,
              stroke: body-drawable.stroke,
              tags: body-drawable.at("tags", default: ()),
              path3d,
            )
            drawables.push(d)
          }
        }
      }

      if drawables.len() == 0 {
        return path-ops.empty-result(ctx, name)
      }

      let anchor-path = drawables.last()
      let (_, anchors) = anchor_.setup(
        auto,
        (),
        name: name,
        transform: none,
        path-anchors: true,
        path: anchor-path,
      )

      return (
        ctx: ctx,
        name: name,
        anchors: anchors,
        drawables: drawables,
      )
    },
  )
}
