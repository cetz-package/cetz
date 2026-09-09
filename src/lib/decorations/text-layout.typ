// Helpers for text-along placement.
#import "/src/util.typ"

#let _sequence = [].func()
#let _styled = text(red)[].func()
#let _space = [ ].func()
#let _wrappers = (strong, emph, underline, overline, strike, smallcaps, sub, super)

// Split transparent wrappers only. Opaque content stays whole.
#let tokenize(body) = {
  if type(body) == array { return body.map(c => [#c]) }
  if type(body) == str { return body.clusters().map(c => [#c]) }
  assert(type(body) == content,
    message: "decorations.text-along: body must be text, content, or an array of chunks")
  let func = body.func()
  if func == _sequence { return body.children.map(tokenize).flatten() }
  if func == _styled {
    return tokenize(body.child).map(c => func(c, body.styles))
  }
  if func == text { return tokenize(body.text) }
  if func in _wrappers {
    let fields = body.fields()
    let children = tokenize(fields.remove("body"))
    return children.map(c => func(c, ..fields))
  }
  if func in (linebreak, parbreak) { return ([ ],) }
  (body,)
}

#let is-space(body) = {
  let func = body.func()
  if func == _space { return true }
  if func == text { return body.text.contains(regex("^\\s+$")) }
  if func == _styled { return is-space(body.child) }
  if func == _sequence { return body.children != () and body.children.all(is-space) }
  if func in _wrappers {
    return is-space(body.body)
  }
  false
}

#let is-text-cluster(body) = {
  let func = body.func()
  if func == text { return body.text.clusters().len() == 1 }
  if func == _styled { return is-text-cluster(body.child) }
  if func == _sequence {
    return body.children.len() == 1 and is-text-cluster(body.children.first())
  }
  if func in _wrappers { return is-text-cluster(body.body) }
  false
}

#let measure-advances(
  ctx, clusters, kerning: true, kernable: none, tracking: 0, padding: (:),
) = {
  let padding = (top: 0, right: 0, bottom: 0, left: 0) + padding
  if kernable == none { kernable = (true,) * clusters.len() }
  // Zero-width boxes stop Typst from trimming edge whitespace.
  let width(c) = util.measure(ctx, box(width: 0pt) + c + box(width: 0pt)).first()
  let content-widths = clusters.map(width)
  let widths = content-widths.map(w => w + padding.left + padding.right)
  // Match draw.content with anchor "base".
  let vertical(c) = {
    let cap = util.measure(ctx, text(top-edge: "cap-height", bottom-edge: "baseline",
      [#show linebreak: [ ]; #c])).at(1)
    let bounds = util.measure(ctx, text(top-edge: "cap-height", bottom-edge: "bounds",
      [#show linebreak: [ ]; #c])).at(1)
    (above: calc.abs(cap) + padding.top,
      below: calc.abs(bounds - cap) + padding.bottom)
  }
  let verticals = clusters.map(vertical)
  let advances = widths.enumerate().map(((i, w)) => {
    if i == widths.len() - 1 { return w }
    let advance = if kerning and kernable.at(i) and kernable.at(i + 1) {
      let pair-width = width(clusters.at(i) + clusters.at(i + 1))
      pair-width - content-widths.at(i + 1) + padding.left + padding.right
    } else { content-widths.at(i) + padding.left + padding.right }
    advance += tracking
    assert(advance >= 0, message: "decorations.text-along: tracking produces a negative advance")
    advance
  })
  (widths: widths, advances: advances,
    above: verticals.map(v => v.above), below: verticals.map(v => v.below))
}

#let resolve-bound(ctx, value, length) = {
  let value = if type(value) == ratio { length * value / 100% }
    else { util.resolve-number(ctx, value) }
  assert(type(value) in (int, float) and calc.abs(value) < calc.inf,
    message: "decorations.text-along: expected a finite distance")
  value
}

#let resolve-distance(ctx, value) = {
  let value = util.resolve-number(ctx, value)
  assert(type(value) in (int, float) and calc.abs(value) < calc.inf,
    message: "decorations.text-along: expected a finite number or length")
  value
}

#let align-factor(value) = {
  if type(value) == alignment {
    value = value.x
  }
  if value in (left, start) { return 0 }
  if value == center { return .5 }
  if value in (right, end) { return 1 }
  if type(value) == ratio and value >= 0% and value <= 100% { return value / 100% }
  panic("decorations.text-along: align must be a horizontal alignment or a ratio from 0% to 100%")
}

// distances are chunk centers. advances are origin steps.
// fit only widens gaps.
#let layout-distances(advances, widths, available, spacing: "natural", align: left, spaces: ()) = {
  let count = advances.len()
  if count == 0 { return () }
  if spacing == "equidistant" and count > 1 {
    return range(count).map(i => (i + .5) * available / count)
  }
  let eligible = range(count - 1).filter(i => spacing == "fit" or
    (spacing == "fit-spaces" and spaces.at(i)))
  let slack = calc.max(0, available - advances.sum())
  if eligible != () {
    for i in eligible { advances.at(i) += slack / eligible.len() }
  }
  let cursor = (available - advances.sum()) * align-factor(align)
  let distances = ()
  for (i, advance) in advances.enumerate() {
    distances.push(cursor + widths.at(i) / 2)
    cursor += advance
  }
  distances
}

// Keep chunks clear of offset joins. one turn of angle A shifts the
// parallel baseline by raise * tan(A / 2) at the vertex.
// "pad" moves chunks in blocks into the nearest open run.
#let apply-corners(
  distances, widths, corners, available,
  raise: 0, above: (), below: (), policy: "pad",
) = {
  if policy == "ignore" { return distances }
  if above == () { above = (0,) * distances.len() }
  if below == () { below = (0,) * distances.len() }
  // Corners use path coordinates. Drop joins outside [0, available].
  // Overflow handles those in apply-overflow.
  let corners = corners
    .filter(c => c.s >= 0 and c.s <= available)
    .sorted(key: c => c.s)
  if corners == () { return distances }
  let miter(corner, i) = if corner.angle == 180deg { 0 } else {
      let inward = corner.side * raise + if corner.side >= 0 { above.at(i) } else { below.at(i) }
      calc.max(0, inward * calc.tan(corner.angle / 2))
    }
  let skip = () => {
    distances.enumerate().map(((i, mid)) => {
      let blocked = corners.any(corner => {
        calc.abs(mid - corner.s) < widths.at(i) / 2 + miter(corner, i)
      })
      if blocked { none } else { mid }
    })
  }
  if policy == "skip" { return skip() }

  let solve(constrain-ends) = {
    let bounds(run, i) = {
      let half = widths.at(i) / 2
      let lower = if run > 0 {
        let corner = corners.at(run - 1)
        corner.s + half + miter(corner, i) - distances.at(i)
      } else if constrain-ends { half - distances.at(i) } else { -calc.inf }
      let upper = if run < corners.len() {
        let corner = corners.at(run)
        corner.s - half - miter(corner, i) - distances.at(i)
      } else if constrain-ends { available - half - distances.at(i) } else { calc.inf }
      (lower, upper)
    }

    // Sweep back to find the rightmost run each chunk can use.
    // This caps the forward pass so later chunks still fit.
    let ceilings = (none,) * distances.len()
    let next = corners.len()
    for i in range(distances.len()).rev() {
      let feasible = none
      for run in range(next + 1).rev() {
        let (lower, upper) = bounds(run, i)
        if lower <= upper {
          feasible = run
          break
        }
      }
      if feasible == none { return none }
      ceilings.at(i) = feasible
      next = feasible
    }

    // Assign each chunk to the nearest run at or before its ceiling.
    let assignments = ()
    let previous = 0
    let home = 0
    for (i, mid) in distances.enumerate() {
      // Corners and chunks are sorted, so track the home run directly.
      while home < corners.len() and corners.at(home).s <= mid { home += 1 }
      let best = none
      for run in range(previous, ceilings.at(i) + 1) {
        let (lower, upper) = bounds(run, i)
        if lower > upper { continue }
        let shift = calc.clamp(0, lower, upper)
        let candidate = (run: run, lower: lower, upper: upper,
          cost: calc.abs(shift), home-distance: calc.abs(run - home))
        if best == none or (candidate.cost < best.cost or
            (candidate.cost == best.cost and candidate.home-distance < best.home-distance) or
            (candidate.cost == best.cost and candidate.home-distance == best.home-distance and
              candidate.run > best.run)) {
          best = candidate
        }
        // Zero shift fits already. Stop here in the common case.
        if candidate.cost == 0 { break }
      }
      if best == none { return none }
      assignments.push(best)
      previous = best.run
    }

    // Merge neighbours in one run into rigid blocks.
    // Split a run when one block cannot hold all its chunks.
    let block-bounds(run, first, stop) = {
      let lower = -calc.inf
      let upper = calc.inf
      for i in range(first, stop) {
        let (candidate-lower, candidate-upper) = bounds(run, i)
        lower = calc.max(lower, candidate-lower)
        upper = calc.min(upper, candidate-upper)
      }
      (lower, upper)
    }

    let result = ()
    let first = 0
    let previous-shift = none
    let previous-run = 0
    while first < distances.len() {
      let assigned-run = assignments.at(first).run
      // Start with the run from the assignment pass.
      let run = assigned-run
      let stop = first + 1
      let (lower, upper) = block-bounds(run, first, stop)
      while stop < distances.len() and assignments.at(stop).run == assigned-run {
        let (next-lower, next-upper) = bounds(run, stop)
        let candidate-lower = calc.max(lower, next-lower)
        let candidate-upper = calc.min(upper, next-upper)
        if candidate-lower > candidate-upper { break }
        (lower, upper) = (candidate-lower, candidate-upper)
        stop += 1
      }
      let shift = calc.clamp(0, lower, upper)

      // A block must not move back past the previous block.
      // Promote it to the next open run instead.
      if previous-shift != none and shift < previous-shift {
        let required = previous-shift
        let promoted = none
        let candidate-start = calc.max(run + 1, previous-run)
        for candidate-run in range(candidate-start, corners.len() + 1) {
          let (candidate-lower, candidate-upper) = block-bounds(candidate-run, first, stop)
          if candidate-lower <= candidate-upper and candidate-upper >= required {
            let candidate-shift = calc.max(required,
              calc.clamp(0, candidate-lower, candidate-upper))
            promoted = (run: candidate-run, lower: candidate-lower,
              upper: candidate-upper, shift: candidate-shift)
            break
          }
        }
        if promoted != none {
          (run, lower, upper, shift) = (promoted.run, promoted.lower,
            promoted.upper, promoted.shift)
        } else {
          // No open run keeps order. Fall back to skip in the caller.
          return none
        }
      }
      result += distances.slice(first, stop).map(mid => mid + shift)
      previous-shift = shift
      previous-run = run
      first = stop
    }
    result
  }
  let result = solve(true)
  if result == none { result = solve(false) }
  if result == none { skip() } else { result }
}

// Apply overflow last. It bounds all spacing and corner modes.
#let apply-overflow(distances, widths, available, policy: "hide") = {
  distances.enumerate().map(((i, mid)) => {
    if mid == none { return none }
    let half = widths.at(i) / 2
    let fits = mid - half >= -1e-9 and mid + half <= available + 1e-9
    if policy == "error" {
      assert(fits, message: "decorations.text-along: text exceeds the available path interval")
    } else if not fits {
      if policy == "hide" or 2 * half > available { return none }
      return calc.clamp(mid, half, available - half)
    }
    mid
  })
}
