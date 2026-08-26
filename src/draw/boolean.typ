#import "/src/drawable.typ"
#import "/src/styles.typ"
#import "/src/wasm.typ": call_wasm
#import "/src/anchor.typ" as anchor_
#import "/src/draw/path-ops.typ" as path-ops

#let cetz-core = plugin("/cetz-core/cetz_core.wasm")

/// Performs a boolean operation on the paths produced by two CeTZ bodies.
/// The supported operations are `"union"`, `"intersection"`, `"difference"`,
/// and `"xor"`.
///
/// ```example
/// boolean(
///   { rect((-1, -1), (1, 0)) },
///   { circle((0, 0), radius: 0.8) },
///   op: "difference",
///   fill: blue,
/// )
/// ```
///
/// Each operand can either be one or more type:elements or the name of an already-defined element (a string).
///
/// ```example
/// rect((-1, -1), (1, 0), name: "r")
/// circle((0, 0), radius: 0.8, name: "c")
/// boolean("r", "c", op: "difference", fill: blue)
/// ```
///
/// All input subpaths must be closed and lie in a single z-plane. The output
/// is a single path drawable in the z-plane of the first input.
///
/// Each operand has its own fill-rule, which decides how its self-overlapping
/// or nested subpaths are interpreted as a filled region *before* the
/// boolean operation runs. By default (`auto`) the fill-rule is inferred
/// from the operand: if every path drawable produced by the body agrees on
/// one fill-rule (e.g. the body is a single `compound-path(..., fill-rule:
/// "even-odd")`), that value is used; otherwise it falls back to
/// `boolean`'s own resolved style.
///
/// - a (elements, str): First operand. Either an element body or the name
///   of an existing element.
/// - b (elements, str): Second operand. Either an element body or the name
///   of an elementxisting element.
/// - op (string): One of `"union"`, `"intersection"`, `"difference"`, `"xor"`.
/// - fill-rule-a (auto, string): `"non-zero"` or `"even-odd"`, applied to `a`. If `auto`, inferred from `a`'s drawables
/// - fill-rule-b (auto, string): `"non-zero"` or `"even-odd"`, applied to `b`. If `auto`, inferred from `b`'s drawables
/// - eps (auto, float): Numerical accuracy. `auto` uses an automatically determined value.
/// - ignore-marks (bool): Drop marks from the inputs (default: `true`).
/// - ignore-hidden (bool): Drop hidden elements from the inputs (default: `true`).
/// - name (none, string):
/// - ..style (style):
#let boolean(
  a,
  b,
  op: "difference",
  fill-rule-a: auto,
  fill-rule-b: auto,
  eps: auto,
  ignore-marks: true,
  ignore-hidden: true,
  name: none,
  ..style,
) = {
  let valid-op = ("union", "intersection", "difference", "xor")

  assert.eq(
    style.pos(),
    (),
    message: "boolean: unexpected positional arguments: " + repr(style.pos()),
  )
  let style = style.named()

  assert(
    op in valid-op,
    message: "boolean: invalid op "
      + repr(op)
      + ". Expected one of: " + valid-op.join(", "),
  )

  path-ops.validate-fill-rule("fill-rule-a", fill-rule-a)
  path-ops.validate-fill-rule("fill-rule-b", fill-rule-b)

  return (
    ctx => {
      let a-drawables = path-ops.collect-path-drawables(
        ctx,
        a,
        ignore-marks: ignore-marks,
        ignore-hidden: ignore-hidden,
      )
      let b-drawables = path-ops.collect-path-drawables(
        ctx,
        b,
        ignore-marks: ignore-marks,
        ignore-hidden: ignore-hidden,
      )

      let a-path3d = a-drawables.map(d => d.segments).join(default: ())
      let b-path3d = b-drawables.map(d => d.segments).join(default: ())
      let a-fill-rules = a-drawables.map(d => d.fill-rule)
      let b-fill-rules = b-drawables.map(d => d.fill-rule)

      let a-wire-info = path-ops.path3d-to-wire2d(
        a-path3d,
        require-closed: true,
      )
      let b-wire-info = path-ops.path3d-to-wire2d(
        b-path3d,
        require-closed: true,
      )
      path-ops.assert-same-plane(a-wire-info.z, b-wire-info.z)

      let resolved-style = styles.resolve(ctx.style, merge: style, root: "boolean")
      let resolved-fill-rule-a = path-ops.infer-fill-rule(fill-rule-a, a-fill-rules, resolved-style.fill-rule)
      let resolved-fill-rule-b = path-ops.infer-fill-rule(fill-rule-b, b-fill-rules, resolved-style.fill-rule)

      let result = call_wasm(cetz-core.path_bool_func, (
        a: a-wire-info.wire,
        b: b-wire-info.wire,
        op: op,
        fill_rule_a: resolved-fill-rule-a,
        fill_rule_b: resolved-fill-rule-b,
        eps: if eps == auto { none } else { eps },
      ))

      let output-z = if a-wire-info.z != none {
        a-wire-info.z
      } else if b-wire-info.z != none {
        b-wire-info.z
      } else {
        0.0
      }
      let path3d = path-ops.wire2d-to-path3d(result.path, output-z)

      // Empty result (e.g. difference of identical shapes): emit no drawables.
      if path3d.len() == 0 {
        return path-ops.empty-result(ctx, name)
      }

      let drawables = drawable.path(
        fill: resolved-style.fill,
        fill-rule: resolved-style.fill-rule,
        stroke: resolved-style.stroke,
        path3d,
      )

      let (_, anchors) = anchor_.setup(
        auto,
        (),
        name: name,
        transform: none,
        path-anchors: true,
        path: drawables,
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
