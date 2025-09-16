#import "/src/anchor.typ" as anchor_
#import "/src/drawable.typ"
#import "/src/matrix.typ" as matrix_
#import "/src/vector.typ"
#import "/src/process.typ"
#import "/src/util.typ"

#let matrix(..cells, columns: auto, name: none, anchor: none) = {
  let cells = cells.pos()
  if columns == auto {
    columns = cells.len()
  } else {
    columns = calc.max(1, calc.min(cells.len(), columns))
  }
  let rows = calc.max(1, calc.ceil(cells.len() / columns))

  (ctx => {
    let cell-info = ()
    let cell-nodes = ()
    let cell-padding = ()
    let column-width = (0,) * columns
    let row-height = (0,) * rows

    let grid-ctx = ctx
    grid-ctx.transform = matrix_.ident(4)

    for (i, cell) in cells.enumerate() {
      let current-column = calc.rem(i, columns)
      let current-row = calc.floor(i / columns)

      if cell == none {
        cell-info.push(((0, 0, 0), (0, 0, 0)))
        cell-nodes.push(())
        continue
      }

      let (ctx: cell-ctx, elements, drawables, bounds) = process.many(grid-ctx, util.resolve-body(grid-ctx, cell))
      cell-info.push((bounds.low, bounds.high))
      cell-nodes.push(elements)

      let (x, y, z) = vector.sub(bounds.high, bounds.low)

      column-width.at(current-column) = calc.max(column-width.at(current-column), x)
      row-height.at(current-row) = calc.max(row-height.at(current-row), y)
    }

    let drawables = ()

    for i in range(0, cells.len()) {
      let column = calc.rem(i, columns)
      let row = calc.floor(i / columns)

      let (p0, p1) = cell-info.at(i)
      // Get the cell center
      let (cx, cy) = (
        column-width.slice(0, column).sum(default: 0) + column-width.at(column) / 2,
        row-height.slice(0, row).sum(default: 0) + row-height.at(row) / 2,
      )

      // Get the current cell size
      let offset = p0
      let size = vector.sub(p1, p0)

      // Compute the final offset
      let (x, y, z) = vector.add(offset, vector.scale(size, 0.5))

      // Compute the translation matrix
      let t = matrix_.transform-translate(cx - x, -cy - y, 0)
      t = matrix_.mul-mat(ctx.transform, t)

      // Render cell bounds
      if ctx.debug {
        let cw = column-width.at(column)
        let ch = row-height.at(row)
        let cell-border-pts = (
          (0 - cw / 2 + x, 0 - ch / 2 + y, 0.0),
          (0 + cw / 2 + x, 0 - ch / 2 + y, 0.0),
          (0 + cw / 2 + x, 0 + ch / 2 + y, 0.0),
          (0 - cw / 2 + x, 0 + ch / 2 + y, 0.0),
        )

        drawables.push(drawable.apply-transform(t, (drawable.line-strip(cell-border-pts,
          stroke: red, close: true, tags: ("debug",)))).first())
      }

      // Translate drawables & anchors
      let nodes = cell-nodes.at(i)
      for element in nodes {
        // Modify node drawables
        if "drawables" in element {
          element.drawables = drawable.apply-transform(t, element.drawables)
          drawables += element.drawables
        }

        // Modyfy anchors
        if "anchors" in element {
          let anchors = element.anchors
          element.anchors = (key => {
            if key != () {
              return matrix_.mul4x4-vec3(t, anchors(key))
            } else {
              return anchors(key)
            }
          })
        }

        if element.at("name", default: none) != none {
          ctx.nodes.insert(element.name, element)
        }
      }
    }

    let width = column-width.sum(default: 0)
    let height = row-height.sum(default: 0)

    let matrix-bounds = (
      (0, 0, 0),
      (width, 0, 0),
      (width, height, 0),
      (0, height, 0),
    )
    let matrix-border-path = drawable.line-strip(
      matrix-bounds, close: true)

    let (transform, anchors) = anchor_.setup(
      anchor => {
        (width / 2, height / 2, 0)
      },
      ("default", "center",),
      name: name,
      default: "default",
      offset-anchor: anchor,
      transform: matrix_.ident(4),
      path-anchors: true,
      border-anchors: true,
      radii: (width, -height),
      path: matrix-border-path,
      nested-anchors: true,
    )

    return (
      ctx: ctx,
      name: name,
      anchors: anchors,
      drawables: drawable.apply-transform(transform, drawables),
    )
  },)
}
