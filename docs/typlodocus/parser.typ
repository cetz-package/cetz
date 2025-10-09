#let parse-argument-list(string) = {
  let arguments = ()
  let current-arg = ""
  let current-default = ""
  let named-arg = false

  let depth = 0
  let in-str = false
  let in-content = false
  let escape-next = false

  for char in string.codepoints() {
    if in-content and not escape-next {
      if char == "]" { in-content = false }
    } else if char == "\"" and not escape-next {
      in-str = not in-str
    } else if not in-str {
      if char == "(" { depth += 1 }
      else if char == ")" { depth -= 1 }
      else if char == "[" { in-content = true }
      else if char == "," and depth == 0 {
        arguments.push((
          name: current-arg.trim(),
          default-value: current-default.trim(),
          has-default: named-arg,
        ))

        current-arg = ""
        current-default = ""
        named-arg = false
        continue
      } else if char == ":" and depth == 0 {
        named-arg = true
        continue
      }
    }

    if named-arg {
      current-default += char
    } else {
      current-arg += char
    }
  }

  if current-arg.trim() != "" {
    arguments.push((
      name: current-arg.trim(),
      default-value: current-default.trim(),
      has-default: named-arg,
    ))
  }

  return arguments
}

#let parse-function-signature(lines) = {
  let let-re = regex("^#?let\s+")
  let identifier-re = regex("^([_a-zA-Z]+[_\w-]*)")
  
  let combined-line = lines.join(" ")
  combined-line = combined-line.trim()

  // Cut off #let or let
  let let-m = combined-line.match(let-re)
  if let-m == none {
    return none
  }
  combined-line = combined-line.slice(let-m.end)
  
  // Parse function name
  let identifier-m = combined-line.match(identifier-re)
  if identifier-m == none {
    return none
  }
  
  let name = identifier-m.captures.at(0)
  combined-line = combined-line.slice(identifier-m.end)
  
  // Check if we have an argument list
  let paren-match = combined-line.match(regex("^\s*\("))
  if paren-match == none {
    return none
  }
  
  // Parse the entire argument list
  let args-start = paren-match.end
  let paren-depth = 1
  let in-str = false
  let in-content = false
  let escape-next = false
  let args-end = none

  // Find the argument list bounds
  for ((i, char)) in combined-line.slice(paren-match.end).codepoints().enumerate() {
    if escape-next {
      escape-next = false
    } else if in-content {
      if char == "]" {
        in-content = false
      }
    } else if char == "\\" {
      escape-next = true
    } else if char == "\"" {
      in-str = not in-str
    } else if not in-str {
      if char == "(" {
        paren-depth += 1
      } else if char == ")" {
        paren-depth -= 1
        if paren-depth == 0 {
          args-end = args-start + i
          break
        }
      } else if char == "[" {
        in-content = true
      }
    }
  }
  
  if args-end == none {
    return none
  }
  
  // Parse arguments
  let arguments = ()

  let args-str = combined-line.slice(args-start, args-end)
  if args-str.trim() != "" {
    arguments = parse-argument-list(args-str)
  }
  
  return (
    name: name,
    arguments: arguments
  )
}

#let parse-docstring(string) = {
  let argument-re = regex("-\s+(\.*[_a-zA-Z]+[-\w]*)(\s+\\(.*?\\))?(\s*=\s*.*?)?:(.*)")
  let result-re = regex("->\s+([_a-zA-Z]+[-\w]*)\s+(.*)")

  let lines = string.split("\n")

  let text = ""
  let arguments = ()
  let result = ()

  for line in lines {
    let result-m = line.match(result-re)
    let argument-m = line.match(argument-re)
    if argument-m != none {
      let name = argument-m.captures.at(0).trim()

      let type-list = argument-m.captures.at(1)
      if type-list != none {
        type-list = type-list.slice(2, -1).split(",").map(s => s.trim())
      }

      let default-value = argument-m.captures.at(2)
      if default-value != none {
        default-value = default-value.trim()
      }

      let description = argument-m.captures.last()
      if description != none {
        description = description.trim()
      }

      arguments.push((
        name: name,
        types: type-list,
        default-value: default-value,
        text: description,
      ))
    } else if result-m != none {
      result.push((
        type: result-m.captures.at(0).trim(),
        text: result-m.captures.at(1).trim()
      ))
    } else {
      text += line + "\n"
    }
  }

  return (
    raw: string,
    text: text.trim(),
    arguments: arguments,
    result: result,
  )
}
