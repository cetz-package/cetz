// CeTZ Library for Layouting Tree-Nodes
#import "../util.typ"
#import "../draw.typ"
#import "../coordinate.typ"
#import "../vector.typ"
#import "../matrix.typ"
#import "../process.typ"
#import "../anchor.typ" as anchor_

#let typst-content = content

/// Layout and render tree nodes
///
/// - root (array): Tree structure represented by nested lists
///                 Example: `([root], [child 1], ([child 2], [grandchild 1]))`
/// - draw-node (function): Callback for rendering a node.
///                         Signature: `(node) => elements`. The nodes position
///                         is accessible through the anchor `"center"` or the last
///                         position `()`.
/// - draw-edge (function): Callback for rendering edges between nodes
///                         Signature: `(source-name, target-name, target-node) => elements`
/// - direction (string): Tree grow direction (up, down, left, right)
/// - parent-position (string): Positioning of parent nodes (begin, center, end)
/// - grow (float): Depth grow factor (default 1)
/// - spread (float): Sibling spread factor (default 1)
#let tree(
  root, 
  draw-node: auto,
  draw-edge: auto,
  direction: "down",
  parent-position: "center",
  grow: 1,
  spread: 1,
  name: none,
  ..style
  ) = {
  assert(parent-position in ("begin", "center"))
  assert(grow > 0)
  assert(spread > 0)

  // if direction == "down" { direction = "south" }
  // if direction == "up" { direction = "north" }

  direction = (
    up: "north",
    down: "south",
    right: "east",
    left: "west"
  ).at(direction)

  let opposite-dir = (
    west: "east", 
    east: "west",
    south: "north",
    north: "south"
  )

  if draw-edge == auto {
    draw-edge = (source-name, target-name, target-node) => {
      let (a, b) = (
        source-name + "." + direction, 
        target-name + "." + opposite-dir.at(direction)
      )

      draw.line(a, b)
      /*
      if direction == "bottom" {
        draw.line(a, (rel: (0, -grow/3)), ((), "-|", b), b)
      } else if direction == "up" {
        draw.line(a, (rel: (0, grow/3)), ((), "-|", b), b)
      } else if direction == "left" {
        draw.line(a, (rel: (-grow/3, 0)), ((), "|-", b), b)
      } else if direction == "right" {
        draw.line(a, (rel: (grow/3, 0)), ((), "|-", b), b)
      }
      */
    }
  } else if draw-edge == none {
    draw-edge = (..) => {}
  }

  if draw-node == auto or draw-node in ("rect",) {
    draw-node = (node, parent-name) => {
      let content = node.content
      if type(content) == str {
        content = [#content]
      } else if type(content) in (float, int) {
        content = $#content$
      } else if type(content) == dictionary and "content" in content {
        content = content.content
      } else if type(content) != typst-content {
        panic("Unsupported content type " + type(content) + "! "+ "Provide your own `draw-node` implementation.")
      }

      if content != none {
        draw.content((), content, name: "content")
      } else {
        draw.content((), [?], name: "content")
      }
      if draw-node == "rect" {
        draw.rect(
          (rel: (-.1, .1), to: "content.top-left"),
          (rel: (.1, -.1), to: "content.bottom-right")
        )
      }
    }
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
  //   (node, left-x, right-x, shift-x)
  let layout-node(node, shift-x, ctx) = {
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

        (child, child-min-x, child-max-x) = layout-node(child, shift-x, ctx)
        node.children.at(i) = child

        left = util.min(child.x, left)
        right = util.max(child.x, right)

        min-x = util.min(min-x, child-min-x)
        max-x = util.max(max-x, child-max-x)

        if child-max-x > right {
          shift-x = child-max-x
        }
        shift-x += spread
      }

      if parent-position == "begin" {
        node.x = left
      } else {
        node.x = left + (right - left) / 2
      }

      node.direct-min-x = left
      node.direct-max-x = right
      node.min-x = min-x
      node.max-x = max-x

      return (node, min-x, max-x)
    }
  }

  let layout(node, ctx) = {
    let (n, ..) = layout-node(node, 0, ctx)
    return n
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

  let render(node, parent-name) = {
    let name = "node-" + str(node.depth) + "-" + str(node.n)

    let cmds = ()
    cmds += draw.group(name: name, {
      draw.move-to(node-position(node))
      draw.anchor("center", ())
      draw-node(node, parent-name)
    })

    if parent-name != none {
      cmds += draw-edge(parent-name, name, node)
    }

    for child in node.children {
      cmds += render(child, name)
    }

    return cmds
  }

  let root = build-node(root)

  return (ctx => {
    let tree-root = layout(root, ctx)
    let (ctx, drawables) = process.many(ctx, render(tree-root, none))

    let anchors = anchors(tree-root, none)

    return (
      ctx: ctx,
      name: name,
      anchors: anchor_.setup(anchor => anchors.at(anchor), anchors.keys(), name: name, transform: ctx.transform),
      drawables: drawables
    )
  },)

  // ((
  //   name: name,
  //   style: style.named(),
  //   before: ctx => {
  //     ctx.groups.push((
  //       ctx: ctx,
  //       anchors: (:),
  //       tree-root: layout(root, ctx)
  //     ))
  //     return ctx
  //   },
  //   after: ctx => {
  //     let self = ctx.groups.pop()
  //     let nodes = ctx.nodes
  //     ctx = self.ctx
  //     if name != none {
  //       ctx.nodes.insert(name, nodes.at(name))
  //     }
  //     return ctx
  //   },
  //   custom-anchors-ctx: (ctx) => {
  //     let self = ctx.groups.last()
  //     return anchors(self.tree-root, none)
  //   },
  //   children: (ctx) => {
  //     let self = ctx.groups.last()
  //     render(self.tree-root, none)
  //   },
  // ),)
}
