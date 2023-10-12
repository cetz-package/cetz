#import "/src/draw.typ"
#import "/src/anchor.typ" as anchor_
#import "/src/styles.typ"
#import "mark.typ": draw-mark-shape

#let default-style = (
  orientation: ttb,
  default-position: "legend.north-east",
  offset: (0,0),   // Legend displacement
  spacing: .1,     // Spacing between anchor and legend
  item: (
    spacing: .35,  // Spacing between items
    preview: (     // Style preview of an item
      width: .75,
      height: .2,
      margin: .1
    )
  ),
)

// Map position to legend group anchor
#let auto-group-anchor = (
  inner-north-west: "north-west",
  inner-north:      "north",
  inner-north-east: "north-east",
  inner-south-west: "south-west",
  inner-south:      "south",
  inner-south-east: "south-east",
  inner-west:       "west",
  inner-east:       "east",
  north-west:       "north-east",
  north:            "south",
  north-east:       "north-west",
  south-west:       "south-east",
  south:            "north",
  south-east:       "south-west",
  east:             "west",
  west:             "east",
)

// Generate legend positioning anchors
#let add-legend-anchors(style, element, size) = {
  import draw: *
  let (w,   h) = size
  let (xo, yo) = {
    let spacing = style.at("spacing", default: (0, 0))
    if type(spacing) == array {
      spacing
    } else {
      (spacing, spacing)
    }
  }

  anchor("north",            (rel: (w / 2,  yo), to: (element + ".north", "-|", element + ".origin")))
  anchor("south",            (rel: (w / 2, -yo), to: (element + ".south", "-|", element + ".origin")))
  anchor("east",             (rel: (xo,  h / 2), to: (element + ".east", "|-", element + ".origin")))
  anchor("west",             (rel: (-xo, h / 2), to: (element + ".west", "|-", element + ".origin")))
  anchor("north-east",       (rel: (xo,  h), to: (element + ".north-east", "|-", element + ".origin")))
  anchor("north-west",       (rel: (-xo, h), to: (element + ".north-west", "|-", element + ".origin")))
  anchor("south-east",       (rel: (xo,  0), to: (element + ".south-east", "|-", element + ".origin")))
  anchor("south-west",       (rel: (-xo, 0), to: (element + ".south-west", "|-", element + ".origin")))
  anchor("inner-north",      (rel: (w / 2,  h - yo), to: element + ".origin"))
  anchor("inner-north-east", (rel: (w - xo, h - yo), to: element + ".origin"))
  anchor("inner-north-west", (rel: (yo,     h - yo), to: element + ".origin"))
  anchor("inner-south",      (rel: (w / 2,  yo), to: element + ".origin"))
  anchor("inner-south-east", (rel: (w - xo, yo), to: element + ".origin"))
  anchor("inner-south-west", (rel: (xo,     yo), to: element + ".origin"))
  anchor("inner-east",       (rel: (w - xo, h / 2), to: element + ".origin"))
  anchor("inner-west",       (rel: (xo,     h / 2), to: element + ".origin"))
}

// Draw a legend box at position relative to anchor of plot-element
#let draw-legend(ctx, style, items, size, plot, position, anchor) = {
  let style = styles.resolve(
    ctx.style, style, base: default-style, root: "legend")

  if position == auto {
    position = style.default-position
  }

  // Create legend anchors
  draw.group(name: "legend", {
    add-legend-anchors(style, plot, size)
  })

  // Try finding an optimal legend anchor
  let anchor = if type(position) == str and anchor == auto {
    auto-group-anchor.at(position.replace("legend.", ""), default: "north-west")
  } else {
    anchor
  }

  // Apply offset
  if style.offset not in (none, (0,0)) {
    position = (rel: style.offset, to: position)
  }

  draw.group(name: "legend", ctx => {
    import draw: *

    set-origin(position)
    anchor("center", (0,0))

    let pt = (0, 0)
    for (i, item) in items.enumerate() {
      if item.label == none { continue }
      let label = if item.label == auto {
        $ f_(#i) $
      } else { item.label }

      group({
        anchor("center", (0,0))

        // Draw item label
        content((0, 0), label, name: "label", anchor: "north-west")

        // Draw line preview
        let (a, b) = ((rel: (-style.item.preview.width -
                              style.item.preview.margin, 0), to: "label.west"),
                      (rel: (-style.item.preview.margin, 0), to: "label.west"))
        if (item.at("fill", default: false) or
            item.at("hypograph", default: false) or
            item.at("epigraph", default: false)) {
          rect((rel: (0,-style.item.preview.height / 2), to: a),
               (rel: (0,+style.item.preview.height / 2), to: b), ..item.style)
        } else {
          line(a, b, ..item.style)
        }

        // Draw mark preview
        let mark = item.at("mark", default: none)
        if mark != none {
          draw-mark-shape((a, .5, b),
            calc.min(style.item.preview.width / 2, item.mark-size),
            mark,
            item.mark-style)
        }
      }, name: "item", anchor: "west")

      if style.orientation == ttb {
        set-origin((rel: (0, -style.item.spacing),
                    to: ((0, 0), "|-", "item.south")))
      } else if style.orientation == ltr {
        set-origin((rel: (style.item.spacing, 0),
                    to: ((0, 0), "-|", "item.east")))
      }
    }
  }, anchor: anchor)
}
