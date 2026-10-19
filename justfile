# Typecheck a package name or .ipkg file
typecheck file:
    pack typecheck {{file}}

# Typecheck the local library package (all modules under src/)
typecheck-src:
    pack typecheck sarmiento-plugins

# Emit deps.inc then compile a GAMS module under src/.
# Requires KALECKY_CHECKOUT=/path/to/kalecky/repo (GAMS src = $KALECKY_CHECKOUT/src).
# Usage:  just gams parameters/TechDiffusion.gms
# Listing: src/build/<slashes_to_underscores>.lst
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
