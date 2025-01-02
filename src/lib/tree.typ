// CeTZ Library for Layouting Tree-Nodes
#import "/src/util.typ"
#import "/src/draw.typ"
#import "/src/coordinate.typ"
#import "/src/vector.typ"
#import "/src/matrix.typ"
#import "/src/process.typ"
#import "/src/anchor.typ" as anchor_

#let typst-content = content

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
#let default-draw-node(node, _) = {
  let text = if type(node) in (content, str, int, float) {
    [#node]
  } else if type(node) == dictionary {
    node.content
  }

  draw.get-ctx(ctx => {
    draw.content((), text)
  })
}

/// Lays out and renders tree nodes.
///
/// For each node, the `tree` function creates an anchor of the format `"node-<depth>-<child-index>"` that can be used to query a nodes position on the canvas.
///
/// ```typc example
/// import cetz.tree
/// set-style(content: (padding: .1))
/// tree.tree(([Root], ([A], [A.A], [A.B]), ([B], [B.A])))
/// ```
///
/// - root (array): A nested array of content that describes the structure the tree should take. Example: `([root], [child 1], ([child 2], [grandchild 1]))`
/// - draw-node (auto,function): The function to call to draw a node. The function will be passed two positional arguments, the node to draw and the node's parent, and is expected to return elements (`(node, parent-node) => elements`). The node's position is accessible through the "center" anchor or by using the previous position coordinate `()`. If `auto` is given, just the node's value will be drawn as content. The following predefined styles can be used:
/// - draw-edge (none,auto,function): The function to call draw an edge between two nodes. The function will be passed the name of the starting node, the name of the ending node, the start node, the end node, and is expected to return elements (`(source-name, target-name, parent-node, child-node) => elements`). If `auto` is given, a straight line will be drawn between nodes.
/// - direction (str): A string describing the direction the tree should grow in ("up", "down", "left", "right")
/// - parent-position (str): Positioning of parent nodes (begin, center, end)
/// - grow (float): Depth grow factor
/// - spread (float): Sibling spread factor
/// - name (none,str): The tree element's name
/// - node-layer (int): Layer to draw nodes on
/// - edge-layer (int): Layer to draw edges on
#let tree(
  root, 
  draw-node: auto,
  draw-edge: auto,
  direction: "down",
  parent-position: "center",
  grow: 1,
  spread: 1,
  name: none,
  node-layer: 1,
  edge-layer: 0
  ) = {
  assert(parent-position in ("begin", "center","end", "after-end"))
  assert(grow > 0)
  assert(spread > 0)

  direction = (
    up: "north",
    down: "south",
    right: "east",
    left: "west"
  ).at(direction)

  if draw-edge == auto {
    draw-edge = default-draw-edge
  } else if draw-edge == none {
    draw-edge = (..) => ()
  }

  if draw-node == auto {
    draw-node = default-draw-node
  }
  assert(draw-node != none, message: "Node draw callback must be set!")

  let build-node(tree, depth: 0, sibling: 0) = {
    let children = ()
    let content = none
    if type(tree) == array {
      children = tree.slice(1).enumerate().map(
        ((n, c)) => build-node(c, depth: depth + 1, sibling: n)
      )
      content = tree.at(0)
    } else {
      content = tree
    }
    
    return (
      x: 0,
      y: depth * grow,
      n: sibling,
      depth: depth,
      children: children,
      content: content
    )
  }

  // Layout node recursive
  //
  // return:
  //   (node, left-x, right-x)
  let layout-node(node, shift-x) = {
    if node.children.len() == 0 {
      node.x = shift-x
      return (node, node.x, node.x)
    } else {
      let (min-x, max-x) = (none, none)
      let (left, right) = (none, none)

      let n-children = node.children.len()
      for i in range(0, n-children) {
        let child = node.children.at(i)
        let (child-min-x, child-max-x) = (none, none)

        (child, child-min-x, child-max-x) = layout-node(child, shift-x)
        node.children.at(i) = child

        left = util.min(child.x, left)
        right = util.max(child.x, right)

        min-x = util.min(min-x, child-min-x)
        max-x = util.max(max-x, child-max-x)

        shift-x = child-max-x + spread
      }

      if parent-position == "begin" {
        node.x = left
      } else if parent-position == "center" {
          node.x = left + (right - left) / 2
      } else if parent-position == "end" {
          node.x = right
      } else { //after-end
          node.x = right+spread
          max-x = max-x + spread
      }

      node.direct-min-x = left
      node.direct-max-x = right
      node.min-x = min-x
      node.max-x = max-x

      return (node, min-x, max-x)
    }
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
    node.name = name
    node.group-name = "g" + name
    node.element = {
      draw.anchor(node.name, node-position(node))
      draw.group(name: node.group-name, {
        draw.move-to(node-position(node))
        draw.anchor("default", ())
        draw-node(node, parent-name)
      })
    }

    // Render children
    node.children = node.children.map(c => build-element(c, name))

    // Render edges
    node.edges = if node.children != () {
      draw.group({
        for child in node.children {
          draw-edge(node.group-name, child.group-name, node, child)
        }
      })
    } else { () }

    return node
  }

  let root = build-node(root)
  let (nodes, ..) = layout-node(root, 0)
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

  draw.group(name: name, render(node))
}
