# Typecheck a single Idris2 source file (path relative to repo root, e.g. src/Foo.idr)
typecheck file:
    idris2 --find-ipkg --check {{file}}

# Typecheck every .idr file under src/
typecheck-src:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob globstar
    files=(src/*.idr src/**/*.idr)
    if ((${#files[@]} == 0)); then
      echo "No .idr files under src/" >&2
      exit 1
    fi
    declare -A seen=()
    for f in "${files[@]}"; do
      [[ -n ${seen[$f]+x} ]] && continue
      seen[$f]=1
      echo "typechecking $f"
      idris2 --find-ipkg --check "$f"
    done
