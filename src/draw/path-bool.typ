#import "/src/drawable.typ"
#import "/src/path-util.typ"
#import "/src/process.typ"
#import "/src/styles.typ"
#import "/src/wasm.typ": call_wasm
#import "/src/anchor.typ" as anchor_

#let cetz-core = plugin("/cetz-core/cetz_core.wasm")

// Runs a CeTZ body through `process.element`, filters marks/hidden drawables,
// and collects every path drawable's subpaths into a flat 3D path (an array
// of `(origin, closed, segments)` triples) plus the fill-rules observed across
// those drawables.
#let _collect-path3d(ctx, body, ignore-marks: true, ignore-hidden: true) = {
  let subpaths = ()
  let fill-rules = ()
  for element in body {
    let r = process.element(ctx, element)
    if r != none {
      ctx = r.ctx
      let tags = (drawable.TAG.debug,)
      if ignore-hidden { tags.push(drawable.TAG.hidden) }
      if ignore-marks { tags.push(drawable.TAG.mark) }

      let drawables = drawable.filter-tagged(r.drawables, ..tags)
      let path-drawables = drawables.filter(d => d.type == "path")
      subpaths += path-drawables.map(d => d.segments).join()
      fill-rules += path-drawables.map(d => d.fill-rule)
    }
  }
  return (ctx, subpaths, fill-rules)
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

  let z0 = path3d.first().at(0).at(2)
  let z-mismatch = false

  let drop-z(v) = (v.at(0), v.at(1))
  let check-z(v) = {
    if calc.abs(v.at(2) - z0) > tol { z-mismatch = true }
  }

  let wire-subpaths = ()
  for (origin, closed, segments) in path3d {
    assert(closed, message: "path-bool: every input subpath must be closed; got an open subpath")
    check-z(origin)

    let wire-segments = segments.map(seg => {
      let (kind, ..args) = seg
      if kind == "l" {
        let to = args.at(0)
        check-z(to)
        (kind: "l", to: drop-z(to))
      } else if kind == "c" {
        let (c1, c2, to) = args
        check-z(c1)
        check-z(c2)
        check-z(to)
        (kind: "c", c1: drop-z(c1), c2: drop-z(c2), to: drop-z(to))
      } else {
        panic("path-bool: unsupported path segment kind " + repr(kind))
      }
    })

    wire-subpaths.push((
      origin: drop-z(origin),
      closed: closed,
      segments: wire-segments,
    ))
  }

  assert(not z-mismatch, message: "path-bool: all input vertices must lie in a single z-plane.")

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
        panic("path-bool: unexpected wire segment kind " + repr(seg.kind))
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
/// path-bool(
///   { rect((-1, -1), (1, 1)) },
///   { circle((0, 0), radius: 0.8) },
///   op: "difference",
///   fill: blue,
/// )
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
/// `path-bool`'s own resolved style.
///
/// - a (elements): First operand body.
/// - b (elements): Second operand body.
/// - op (string): One of `"union"`, `"intersection"`, `"difference"`, `"xor"`.
/// - fill-rule-a (auto, string): `"non-zero"` or `"even-odd"`, applied to `a`. If `auto`, inferred from `a`'s drawables
/// - fill-rule-b (auto, string): `"non-zero"` or `"even-odd"`, applied to `b`. If `auto`, inferred from `b`'s drawables
/// - eps (auto, float): Numerical accuracy. `auto` uses an automatically determined value.
/// - ignore-marks (bool): Drop marks from the inputs.
/// - ignore-hidden (bool): Drop hidden elements from the inputs.
/// - name (none, string):
/// - ..style (style):
#let path-bool(
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
  assert.eq(
    style.pos(),
    (),
    message: "path-bool: unexpected positional arguments: " + repr(style.pos()),
  )
  let style = style.named()

  assert(
    op in ("union", "intersection", "difference", "xor"),
    message: "path-bool: invalid op "
      + repr(op)
      + ". Expected one of: \"union\", \"intersection\", \"difference\", \"xor\"",
  )

  let validate-fill-rule(name, value) = {
    assert(
      value == auto or value in ("non-zero", "even-odd"),
      message: "path-bool: invalid " + name + " " + repr(value) + ". Expected `auto`, \"non-zero\", or \"even-odd\".",
    )
  }
  validate-fill-rule("fill-rule-a", fill-rule-a)
  validate-fill-rule("fill-rule-b", fill-rule-b)

  return (
    ctx => {
      let (_, a-path3d, a-fill-rules) = _collect-path3d(
        ctx,
        a,
        ignore-marks: ignore-marks,
        ignore-hidden: ignore-hidden,
      )
      let (_, b-path3d, b-fill-rules) = _collect-path3d(
        ctx,
        b,
        ignore-marks: ignore-marks,
        ignore-hidden: ignore-hidden,
      )

      let (a-wire, az) = _path3d-to-wire2d(a-path3d)
      let (b-wire, bz) = _path3d-to-wire2d(b-path3d)

      assert(
        calc.abs(az - bz) < 1e-6,
        message: "path-bool: input paths must lie in the same z-plane; got z=" + repr(az) + " and z=" + repr(bz),
      )

      let resolved-style = styles.resolve(ctx.style, merge: style, root: "path-bool")
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
              panic("path-bool: result is empty; no anchor `" + repr(anchor) + "` available")
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
