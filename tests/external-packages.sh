#!/usr/bin/env sh
set -eu

ROOT="$(dirname "$0")/.."

TYPST_PACKAGE_PATH="$(mktemp -d)"
export TYPST_PACKAGE_PATH

(
  echo "$PWD, $ROOT"
  "$ROOT/common/scripts/package" @preview --version "HEAD"

  cd "$TYPST_PACKAGE_PATH/preview"
  ln -s "./HEAD" "0.3.0"
  ln -s "./HEAD" "0.3.1"
  ln -s "./HEAD" "0.3.2"
  ln -s "./HEAD" "0.3.3"
  ln -s "./HEAD" "0.3.4"
)

# Finite
(
  cd "$(mktemp -d)"
  git clone "https://github.com/jneug/typst-finite.git"
  cd typst-finite
  #git checkout "v0.5.0"
  just test
)

# Fletcher
(
  cd "$(mktemp -d)"
  git clone "https://github.com/Jollywatt/typst-fletcher.git"
  cd typst-fletcher
  git checkout "v0.5.8"
  tt run
)
