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

  let escape-hit = false
  let delim-stack = ("(",)
  let delim-lut = (
    start: (
      "\"",
      "(",
      "[",
      "{",
    ),
    end: (
      "\"",
      ")",
      "]",
      "}",
    ),
  )
  let arguments = ()
  let current-arg = (
    name: "",
    default-value: "",
    has-default: false,
  )
  let marker-lut = (
    ":",
    ",",
  )
  let in-named-arg = false
  let indent-ws
  let indent-re = regex(`^(\s+).*`.text)

  for line in lines {
    if delim-stack.len() == 1 {
      let tmp = line.match(indent-re)
      if tmp != none { indent-ws = tmp.captures.first().len() }

      line = line.trim(at: start)
    }
    if in-named-arg {
      let stack-top = delim-stack.last()

      if stack-top == delim-lut.start.at(1) or stack-top == delim-lut.start.at(3) {
        let tmp = line.match(regex(`^(\s{`.text + str(indent-ws) + `}).*`.text))
        if tmp != none { line = line.slice(2) }
      }

      current-arg.default-value += "\n"
    }

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

      if char in delim-lut.start or char in delim-lut.end {
        if stack-top == delim-lut.start.at(0) {
          if char == delim-lut.end.at(0) { delim-stack.pop() }
          if in-named-arg { current-arg.default-value += char }
        } else if stack-top == delim-lut.start.at(2) {
          if char == delim-lut.end.at(2) { delim-stack.pop() }
          if in-named-arg { current-arg.default-value += char }
        } else if stack-top == delim-lut.start.at(3) {
          if char == delim-lut.end.at(3) { delim-stack.pop() }
          if in-named-arg { current-arg.default-value += char }
        } else {
          if char in delim-lut.start {
            delim-stack.push(char)
            if in-named-arg { current-arg.default-value += char }
          } else if char in delim-lut.end {
            if in-named-arg and delim-stack.len() > 1 { current-arg.default-value += char }
            delim-stack.pop()
          }
        }

        if delim-stack.len() == 0 {
          if current-arg.name.len() != 0 {
            current-arg.name = current-arg.name.trim()
            if current-arg.has-default {
              current-arg.default-value = current-arg.default-value.trim()
            }

            arguments.push(current-arg)
          }
          break
        }
      } else if delim-stack.len() == 1 {
        if char not in marker-lut and not in-named-arg {
          current-arg.name += char
        } else if char == marker-lut.first() {
          in-named-arg = true
          current-arg.has-default = true
        } else if char == marker-lut.last() {
          in-named-arg = false

          current-arg.name = current-arg.name.trim()
          if current-arg.has-default {
            current-arg.default-value = current-arg.default-value.trim()
          }
          arguments.push(current-arg)

          current-arg = (
            name: "",
            default-value: "",
            has-default: false,
          )
        } else if in-named-arg {
          current-arg.default-value += char
        }
      } else if in-named-arg {
        current-arg.default-value += char
      }
    }

    if delim-stack.len() == 0 { break }
  }

  return (
    name: ident,
    arguments: arguments,
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
