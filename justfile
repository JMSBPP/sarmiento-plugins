# Typecheck an .idr source file, package name, or .ipkg
typecheck file:
    #!/usr/bin/env bash
    set -euo pipefail
    file="{{file}}"
    if [[ "$file" == *.idr ]]; then
      "$(pack app-path idris2)" --find-ipkg --check "$file"
    else
      pack typecheck "$file"
    fi

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
    idris2="$(pack app-path idris2)"
    declare -A seen=()
    for f in "${files[@]}"; do
      [[ -n ${seen[$f]+x} ]] && continue
      seen[$f]=1
      echo "typechecking $f"
      "$idris2" --find-ipkg --check "$f"
    done
