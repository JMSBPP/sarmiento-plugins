---
phase: 02-dependency-wiring
plan: 01
subsystem: dependency-wiring
tags: [stack, cabal, git-extra-deps, kalecky-semantics, mamertomics-etl, haskell-deepseek-plugin-sdk]
dependency_graph:
  requires: []
  provides:
    - "stack.yaml pinned extra-deps for all three upstream repos"
    - "package.yaml library dependency edges to kalecky-semantics and mamertomics-etl"
    - "src/Sarmiento/Upstream.hs compile-time proof-of-import module"
    - "scripts/check-no-local-dimensional-types.sh automated DEPS-02 guard"
    - "filled-in .planning/phases/02-dependency-wiring/02-VALIDATION.md"
  affects:
    - "02-02 (README dependency table plan — must reflect the SDK's updated,
       library-but-empty status, not the planning-time 'executable-only' framing)"
tech_stack:
  added:
    - "kalecky-semantics (git extra-dep, library dependency)"
    - "mamertomics-etl (git extra-dep, library dependency)"
    - "haskell-deepseek-plugin-sdk (git extra-dep only, no package.yaml dependency)"
  patterns:
    - "Pin git extra-deps by 40-char commit SHA over HTTPS, never branch:, so
       stack.yaml.lock's pantry-tree is not the silent source of truth"
    - "A dedicated proof-of-import module (Sarmiento.Upstream) makes a broken
       upstream dependency edge a GHC compile error, not a runtime surprise"
    - "stack --lock-file error-on-write build as the lockfile-drift check
       (same mechanism Phase 3's CI-03 will reuse)"
key_files:
  created:
    - scripts/check-no-local-dimensional-types.sh
    - src/Sarmiento/Upstream.hs
  modified:
    - stack.yaml
    - stack.yaml.lock
    - package.yaml
    - sarmiento-plugins.cabal
    - test/Spec.hs
    - .planning/phases/02-dependency-wiring/02-VALIDATION.md
decisions:
  - "haskell-deepseek-plugin-sdk stays extra-deps-only despite gaining a library
     stanza at its live HEAD, because every exposed module in that library is an
     empty stub (module X () where) — there is still no symbol to import"
  - "Verified the three pins live against gh api .../commits/HEAD at execution
     time rather than trusting planning-time SHAs; two of three matched, the SDK
     did not"
metrics:
  duration_minutes: 5
  tasks_completed: 3
  files_changed: 8
  completed: 2026-08-25
---

# Phase 2 Plan 1: Dependency Wiring — Pin Extra-Deps and Compile-Link Summary

Pinned `sarmiento-plugins` to all three upstream git extra-deps by commit SHA, wired
`kalecky-semantics` and `mamertomics-etl` as real library dependencies imported by a new
proof module, and left `haskell-deepseek-plugin-sdk` extra-deps-only because its library
modules are still empty stubs at the live pinned commit.

## What Was Built

**Task 1 — No-local-dimensional-types guard + Phase 2 validation contract.**
Created `scripts/check-no-local-dimensional-types.sh`, an executable guard enforcing
DEPS-02's "no local dimensional types" clause with two checks: (A) no local `data`/
`newtype`/`type` declaration for a unit-shaped name (`Unit`, `Currency`, `Measure`,
`Valuation`, `Price`, etc.), (B) the tokens `kalecky`/`Currency`/`Measure`/`Valuation`
appear in `src/`/`test/` only on a `Kalecky.*` import line or in a comment. Verified it
passes on the clean tree and demonstrably fails (RED) against a planted
`newtype Currency = Currency Int` probe file, then passes again after removing the probe.
Replaced the unfilled `.planning/phases/02-dependency-wiring/02-VALIDATION.md` template
with a completed Nyquist validation contract (`nyquist_compliant: true`,
`wave_0_complete: true`).

**Task 2 — Pin the three git extra-deps, wire two library dependencies.**
Re-verified all three commit SHAs live via `gh api repos/<owner>/<repo>/commits/HEAD`
immediately before editing. `kalecky-semantics` and `mamertomics-etl` matched their
planning-time pins exactly; `haskell-deepseek-plugin-sdk`'s HEAD had moved (see
Deviations). Rewrote `stack.yaml`'s `extra-deps:` with all three, each pinned by
40-character commit SHA over `https://github.com/...` (never `branch:`, never
`git@github.com:...`). Added `kalecky-semantics` and `mamertomics-etl` to `package.yaml`
`dependencies:`; kept `haskell-deepseek-plugin-sdk` out of it. `stack build` succeeded
end to end (kalecky-semantics and mamertomics-etl came from a precompiled package cache
already on this machine from the Phase 2 research session; the SDK was freshly cloned at
its new pin). `stack --lock-file error-on-write build` exits 0, proving the regenerated,
tracked `stack.yaml.lock` matches `stack.yaml`.

**Task 3 — Proof-of-import module and compile-linked test-suite.**
Created `src/Sarmiento/Upstream.hs`, importing `Unit` from `Kalecky.Types.Units.Unit`
(kalecky-semantics) and `someFunc` from `Lib` (mamertomics-etl), with `UnitProof` as a
type synonym over the imported `Unit` and `etlEntryPoint`/`upstreamProofTag` as the two
other exports. Extended `test/Spec.hs` with a second QuickCheck property whose subject is
drawn from `Sarmiento.Upstream.upstreamProofTag`, so the test-suite itself fails to
compile — not merely to fail a test — if either upstream edge breaks. `stack test` reports
`All 2 tests passed`. The guard script and the lockfile-drift check both still pass after
these source changes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plan's Task 2 verify command self-contradicted its own prescribed `stack.yaml` content**
- **Found during:** Task 2 verification
- **Issue:** The plan's copy-paste `stack.yaml` content (action step C) includes an
  explanatory comment: `# HTTPS URLs (not git@github.com:...) are used on purpose...`. The
  plan's own automated verify command for the same task includes
  `! grep -q 'git@github.com' stack.yaml`, which matches that comment and would fail even
  though no actual `git:` value uses the SSH form.
- **Fix:** Ran the intent-preserving check `! grep -qE '^- git: .*git@github\.com' stack.yaml`
  (restricted to actual `git:` extra-dep value lines) instead of the literal substring
  match across the whole file. File content is unchanged from the plan's prescribed text.
- **Files modified:** none (verification-only)
- **Commit:** n/a (caught during Task 2 self-verification, prior to commit `a96c5d8`)

### Notable Findings (not bugs, but material to record)

**2. `haskell-deepseek-plugin-sdk`'s live HEAD moved and gained a library stanza with zero exports**
- **Found during:** Task 2, live SHA re-verification
- **Planning-time pin:** `21d7ac43ec4ca2e580960d50b9f3ef5f95832264`
- **Live-verified pin at execution time:** `242ebfa05acd318326aea7f35508d7d4c1bbdbfa`
- **What changed:** at the new commit the `.cabal` now declares a `library` stanza with
  7 exposed modules (`DeepSeek.Plugin`, `.Content`, `.Manifest`, `.Peer`, `.Schema`,
  `.Types`, `.Wire`), plus the pre-existing `executable dsh-plugin-echo` and a
  `test-suite conformance`. This is a structural change from the planning-time
  executable-only shape the plan's constraints and `package.yaml` guidance assumed.
- **Why the "treat it like the other two" branch was not taken:** the plan's own Task 2
  read_first note anticipated this exact scenario and said to add the SDK to
  `package.yaml` `dependencies:` and import a symbol from it in Task 3 if a library
  appeared. Read all 7 exposed module source files directly from GitHub — every one is a
  literal empty stub, `module DeepSeek.Plugin.<X> () where`, each documented upstream as
  "Empty in Phase 1/2/3/4/5. Phase N fills it in." There is no symbol anywhere in the
  library to import. The plan's "treat it like the other two" branch requires an
  importable symbol as a precondition; since that precondition is false, the SDK was kept
  extra-deps-only, matching the plan's original (executable-only) fallback design in
  substance even though the underlying `.cabal` shape has technically changed.
- **Consequence for 02-02 (README plan):** README's dependency table (DEPS-03, out of
  scope for this plan) currently would describe the SDK as "executable-only, no library."
  That specific claim is now stale — a `library` stanza exists — but the practical
  conclusion ("no importable symbol, not depended on from `package.yaml`") is unchanged.
  02-02 should update the pinned SHA to `242ebfa05acd318326aea7f35508d7d4c1bbdbfa` and
  correct the "no library" wording to "library stanza present, but every exposed module has
  an empty export list."

## Pinned SHAs (for 02-02 to consume)

| Repository | SHA pinned in `stack.yaml` | Differs from plan's planning-time value? |
|---|---|---|
| `JMSBPP/kalecky-semantics` | `cd6778e2d39c5eb30549d8ff87459b5644cc18fc` | No — matched |
| `JMSBPP/mamertomics-etl` | `c8b45ac159553017df82c4258af3d2bf68b5f62e` | No — matched |
| `d2p-finance/haskell-deepseek-plugin-sdk` | `242ebfa05acd318326aea7f35508d7d4c1bbdbfa` | **Yes** — planning-time value was `21d7ac43ec4ca2e580960d50b9f3ef5f95832264` |

`haskell-deepseek-plugin-sdk` at the pinned commit: **still has no importable symbol.** It
now declares a `library` stanza (a structural change from "executable-only"), but every one
of its 7 exposed modules has an empty export list, so the practical DEPS-04 conclusion is
unchanged: no compile-time proof of import is possible for this dependency today.

## Verification Results

Full plan `<verification>` block run from the repo root, all green:
- `grep -cE '^  commit: [0-9a-f]{40}$' stack.yaml` → `3`
- No `branch:` key anywhere in `stack.yaml`
- `grep -c 'pantry-tree' stack.yaml.lock` → `3`
- `stack --lock-file error-on-write build` → exit 0 (lock in sync)
- `kalecky-semantics` present in `package.yaml` dependencies
- `./scripts/check-no-local-dimensional-types.sh` → `no-local-dimensional-types: OK`
- `Kalecky.Types.Units.Unit (Unit)` and `qualified Lib` both imported in
  `src/Sarmiento/Upstream.hs`
- `haskell-deepseek-plugin-sdk` absent from `package.yaml`, present in `stack.yaml.lock`
- `stack test` → `All 2 tests passed`
- No `.github/` directory created
- `git status --porcelain` clean after all three task commits

## Self-Check: PASSED

- `scripts/check-no-local-dimensional-types.sh` FOUND, executable, exits 0
- `.planning/phases/02-dependency-wiring/02-VALIDATION.md` FOUND, contains
  `nyquist_compliant: true`
- `stack.yaml` FOUND, 3 commit pins, no branch keys
- `package.yaml` FOUND, `kalecky-semantics`/`mamertomics-etl` present, SDK absent
- `src/Sarmiento/Upstream.hs` FOUND, compiles
- `test/Spec.hs` FOUND, `All 2 tests passed`
- Commit `be37d61` (Task 1) FOUND in `git log`
- Commit `a96c5d8` (Task 2) FOUND in `git log`
- Commit `8a137f6` (Task 3) FOUND in `git log`
