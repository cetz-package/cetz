#import "/src/draw.typ"
#import "/src/anchor.typ" as anchor_
#import "/src/styles.typ"
#import "mark.typ": draw-mark-shape
#import draw: group

#let default-style = (
  orientation: ttb,
  default-position: "north-east",
  layer: 1,        // Legend layer
  fill: rgb(255,255,255,200), // Legend background
  stroke: black,   // Legend border
  padding: .1,     // Legend border padding
  offset: (0, 0),  // Legend displacement
  spacing: .1,     // Spacing between anchor and legend
  item: (
    radius: 0,
    spacing: .05,  // Spacing between items
    preview: (
      width: .75,  // Preview width
      height: .3,  // Preview height
      margin: .1   // Distance between preview and label
    )
  ),
  radius: 0,
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

// Draw a generic item preview
#let draw-generic-preview(item) = {
  import draw: *

  if item.at("fill", default: false) {
    rect((0,0), (1,1), ..item.style)
  } else {
    line((0,.5), (1,.5), ..item.style)
  }
}

/// Construct a legend item for use with the `legend` function
///
/// - label (none, auto, content): Legend label or auto to use the enumerated default label
/// - preview (auto, function): Legend preview icon function of the format `item => elements`.
///                             Note that the canvas bounds for drawing the preview are (0,0) to (1,1).
/// - mark: (none,string): Legend mark symbol
/// - mark-style: (none,dictionary): Mark style
/// - mark-size: (number): Mark size
/// - style (styles): Style keys for the single item
#let item(label, preview, mark: none, mark-style: (:), mark-size: 1, ..style) = {
  assert.eq(style.pos().len(), 0,
    message: "Unexpected positional arguments")
  return ((label: label, preview: preview,
           mark: mark, mark-style: mark-style, mark-size: mark-size,
           style: style.named()),)
}

/// Draw a legend
#let legend(position, items, name: "legend", ..style) = group(name: name, ctx => {
  draw.anchor("default", ())
  let items = if items != none { items.filter(v => v.label != none) } else { () }
  if items == () {
    return
  }

  let style = styles.resolve(
    ctx.style, merge: style.named(), base: default-style, root: "legend")
  assert(style.orientation in (ttb, ltr),
    message: "Unsupported legend orientation.")

  // Position
  let position = if position == auto {
    style.default-position
  } else {
    position
  }

  // Adjust anchor
  if style.anchor == auto {
    style.anchor = if type(position) == str {
      auto-group-anchor.at(position, default: "north-west")
    } else {
      "north-west"
    }
  }

  // Apply offset
  if style.offset not in (none, (0,0)) {
    position = (rel: style.offset, to: position)
  }

  // Draw items
  draw.on-layer(style.layer, {
    draw.group(name: "items", padding: style.padding, ctx => {
      import draw: *

      set-origin(position)
      anchor("default", (0,0))

      let pt = (0, 0)
      for (i, item) in items.enumerate() {
        let (label, preview) = item
        if label == none {
          continue
        } else if label == auto {
          label = $ f_(#i) $
        }

        group({
          anchor("default", (0,0))

          let row-height = style.item.preview.height
          let preview-width = style.item.preview.width
          let preview-a = (0, -row-height / 2)
          let preview-b = (preview-width, +row-height / 2)
          let label-west = (preview-width + style.item.preview.margin, 0)

          // Draw item preview
          let draw-preview = if preview == auto { draw-generic-preview } else { preview }
          group({
            set-viewport(preview-a, preview-b, bounds: (1, 1, 0))
            (draw-preview)(item)
          })

          // Draw mark preview
          let mark = item.at("mark", default: none)
          if mark != none {
            draw-mark-shape((preview-a, 50%, preview-b),
              calc.min(style.item.preview.width / 2, item.mark-size),
              mark,
              item.mark-style)
          }

          // Draw label
          content(label-west,
            align(left + horizon, label),
            name: "label", anchor: "west")
        }, name: "item", anchor: if style.orientation == ltr { "west" } else { "north-west" })

        if style.orientation == ttb {
          set-origin((rel: (0, -style.item.spacing),
                      to: "item.south-west"))
        } else if style.orientation == ltr {
          set-origin((rel: (style.item.spacing, 0),
                      to: "item.east"))
        }
      }
    }, anchor: style.anchor)
  })

  // Fill legend background
  draw.on-layer(style.layer - .5, {
    draw.rect("items.south-west",
              "items.north-east", fill: style.fill, stroke: style.stroke, radius: style.radius)
  })
})
