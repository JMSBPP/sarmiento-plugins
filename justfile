# Typecheck a package name or .ipkg file
typecheck file:
    pack typecheck {{file}}

# Typecheck the local library package (all modules under src/)
typecheck-src:
    pack typecheck sarmiento-plugins

# Emit deps.inc (git pin → .cache/ if needed) then gams action=ce under src/
gams file:
    #!/usr/bin/env bash
    set -euo pipefail
    pack run sarmiento-plugins
    mkdir -p src/build
    f="{{file}}"
    f="${f#file=}"
    f="${f#src/}"
    out="build/$(echo "$f" | tr / _ | sed 's/\.gms$//').lst"
    cd src && gams "$f" action=ce o="$out" scrdir=build lo=3
