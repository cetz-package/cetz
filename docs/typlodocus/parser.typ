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
      if char == "(" {
        depth += 1
      } else if char == ")" {
        depth -= 1
      } else if char == "[" {
        in-content = true
      } else if char == "," and depth == 0 {
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
  let ident = lines
    .first()
    .replace(
      regex(`#let\s+([_[:alnum:]-]+).*`.text),
      match => match.captures.first(),
      count: 1,
    )

  lines.first() = lines
    .first()
    .trim(
      regex(`#let\s+[_[:alnum:]-]+\(?`.text),
      at: start,
      repeat: false,
    )

  if lines.first().starts-with(regex(`\s*=`.text)) {
    return (
      name: ident,
      arguments: (),
    )
  }

  let param-end-line = -1
  let param-end-char-pos
  let escape-hit = false
  let delim-stack = ("(",)
  let delim-lut = (
    start: (
      "\"",
      "(",
      "[",
    ),
    end: (
      "\"",
      ")",
      "]",
    ),
  )

  for line in lines {
    param-end-char-pos = -1

    for char in line.codepoints() {
      if char == "\\" {
        escape-hit = true
        continue
      }
      if escape-hit {
        escape-hit = false
        continue
      }

      let stack-top = delim-stack.last()
      if stack-top == delim-lut.start.first() {
        if char == delim-lut.end.first() { delim-stack.pop() }
      } else if stack-top == delim-lut.start.last() {
        if char == delim-lut.end.last() { delim-stack.pop() }
      } else {
        if char in delim-lut.start {
          delim-stack.push(char)
        } else if char in delim-lut.end {
          delim-stack.pop()
        }
      }

      param-end-char-pos += 1
      if delim-stack.len() == 0 { break }
    }

    param-end-line += 1
    if delim-stack.len() == 0 { break }
  }

  let param-span = lines
    .slice(0, param-end-line + 1)
    .enumerate()
    .fold("", (accum, (line-num, line)) => {
      if line-num == param-end-line {
        accum + " " + line.slice(0, param-end-char-pos)
      } else {
        accum + " " + line
      }
    })
    .trim()

  return (
    name: ident,
    arguments: parse-argument-list(param-span),
  )
}

#let parse-docstring(string) = {
  let argument-re = regex("-\s+(\.*[_a-zA-Z]+[-\w]*)\s+(\\(.*?\\))?(\s*=\s*.*?)?:(.*)")
  let result-re = regex("->\s+\(?([_a-zA-Z]+[-\w]*)\)?\s*(.*)")

  let lines = string.split("\n")

  let text = ""
  let arguments = ()
  let in-argument = false
  let result = ()
  let in-result = false

  for line in lines {
    let result-m = line.match(result-re)
    let argument-m = line.match(argument-re)

    if in-result and not line.starts-with("   ") {
      in-result = false
    }

    if in-argument and not line.starts-with("  ") {
      in-argument = false
    }

    if in-result {
      result.last().text += line
    } else if in-argument {
      arguments.last().text += line
    } else if argument-m != none {
      let name = argument-m.captures.at(0).trim()

      let type-list = argument-m.captures.at(1)
      if type-list != none {
        type-list = type-list.slice(1, -1).split(",").map(s => s.trim())
      }

      let default-value = argument-m.captures.at(2)
      if default-value != none {
        default-value = default-value.trim()
      }

      let description = argument-m.captures.last()
      if description != none {
        description = description.trim()
      }

      in-argument = true
      arguments.push((
        name: name,
        types: type-list,
        default-value: default-value,
        text: description,
      ))
    } else if result-m != none {
      in-result = true
      result.push((
        type: result-m.captures.at(0).trim(),
        text: result-m.captures.at(1).trim(),
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
