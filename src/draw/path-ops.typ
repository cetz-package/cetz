// Shared infrastructure for draw operations that consume CeTZ paths and pass
// a two-dimensional wire representation to cetz-core. This module owns the
// adaptation between drawables and the WASM wire protocol; generic path
// geometry remains in `/src/path-util.typ`.

#import "/src/drawable.typ"
#import "/src/path-util.typ"
#import "/src/process.typ"

/// Extracts path drawables from an array of resolved drawables.
///
/// Debug and content-frame drawables are always excluded. Marks and hidden
/// drawables are excluded by default, but callers may opt into either. The
/// relative order of the remaining path drawables is preserved.
///
/// - drawables (array): Resolved CeTZ drawables
/// - ignore-marks (bool): Whether to exclude mark drawables
/// - ignore-hidden (bool): Whether to exclude hidden drawables
/// -> array Path drawables that may be passed to a path operation
#let path-drawables(drawables, ignore-marks: true, ignore-hidden: true) = {
  let tags = (drawable.TAG.debug, drawable.TAG.content-frame)
  if ignore-hidden { tags.push(drawable.TAG.hidden) }
  if ignore-marks { tags.push(drawable.TAG.mark) }

  let drawables = drawable.filter-tagged(drawables, ..tags)
  return drawables.filter(d => d.type == "path")
}

/// Resolves an operand into path drawables.
///
/// An operand may be the name of an existing element in `ctx.nodes`, or a CeTZ
/// body. Elements in a body are processed sequentially so that each element
/// observes the context returned by the preceding element. Only the resolved
/// path drawables are returned; the operand's context changes remain scoped to
/// operand evaluation, matching the original boolean and clip behavior.
///
/// - ctx (dictionary): Current CeTZ context
/// - operand (string, elements): Existing element name or CeTZ body
/// - ignore-marks (bool): Whether to exclude mark drawables
/// - ignore-hidden (bool): Whether to exclude hidden drawables
/// -> array Resolved and filtered path drawables
#let collect-path-drawables(
  ctx,
  operand,
  ignore-marks: true,
  ignore-hidden: true,
) = {
  if type(operand) == str {
    assert(
      operand in ctx.nodes,
      message: "no element named " + repr(operand),
    )
    let element = ctx.nodes.at(operand)
    return path-drawables(
      element.at("drawables", default: ()),
      ignore-marks: ignore-marks,
      ignore-hidden: ignore-hidden,
    )
  }

  let paths = ()
  for element in operand {
    let r = process.element(ctx, element)
    if r != none {
      ctx = r.ctx
      paths += path-drawables(
        r.drawables,
        ignore-marks: ignore-marks,
        ignore-hidden: ignore-hidden,
      )
    }
  }
  return paths
}

/// Validates a fill-rule argument accepted by a path operation.
///
/// - name (string): Argument name used in the assertion message
/// - value (auto, string): `auto`, `"non-zero"`, or `"even-odd"`
#let validate-fill-rule(name, value) = {
  assert(
    value == auto or value in ("non-zero", "even-odd"),
    message: "invalid " + name + " " + repr(value) + ". Expected `auto`, \"non-zero\", or \"even-odd\".",
  )
}

/// Picks a fill rule for one operand.
///
/// + If the user passed an explicit value (not `auto`), use it.
/// + Else if every contributing path drawable agrees on a single fill-rule, inherit that one.
/// + Else fall back to the style default.
///
/// - arg (auto, string): User-provided fill-rule argument
/// - observed (array): Fill rules of the contributing path drawables
/// - fallback (string): Fill rule used when inference is inconclusive
/// -> string Resolved fill rule
#let infer-fill-rule(arg, observed, fallback) = {
  if arg != auto {
    return arg
  }
  let unique = observed.dedup()
  if unique.len() == 1 {
    return unique.first()
  }
  return fallback
}

/// Projects a CeTZ 3D path to the 2D wire representation used by cetz-core.
///
/// All vertices must lie in one z-plane within `tol`. When `require-closed` is
/// true, every subpath must also be closed. The z-coordinate is removed from
/// origins, line endpoints, and cubic control points, while segment order and
/// closed flags are preserved.
///
/// - path3d (path): CeTZ path containing three-dimensional vertices
/// - require-closed (bool): Whether every subpath must be closed
/// - tol (float): Absolute z tolerance within the input path
/// -> dictionary Fields `wire` and `z`; `z` is `none` for an empty path
#let path3d-to-wire2d(
  path3d,
  require-closed: false,
  tol: 1e-6,
) = {
  if path3d.len() == 0 {
    return (wire: (subpaths: ()), z: none)
  }

  let (z0, same-z) = path-util.same-z-plane(path3d, eps: tol)
  assert(same-z, message: "all path vertices must lie in a single z-plane")

  let drop-z(v) = (v.at(0), v.at(1))
  let wire-subpaths = ()
  for (origin, closed, segments) in path3d {
    if require-closed {
      assert(
        closed,
        message: "all subpaths must be closed; got an open subpath",
      )
    }

    let wire-segments = segments.map(seg => {
      let (kind, ..args) = seg
      if kind == "l" {
        (kind: "l", to: drop-z(args.at(0)))
      } else if kind == "c" {
        let (c1, c2, to) = args
        (kind: "c", c1: drop-z(c1), c2: drop-z(c2), to: drop-z(to))
      } else {
        panic("unsupported CeTZ path segment kind " + repr(kind))
      }
    })

    wire-subpaths.push((
      origin: drop-z(origin),
      closed: closed,
      segments: wire-segments,
    ))
  }

  return (wire: (subpaths: wire-subpaths), z: z0)
}

/// Injects a z-coordinate into a cetz-core 2D wire path.
///
/// Origins, line endpoints, and cubic control points are inflated to CeTZ 3D
/// vertices. Segment order and closed flags are preserved.
///
/// - wire (dictionary): Two-dimensional cetz-core wire path
/// - z0 (none, float): Z-coordinate assigned to every output vertex; `none`
///   is only meaningful when `wire` is empty
/// -> path CeTZ path containing three-dimensional vertices
#let wire2d-to-path3d(wire, z0) = {
  let inflate(v) = (v.at(0), v.at(1), z0)
  return wire.subpaths.map(sp => {
    let segments = sp.segments.map(seg => {
      if seg.kind == "l" {
        ("l", inflate(seg.to))
      } else if seg.kind == "c" {
        ("c", inflate(seg.c1), inflate(seg.c2), inflate(seg.to))
      } else {
        panic("unexpected cetz-core wire segment kind " + repr(seg.kind))
      }
    })
    (inflate(sp.origin), sp.closed, segments)
  })
}

/// Asserts that two optional path-operation planes describe the same z-plane.
///
/// `none` represents an empty path, which has no z-plane and therefore cannot
/// conflict with the plane of a non-empty path. If both values are present,
/// their absolute difference must be less than `tol`.
///
/// - a-z (none, float): Z-coordinate of the first operand, or `none` if empty
/// - b-z (none, float): Z-coordinate of the second operand, or `none` if empty
/// - tol (float): Absolute z tolerance between the operands
#let assert-same-plane(a-z, b-z, tol: 1e-6) = {
  if a-z != none and b-z != none {
    assert(
      calc.abs(a-z - b-z) < tol,
      message: "path inputs must lie in the same z-plane; got z=" + repr(a-z) + " and z=" + repr(b-z),
    )
  }
}

/// Constructs the standard result returned by an empty draw operation.
///
/// The result emits no drawables. The empty anchor `()` remains available,
/// while requesting any named anchor reports that the named path result (or
/// generic path-operation result) is empty.
///
/// - ctx (dictionary): Current CeTZ context
/// - name (none, string): Element name to retain in the result
/// -> dictionary Empty CeTZ element-processing result
#let empty-result(ctx, name) = {
  let result-label = if name == none {
    "path operation result"
  } else {
    "path result " + repr(name)
  }
  return (
    ctx: ctx,
    name: name,
    anchors: anchor => {
      if anchor == () { () } else {
        panic(result-label + " is empty; no anchor `" + repr(anchor) + "` available")
      }
    },
    drawables: (),
  )
}
