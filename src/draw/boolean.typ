#import "/src/drawable.typ"
#import "/src/path-util.typ"
#import "/src/process.typ"
#import "/src/styles.typ"
#import "/src/wasm.typ": call_wasm
#import "/src/anchor.typ" as anchor_

#let cetz-core = plugin("/cetz-core/cetz_core.wasm")

// extract path subpaths and fill-rules from an array of resolved drawables
#let _extract-paths(drawables, ignore-marks: true, ignore-hidden: true) = {
  // exclude debug and content-frame drawables
  let tags = (drawable.TAG.debug, drawable.TAG.content-frame)
  if ignore-hidden { tags.push(drawable.TAG.hidden) }
  if ignore-marks { tags.push(drawable.TAG.mark) }

  let drawables = drawable.filter-tagged(drawables, ..tags)
  let path-drawables = drawables.filter(d => d.type == "path")
  let subpaths = path-drawables.map(d => d.segments).join(default: ())
  let fill-rules = path-drawables.map(d => d.fill-rule)
  return (subpaths, fill-rules)
}

// Resolves an operand into (subpaths, fill-rules). The operand can be:
//   - a string: the name of an existing element in `ctx.nodes`
//   - a CeTZ body
#let _collect-path3d(ctx, operand, ignore-marks: true, ignore-hidden: true) = {
  if type(operand) == str {
    assert(
      operand in ctx.nodes,
      message: "boolean: no element named " + repr(operand),
    )
    let element = ctx.nodes.at(operand)
    let raw = element.at("drawables", default: ())
    let (subpaths, fill-rules) = _extract-paths(
      raw,
      ignore-marks: ignore-marks,
      ignore-hidden: ignore-hidden,
    )
    return (subpaths, fill-rules)
  }

  let subpaths = ()
  let fill-rules = ()
  for element in operand {
    let r = process.element(ctx, element)
    if r != none {
      ctx = r.ctx
      let (extracted-subpaths, extracted-fill-rules) = _extract-paths(
        r.drawables,
        ignore-marks: ignore-marks,
        ignore-hidden: ignore-hidden,
      )
      subpaths += extracted-subpaths
      fill-rules += extracted-fill-rules
    }
  }
  return (subpaths, fill-rules)
}

// Picks a fill-rule for one operand:
// - If the user passed an explicit value (not `auto`), use it.
// - Else if every contributing path drawable agrees on a single fill-rule, inherit that one.
// - Else fall back to the style default.
#let _infer-fill-rule(arg, observed, default) = {
  if arg != auto {
    return arg
  }
  let unique = observed.dedup()
  if unique.len() == 1 {
    return unique.first()
  }
  return default
}

// Projects a CeTZ 3D path to a 2D wire path, asserting all vertices share the
// same z-plane (within `tol`) and all subpaths are closed.
#let _path3d-to-wire2d(path3d, tol: 1e-6) = {
  if path3d.len() == 0 {
    return ((subpaths: ()), 0.0)
  }

  let (z0, same-z) = path-util.same-z-plane(path3d, tol: tol)
  assert(same-z, message: "boolean: all input vertices must lie in a single z-plane.")

  let drop-z(v) = (v.at(0), v.at(1))

  let wire-subpaths = ()
  for (origin, closed, segments) in path3d {
    assert(closed, message: "boolean: every input subpath must be closed; got an open subpath")

    let wire-segments = segments.map(seg => {
      let (kind, ..args) = seg
      if kind == "l" {
        (kind: "l", to: drop-z(args.at(0)))
      } else if kind == "c" {
        let (c1, c2, to) = args
        (kind: "c", c1: drop-z(c1), c2: drop-z(c2), to: drop-z(to))
      } else {
        panic("boolean: unsupported path segment kind " + repr(kind))
      }
    })

    wire-subpaths.push((
      origin: drop-z(origin),
      closed: closed,
      segments: wire-segments,
    ))
  }

  return ((subpaths: wire-subpaths), z0)
}

// Injects z0 back into a 2D wire path to produce a CeTZ 3D path.
#let _wire2d-to-path3d(wire, z0) = {
  let inflate(v) = (v.at(0), v.at(1), z0)
  return wire.subpaths.map(sp => {
    let segments = sp.segments.map(seg => {
      if seg.kind == "l" {
        ("l", inflate(seg.to))
      } else if seg.kind == "c" {
        ("c", inflate(seg.c1), inflate(seg.c2), inflate(seg.to))
      } else {
        panic("boolean: unexpected wire segment kind " + repr(seg.kind))
      }
    })
    (inflate(sp.origin), sp.closed, segments)
  })
}

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

  let validate-fill-rule(name, value) = {
    assert(
      value == auto or value in ("non-zero", "even-odd"),
      message: "boolean: invalid " + name + " " + repr(value) + ". Expected `auto`, \"non-zero\", or \"even-odd\".",
    )
  }
  validate-fill-rule("fill-rule-a", fill-rule-a)
  validate-fill-rule("fill-rule-b", fill-rule-b)

  return (
    ctx => {
      let (a-path3d, a-fill-rules) = _collect-path3d(
        ctx,
        a,
        ignore-marks: ignore-marks,
        ignore-hidden: ignore-hidden,
      )
      let (b-path3d, b-fill-rules) = _collect-path3d(
        ctx,
        b,
        ignore-marks: ignore-marks,
        ignore-hidden: ignore-hidden,
      )

      let (a-wire, az) = _path3d-to-wire2d(a-path3d)
      let (b-wire, bz) = _path3d-to-wire2d(b-path3d)

      assert(
        calc.abs(az - bz) < 1e-6,
        message: "boolean: input paths must lie in the same z-plane; got z=" + repr(az) + " and z=" + repr(bz),
      )

      let resolved-style = styles.resolve(ctx.style, merge: style, root: "boolean")
      let resolved-fill-rule-a = _infer-fill-rule(fill-rule-a, a-fill-rules, resolved-style.fill-rule)
      let resolved-fill-rule-b = _infer-fill-rule(fill-rule-b, b-fill-rules, resolved-style.fill-rule)

      let result = call_wasm(cetz-core.path_bool_func, (
        a: a-wire,
        b: b-wire,
        op: op,
        fill_rule_a: resolved-fill-rule-a,
        fill_rule_b: resolved-fill-rule-b,
        eps: if eps == auto { none } else { eps },
      ))

      let path3d = _wire2d-to-path3d(result.path, az)

      // Empty result (e.g. difference of identical shapes): emit no drawables.
      if path3d.len() == 0 {
        return (
          ctx: ctx,
          name: name,
          anchors: anchor => {
            if anchor == () { () } else {
              panic("boolean: result is empty; no anchor `" + repr(anchor) + "` available")
            }
          },
          drawables: (),
        )
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
