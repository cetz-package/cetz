// CeTZ Library for Layouting Tree-Nodes
#import "/src/util.typ"
#import "/src/draw.typ"
#import "/src/coordinate.typ"
#import "/src/vector.typ"
#import "/src/matrix.typ"
#import "/src/process.typ"
#import "/src/anchor.typ" as anchor_
#import "/src/aabb.typ"
#import "/src/drawable.typ"
#import "/src/matrix.typ"

#let cetz-core = plugin("../../cetz-core/cetz_core.wasm")


// Default edge draw callback
//
// - from (string): Source element name
// - to (string): Target element name
// - parent (node): Parent (source) tree node
// - child (node): Child (target) tree node
#let default-draw-edge(from, to, parent, child) = {
  draw.line(from, to)
}

// Default node draw callback
//
// - node (node): The node to draw
#let default-draw-node(node) = {
  let text = if type(node) in (content, str, int, float) {
    [#node]
  } else if type(node) == dictionary {
    node.content
  }

  draw.content((0,0), text)
}


#let layout-node(node, grow, spread) = {
  let just-heights-and-weights(node) = {
    (
      height: float(node.height),
      width: float(node.width),
      children: node.children.map(x => just-heights-and-weights(x)),
    )
  }
  let encoded = cbor.encode((just-heights-and-weights(node), float(grow), float(spread)))
  let positions = cbor(cetz-core.layout_tree_func(encoded))

  let weave-together(node, positions) = {
    node.x = positions.x
    node.y = positions.y

    node.children = node.children.zip(positions.children).map(x => weave-together(x.first(), x.last()))
    return node
  }

  return weave-together(node, positions)
}

/// Lays out and renders tree nodes.
///
/// For each node, the `tree` function creates an anchor of the format `"[<child-index>-]<child-index>"` (the root is `"0"`, its first child `"0-0"`, second `"0-1"` and so on) that can be used to query a nodes position on the canvas.
///
/// ```typc example
/// import cetz.tree
/// set-style(content: (padding: .1))
/// tree.tree(([Root], ([A], [A.A], [A.B]), ([B], [B.A])))
/// ```
///
/// - root (array): A nested array of content that describes the structure the tree should take. Example: `([root], [child 1], ([child 2], [grandchild 1]))`
/// - draw-node (auto,function): The function to call to draw a node. The function will be passed the node to draw (a dictionary with a `content` key) and is expected to return elements (`(node, parent-node) => elements`). The node must be drawn at the `(0,0)` coordinate. If `auto` is given, just the node's value will be drawn as content. The following predefined styles can be used:
/// - draw-edge (none,auto,function): The function to call draw an edge between two nodes. The function will be passed the name of the starting node, the name of the ending node, the start node, the end node, and is expected to return elements (`(source-name, target-name, parent-node, child-node) => elements`). If `auto` is given, a straight line will be drawn between nodes.
/// - direction (str): A string describing the direction the tree should grow in ("up", "down", "left", "right")
/// - grow (float): Depth grow factor
/// - spread (float): Sibling spread factor
/// - name (none,str): The tree element's name
/// - node-layer (int): Layer to draw nodes on
/// - edge-layer (int): Layer to draw edges on
/// - anchor (none, string): Name of the anchor to align the tree to. Use the root node anchor (`"0"`) to align the tree to the root nodes position.
/// - node-name-prefix (string): Prefix added to node anchors (e.g. `"node-" → "node-0-0" for the root node`)
/// - node-group-name-prefix (string): Prefix added to node group names
#let tree(
  root,
  draw-node: auto,
  draw-edge: auto,
  direction: "down",
  grow: 1,
  spread: 1,
  name: none,
  node-layer: 1,
  edge-layer: 0,
  measure-content: true,
  anchor: none,
  node-name-prefix: "",
  node-group-name-prefix: "g",
) = {
  assert(grow >= 0)
  assert(spread >= 0)

  direction = (
    up: "north",
    down: "south",
    right: "east",
    left: "west",
  ).at(direction, default: "south")

  if draw-edge == auto {
    draw-edge = default-draw-edge
  } else if draw-edge == none {
    draw-edge = (..) => ()
  }

  if draw-node == auto {
    draw-node = default-draw-node
  }
  assert(draw-node != none, message: "Node draw callback must be set!")

  draw.get-ctx(ctx => {
    let build-node(tree, depth: 0, sibling: 0) = {
      let children = ()
      let content = none
      if type(tree) == array {
        children = tree.slice(1).enumerate().map(((n, c)) => build-node(c, depth: depth + 1, sibling: n))
        content = tree.at(0)
      } else {
        content = tree
      }

      let node = (
        height: 0.0,
        width: 0.0,
        n: sibling,
        depth: depth,
        children: children,
        content: content,
      )

      // Measure the node
      if measure-content {
        let (ctx: _, drawables: _, bounds) = process.many(ctx, {
          draw.set-origin((0, 0))
          (draw-node)(node)
        })

        if bounds != none {
          (node.width, node.height, _) = aabb.size(bounds)
        }
      }

      return node
    }


    let node-position(node) = {
      if direction == "south" {
        return (node.x, -node.y)
      } else if direction == "north" {
        return (node.x, node.y)
      } else if direction == "west" {
        return (-node.y, node.x)
      } else if direction == "east" {
        return (node.y, node.x)
      } else {
        panic(message: "Invalid tree direction.")
      }
    }

    let anchors(node, parent-path) = {
      if parent-path != none {
        parent-path += "-"
      } else {
        parent-path = ""
      }

      let d = (:)
      d.insert(parent-path + str(node.n), node-position(node))
      for child in node.children {
        d += anchors(child, parent-path + str(node.n))
      }
      return d
    }

    let build-element(node, parent-name) = {
      let name = if parent-name != none {
        parent-name + "-" + str(node.n)
      } else {
        "0"
      }

      // Render element
      node.name = node-name-prefix + name
      node.group-name = node-group-name-prefix + name
      node.element = {
        draw.anchor(node.name, node-position(node))
        draw.group(name: node.group-name, ctx => {
            let (x, y) = node-position(node)
            draw.translate((x, y, 0))
            draw.anchor("default", (0, 0))
            draw-node(node)
          },
        )
      }

      // Render children
      node.children = node.children.map(c => build-element(c, name))

      // Render edges
      node.edges = if node.children != () {
        draw.group({
          for child in node.children {
            draw-edge(node.name, child.name, node, child)
          }
        })
      } else { () }

      return node
    }

    let root = build-node(root)
    let nodes = layout-node(root, grow, spread)
    let node = build-element(nodes, none)

    // Render node recursive
    let render(node) = {
      if node.element != none {
        draw.on-layer(node-layer, node.element)
        if "children" in node {
          for child in node.children {
            render(child)
          }
        }
        draw.on-layer(edge-layer, node.edges)
      }
    }

    draw.group(name: name, anchor: anchor, {
      draw.anchor("default", (0,0))
      render(node)
    })
  })
}
