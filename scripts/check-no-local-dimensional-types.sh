#!/usr/bin/env bash
#
# check-no-local-dimensional-types.sh
#
# Enforces REQUIREMENTS.md DEPS-02: "no local dimensional types are defined".
#
# `kalecky-semantics` is this project's single source of dimensional, unit, currency and
# price types. Declaring a second one here would create exactly the "third dimensional
# system" PROJECT.md forbids. Two independent checks run; both must pass.
#
#   Check A — no local declaration of a dimensional / unit-shaped type.
#   Check B — the tokens `kalecky` / `Currency` / `Measure` / `Valuation` appear in
#             src/ and test/ only on an import of a `Kalecky.*` module, or in a comment.
#
# Exit 0 and print `no-local-dimensional-types: OK` when clean; exit 1 with the offending
# file:line otherwise.

set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root" || exit 1

fail=0

# --- Check A: no locally declared dimensional / unit-shaped type -------------------
# `Unit\b` deliberately does NOT match `UnitProof` (no word boundary between `t` and `P`),
# so a type synonym *over* an imported Kalecky type is allowed; a redeclaration is not.
decl_pattern='^[[:space:]]*(data|newtype|type)[[:space:]]+(Unit|CompoundUnit|LaborUnit|MoneyUnit|TimeUnit|Currency|Measure|Valuation|Price|PriceIndex|Wage|Quantity|Dimension)\b'
decls=$(grep -rnE "$decl_pattern" src/ test/ 2>/dev/null || true)
if [ -n "$decls" ]; then
  echo "FAIL (A): local dimensional type declaration(s) found:"
  echo "$decls"
  fail=1
fi

# --- Check B: dimensional names only via a Kalecky import, or in a comment ---------
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  content=${hit#*:}          # strip "path:"
  content=${content#*:}      # strip "lineno:"
  case "$content" in
    *"import Kalecky."*|*"import qualified Kalecky."*) continue ;;
  esac
  trimmed=${content#"${content%%[![:space:]]*}"}
  case "$trimmed" in
    --*|"{-"*|"-}"*|"|"*) continue ;;
  esac
  echo "FAIL (B): dimensional name outside a Kalecky import or comment: $hit"
  fail=1
done < <(
  {
    grep -rniE 'kalecky' src/ test/ 2>/dev/null || true
    grep -rnE 'Currency|Measure|Valuation' src/ test/ 2>/dev/null || true
  }
)

if [ "$fail" -ne 0 ]; then
  echo "no-local-dimensional-types: FAILED"
  exit 1
fi

echo "no-local-dimensional-types: OK"
