// TODO: see if we can perform documentation diagnostics:
//       (1) the diagnostics would include:
//           - default argument type validation (would have to look into how do
//             this with custom types but it's feasible,)
//           - argument name validation (feasible considering we preprocess the
//             function signature prior to the docstring, though it would
//             require further rework,)
//       (2) the diagnostics should panic such that querying fails and the error
//           is reported during the doc building process (to better diagnose
//           issues whenever this happens in CI, it would be best if the errors
//           were also written to some log file or alternatively replaced the
//           query operation, and the Python script reported the actual error
//           and wrote to file if a specific json schema in the expected query
//           results is detected.)

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

// TODO: change the `symbol` key in the corresponding dictionaries with the
//       `token` key.
// TODO: see if repetitive code blocks at different stages of the parsing
//       process can be refactored into a set of functions that handle such
//       functionality in an isolated manner.
// NOTE: a current limitation of this parser is that Typst code that would get
//       parsed as some output 'A', will get parsed as an output 'B' instead
//       because whitespace removal is performed eagerly at the start of all
//       lines. As an example, take Typst's lists; They use whitespace to denote
//       offsetting from top-level items, but this won't be the case after this
//       gets parsed.
#let parse-docstring-alt(string) = {
  let indent-ws = 0
  let example-fields = (
    symbol: (
      open: "```example",
      close: "```",
    ),
    inside: false,
  )
  let parameter-fields = (
    symbol: (
      param: "-",
      param-list-open: "(",
      param-list-close: ")",
    ),
    inside: false,
    inside-param-list: false,
    re: (
      line: regex(
        // TODO: rework the part of the regex parsing the optional type list to
        //       make it accept only comma-optional separated sequences.
        `^-(\s+)((?:\.{2})?[[:alnum:]_-]+)((?:\s+)(?:\()([[:alnum:][:blank:]-_\.,]+)(?:\)))?((?:\s+=\s+)([^:]+))?(:\s+(.+))?`.text,
      ),
      parameter-list: regex(`([[:alnum:]-_\.]+)(?:,){0,1}`.text),
      default-param: regex(`\)(\s+=\s+([^:]+))?:(?:\s*)?(.*)?`.text),
    ),
    indent-ws: 0,
  )
  let result-fields = (
    symbol: "->",
    inside: false,
    re: regex(`^->(\s+)\(?([[:alnum:]-_]+)\)?((?:\s+)(.+))?`.text),
    indent-ws: 0,
  )
  // NOTE: this matches the empty string on non-matching haystacks, so it's
  //       never `none`.
  let comment-ws-re = regex(`^([[:blank:]]*).*`.text)
  let arguments = ()
  let result = ()
  let text = ()
  // NOTE: this is meant to store the contents of (possibly) parameter
  //       documentation in case it turns out to be Typst native list syntax
  //       instead of a multiline parameter type list.
  let tmp-buffer = none

  for line in string.split("\n") {
    if not (example-fields.inside or parameter-fields.inside or result-fields.inside) {
      indent-ws = line.match(comment-ws-re).captures.first().len()
      line = line.slice(indent-ws)

      if line.len() == 0 and text.last().len() == 0 {
        continue
      } else if line.starts-with(example-fields.symbol.open) {
        example-fields.inside = true
        text.push(line.trim(at: end))
      } else if line.starts-with(result-fields.symbol) {
        let re-result = line.match(result-fields.re)
        if re-result != none {
          result-fields.indent-ws = re-result.captures.first().len()
          result-fields.inside = true

          result.push((
            type: re-result.captures.at(1),
            text: if re-result.captures.at(3) != none {
              (re-result.captures.at(3).trim(at: end),)
            } else {
              ()
            },
          ))

          continue
        }
      } else if line.starts-with(parameter-fields.symbol.param) {
        let param = line.match(parameter-fields.re.line)
        if param != none {
          parameter-fields.indent-ws = param.captures.first().len()
          parameter-fields.inside = true

          if (
            param.captures.at(2) == none
              and param.captures.at(3) == none
              and param.captures.at(4) == none
          ) { tmp-buffer = (line,) }

          arguments.push((
            name: param.captures.at(1),
            types: if param.captures.at(3) != none {
              param
                .captures
                .at(3)
                .matches(parameter-fields.re.parameter-list)
                .map(it => it.captures.first())
            } else {
              ()
            },
            default-value: if param.captures.at(5) != none { param.captures.at(5) } else { none },
            text: if param.captures.at(7) != none {
              (param.captures.at(7).trim(at: end),)
            } else {
              ()
            },
          ))

          continue
        }
      } else {
        text.push(line.trim(at: end))
      }
    } else if example-fields.inside {
      let tmp-ws = line.match(comment-ws-re).captures.first().len()
      line = line.slice(tmp-ws)

      if line.starts-with(example-fields.symbol.close) { example-fields.inside = false }
      text.push(line)
    } else if parameter-fields.inside {
      let tmp-ws = line.match(comment-ws-re).captures.first().len()
      line = line.slice(tmp-ws)

      if tmp-ws < indent-ws + parameter-fields.indent-ws + parameter-fields.symbol.param.len() {
        parameter-fields.inside = false
        indent-ws = tmp-ws

        if tmp-buffer != none {
          arguments.pop()
          for buf in tmp-buffer { text.push(buf) }

          tmp-buffer = none
        }

        if line.starts-with(result-fields.symbol) {
          let re-result = line.match(result-fields.re)
          if re-result != none {
            result-fields.indent-ws = re-result.captures.first().len()
            result-fields.inside = true

            result.push((
              type: re-result.captures.at(1),
              text: if re-result.captures.at(3) != none {
                (re-result.captures.at(3).trim(at: end),)
              } else {
                ()
              },
            ))
          }
        } else if line.starts-with(parameter-fields.symbol.param) {
          let param = line.match(parameter-fields.re.line)
          if param != none {
            parameter-fields.indent-ws = param.captures.first().len()
            parameter-fields.inside = true

            if (
              param.captures.at(2) == none
                or param.captures.at(3) == none
                or param.captures.at(4) == none
            ) { tmp-buffer = (line,) }

            arguments.push((
              name: param.captures.at(1),
              types: if param.captures.at(3) != none {
                param
                  .captures
                  .at(3)
                  .matches(parameter-fields.re.parameter-list)
                  .map(it => it.captures.first())
              } else {
                ()
              },
              default-value: if param.captures.at(5) != none { param.captures.at(5) } else { none },
              text: if param.captures.at(7) != none {
                (param.captures.at(7).trim(at: end),)
              } else {
                ()
              },
            ))
          }
        } else {
          if text.last().len() == 0 and line.len() == 0 { continue }
          text.push(line.trim(at: end))
        }
      } else {
        if parameter-fields.inside-param-list {
          if line.starts-with(parameter-fields.symbol.param-list-close) {
            parameter-fields.inside-param-list = false

            let result = line.match(parameter-fields.re.default-param)
            if result != none { arguments.last().text.push(result.captures.at(1)) }
          } else {
            let result = line.match(parameter-fields.re.parameter-list)
            if result != none { arguments.last().types.push(result.captures.first()) }
          }
        } else if arguments.last().types.len() == 0 {
          if tmp-buffer.len() == 1 and line.first() == parameter-fields.symbol.param-list-open {
            parameter-fields.inside-param-list = true
          } else {
            tmp-buffer.push(line)
          }
        } else {
          arguments.last().text.push(line.trim(at: end))
        }
      }
    } else if result-fields.inside {
      let tmp-ws = line.match(comment-ws-re).captures.first().len()
      line = line.slice(tmp-ws)

      if tmp-ws < indent-ws + result-fields.indent-ws + result-fields.symbol.len() {
        result-fields.inside = false
        indent-ws = tmp-ws

        if line.starts-with(result-fields.symbol) {
          let re-result = line.match(result-fields.re)
          if re-result != none {
            result-fields.indent-ws = re-result.captures.first().len()
            result-fields.inside = true

            result.push((
              type: re-result.captures.at(1),
              text: if re-result.captures.at(3) != none {
                (re-result.captures.at(3).trim(at: end),)
              } else {
                ()
              },
            ))
          }
        } else if line.starts-with(parameter-fields.symbol.param) {
          let param = line.match(parameter-fields.re.line)
          if param != none {
            parameter-fields.indent-ws = param.captures.first().len()
            parameter-fields.inside = true

            if (
              param.captures.at(2) == none
                or param.captures.at(3) == none
                or param.captures.at(4) == none
            ) { tmp-buffer = (line,) }

            arguments.push((
              name: param.captures.at(1),
              types: if param.captures.at(3) != none {
                param
                  .captures
                  .at(3)
                  .matches(parameter-fields.re.parameter-list)
                  .map(it => it.captures.first())
              } else {
                ()
              },
              default-value: if param.captures.at(5) != none { param.captures.at(5) } else { none },
              text: if param.captures.at(7) != none {
                (param.captures.at(7).trim(at: end),)
              } else {
                ()
              },
            ))
          }
        } else if line.starts-with(example-fields.symbol.open) {
          example-fields.inside = true
          text.push(line.trim(at: end))
        } else {
          if text.last().len() == 0 and line.len() == 0 { continue }
          text.push(line.trim(at: end))
        }
      } else {
        result.last().text.push(line.trim(at: end))
      }
    }
  }

  if tmp-buffer != none {
    for buf in tmp-buffer { text.push(buf) }
    arguments.pop()
  }

  return (
    raw: string,
    text: text.join("\n", default: "").trim(),
    arguments: arguments.map(it => (
      ..it,
      text: it
        .text
        .join(
          "\n",
          default: "",
        )
        .trim(),
    )),
    result: result.map(it => (
      ..it,
      text: it
        .text
        .join(
          "\n",
          default: "",
        )
        .trim(),
    )),
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
