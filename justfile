# Typecheck a package name or .ipkg file
typecheck file:
    pack typecheck {{file}}

# Typecheck every module under src/ via the local package
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
    done
    pack typecheck sarmiento-plugins
