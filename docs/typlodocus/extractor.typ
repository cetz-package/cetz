#import "parser.typ"

/// Extracts documentation comment blocks
/// plus the next function signature from
/// a list of lines.
///
/// - lines (array): List of lines to parse.
/// -> array Array of dictionaries of the form (comment: (raw:, text:, arguments: ((name:, types: (,), default-value:, text:),)), signature: (name:, arguments: ((name:, default-value:, has-default:),)))
#let extract-doc-comments(lines) = {
  let comments = ()

  let in-comment = false
  let current-comment = ""

  let i = 0
  while i < lines.len() {
    let line = lines.at(i).trim(at: end)

    if line.starts-with("///") {
      in-comment = true
      current-comment += line.slice(3).trim() + "\n"
    } else if in-comment {
      if line.starts-with(regex(`#let\s+`.text)) {
        let function = parser.parse-function-signature(lines.slice(i))
        comments.push((
          comment: parser.parse-docstring(current-comment),
          signature: function,
        ))
      }

      in-comment = false
      current-comment = ""
    }

    i += 1
  }

  return comments
}
