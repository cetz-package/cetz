#import "util.typ"

/// Parse a selector string into a list of selectors
#let parse-selector(sel) = {
  assert.eq(type(sel), str)

  return sel.split(",").map(s => {
    s = s.trim(" ", repeat: true)
    return s.split(".").map(s => s.trim(" ", repeat: true))
  })
}

/// Resolve a style using an element hierarchy as selector
///
/// - ctx (context): The current context
/// - current (array): The current style list
/// - override (style, none): Style dictionary to merge into the result
/// - element (string, array, none): Element kind hierarchy
#let resolve(ctx, current, override, element: none) = {
  let s = none

  if element == none { element = ("*",) }
  if type(element) != array { element = (element, ) }

  let match-selector(sel, elem) = {
    if sel != ("*",) {
      if sel.len() > elem.len() {
        return false
      }
      // Try backward element path match
      for i in range(1, sel.len() + 1) {
        let sel-elem = sel.at(sel.len() - i)
        if sel-elem != "*" and sel-elem != elem.at(elem.len() - i) {
          // Try forward element path match
          for i in range(0, sel.len()) {
            let sel-elem = sel.at(i)
            if sel-elem != "*" and sel-elem != elem.at(i) {
              return false
            }
          }
        }
      }
    }

    return true
  }

  // Current context hierarchy
  let hierarchy = ctx.element + element

  // Current element path
  let elem-hierarchy = ()

  // For each intermediate element, find and merge styles
  for elem in hierarchy {
    elem = elem-hierarchy + (elem,)
    for (sel, sty) in current {
      if match-selector(sel, elem) {
        if s == none {
          s = sty
        } else {
          s = util.merge-dictionary(s, sty)
        }
      }
    }

    // Add the processed element to the element path for
    // following elements
    elem-hierarchy = elem
  }

  if s == none {
    return override
  } else if override != none {
    s = util.merge-dictionary(s, override)
  }
  return s
}

// Get a weighted style list
#let sorted(list) = {
  // Selectors get scored by their class count
  // and their hierarchy depth (class > hierarchy)
  return list.sorted(key: ((sel, _)) => {
    let score = 0
    if sel != ("*",) {
      score += sel.len()
    }
    return score
  })
}

// Merge multiple generic styles into one
#let merge-list(list) = {
  let generic = none
  let offset = 0
  for (i, s) in list.enumerate() {
    let (sel, sty) = s
    if sel == (auto,) {
      generic = if generic == none {
        sty
      } else {
        util.merge-dictionary(generic, sty)
      }
      list.remove(i - offset)
      offset += 1
    }
  }
  return sorted(list + (((auto,), generic), ))
}

/* Default style list */
#let default-styles = sorted((
  (("*",), (
    stroke: black,
    fill: none,
    radius: 1.0,
  )),
  (("line",), (
    mark: (begin: none, end: none),
  )),
  (("mark",), (
    fill: none,
    size: .15,
  )),
  (("arc",), (
    mode: "OPEN",
  )),
  (("content",), (
    padding: 0,
    frame: none,
  )),
  (("shadow",), (
    color: gray,
    offset: (.1, -.1, 0)
  ))
))
