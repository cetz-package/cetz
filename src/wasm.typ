/// These functions are not in `util.typ` to avoid circular imports.

/// Call a wasm function with the given arguments and return the result.
///
/// - func (function): The wasm function to call.
/// - args (dictionary): The arguments to pass to the function.
/// -> any
#let call_wasm(func, args) = {
  let encoded = cbor.encode(args)
  cbor(func(encoded))
}
