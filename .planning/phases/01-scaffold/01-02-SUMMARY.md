---
phase: 01-scaffold
plan: 02
subsystem: infra
tags: [haskell, stack, hpack, tasty, quickcheck, ghc-9.10.3, lts-24.56]

# Dependency graph
requires:
  - phase: 01-scaffold (plan 01)
    provides: ".gitignore excluding build artefacts/credentials while keeping stack.yaml.lock and the .cabal file trackable; README.md and CHANGELOG.md that package.yaml's extra-source-files reference"
provides:
  - "Stack project pinned to Stackage lts-24.56 (GHC 9.10.3) by immutable snapshot URL, extra-deps: [] (Phase 2 untouched)"
  - "hpack package.yaml with library-in-src + test-suite-in-test layout, no executable stanza, ghc-options byte-identical to the data resource's warning set"
  - "src/Sarmiento/Plugin.hs — the library's sole module, exporting pluginName and pluginVersion, the compile-time link target for the test-suite and (later) Phase 2/CI"
  - "src/Education/README.md placeholder, proven harmless to hpack module discovery by a real build"
  - "test/Spec.hs — one tasty + QuickCheck smoke property whose subject is drawn from the library, compile-enforcing the test-suite -> library link"
  - "Generated-and-tracked stack.yaml.lock and sarmiento-plugins.cabal, verified free of drift on a pristine clone-equivalent copy of the tree"
affects: ["01-scaffold phase completion", "Phase 2 (Dependency Wiring) — extra-deps entries land in the stack.yaml this plan created", "Phase 3 (CI) — caches on stack.yaml.lock and runs the exact stack build / stack test commands proven here"]

# Tech tracking
tech-stack:
  added: ["stack 3.11.1", "GHC 9.10.3 (lts-24.56)", "hpack 0.39.6", "tasty 1.5.4", "tasty-quickcheck 0.11.1", "QuickCheck 2.15.0.1"]
  patterns:
    - "Snapshot pinned by immutable URL (not bare name) so Stack never re-resolves it — mirrors the data resource"
    - "ghc-options warning set kept byte-identical across sibling repos so a module can move between them without a warning-flag surprise"
    - "Test-suite property built from a real library symbol (not base-only values) so a broken library link fails compilation, not just at runtime"

key-files:
  created: [stack.yaml, package.yaml, src/Sarmiento/Plugin.hs, src/Education/README.md, test/Spec.hs, sarmiento-plugins.cabal, stack.yaml.lock]
  modified: []

key-decisions:
  - "Rewrote the package.yaml comment that named '-Werror' (to say it is not used) because the plan's own verify script checks for zero occurrences of the literal string 'Werror' anywhere in package.yaml, including comments — the original plan-supplied comment text would have failed its own acceptance check"
  - "No version bounds added on tasty/tasty-quickcheck/QuickCheck in the test-suite dependencies — all three resolve from the pinned snapshot, so bounds would create a second, drift-prone source of truth"

patterns-established:
  - "Fresh-clone reproducibility check: reconstruct git ls-files --cached --others --exclude-standard into a scratch dir and build there before trusting a scaffold — reused verbatim by Phase 3's CI"

requirements-completed: [SCAF-01, SCAF-02, SCAF-04]

# Metrics
duration: 3min
completed: 2026-08-25
---

# Phase 1 Plan 2: Stack Project Scaffold, Library Module, and Smoke Test Suite Summary

**Stack+hpack project pinned to lts-24.56 (GHC 9.10.3), a one-module library, a `src/Education/` placeholder, and a tasty+QuickCheck property that compile-links the test-suite to the library — `stack build` and `stack test` both pass, including on a pristine clone-equivalent copy of the tree**

## Performance

- **Duration:** 3 min
- **Started:** 2026-08-25T19:32:15Z
- **Completed:** 2026-08-25T19:35:08Z
- **Tasks:** 3
- **Files modified:** 7 (all new)

## Accomplishments
- `stack build` succeeds on Stackage `lts-24.56` (GHC 9.10.3), producing a library with exactly one module (`Sarmiento.Plugin`) and no warnings
- `package.yaml`'s `ghc-options` block is byte-identical to `the data resource/package.yaml`'s nine-flag warning set, with no `-Werror` and no `executables:` stanza
- `src/Education/README.md` proven harmless: a real build confirms it contributes no module to the generated `.cabal`
- `stack test` runs one tasty + QuickCheck property (`reverse . reverse == id` over `pluginName <> suffix`) and reports `All 1 tests passed` — the property's subject is drawn from the library, so a broken `test-suite -> library` dependency would fail compilation, not just execution
- A pristine copy of the tree (built via `git ls-files --cached --others --exclude-standard`, i.e. exactly what a clone would receive) builds and tests successfully from scratch with zero `stack.yaml.lock` drift, and the real working tree has no stray `.stack-work`, `.env`, or `.pem` files

## Task Commits

Each task was committed atomically:

1. **Task 1: Create the Stack + hpack project configuration and the library module, then prove `stack build` succeeds** - `6dc3107` (feat)
2. **Task 2: Add the tasty + QuickCheck smoke test-suite and prove `stack test` passes** - `58005a2` (test)
3. **Task 3: Prove the fresh-clone promise on a pristine copy of the tree** - no commit (verification-only task, no files created or modified)

**Plan metadata:** (pending — this commit)

## Files Created/Modified
- `stack.yaml` - Pins Stackage `lts-24.56` (GHC 9.10.3) by immutable snapshot URL; `extra-deps: []`
- `package.yaml` - hpack description: library in `src/`, `sarmiento-plugins-test` suite in `test/`, nine-flag `-Wall`-plus warning set, no executable
- `src/Sarmiento/Plugin.hs` - The library's only module; exports `pluginName :: String` and `pluginVersion :: String`
- `src/Education/README.md` - One-line placeholder; contributes no module to the build
- `test/Spec.hs` - `defaultMain` running one `testProperty`, importing `Sarmiento.Plugin`
- `sarmiento-plugins.cabal` - hpack-generated, tracked, never hand-edited
- `stack.yaml.lock` - Resolved snapshot pin; verified to show no drift on a clean-checkout build

## Decisions Made
- Fixed a self-contradiction in the plan's own template: the suggested `package.yaml` comment text mentioned "-Werror" (to say it wasn't used), but the plan's automated verify checks for zero occurrences of the substring "Werror" anywhere in the file, including comments. Reworded the comment to convey the same meaning ("no error-on-warning flag is set") without the literal string, so both the intent and the verification pass.
- No version bounds on `tasty`/`tasty-quickcheck`/`QuickCheck` — deliberately left to resolve from the snapshot, per the plan's explicit note, to avoid a second drift-prone source of truth alongside `stack.yaml.lock`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] package.yaml comment triggered its own "no Werror" verification check**
- **Found during:** Task 1, immediately after the first `stack build` and before running the full acceptance-criteria check
- **Issue:** The plan's suggested `package.yaml` content included the comment "No -Werror in this phase," but the plan's own automated verify command asserts `! grep -q 'Werror' package.yaml` — the comment's presence would make this specific check fail even though no `-Werror` flag was actually configured
- **Fix:** Reworded the comment to "Warnings do not fail the build in this phase (no error-on-warning flag is set)," preserving the documented intent without the literal substring
- **Files modified:** `package.yaml`
- **Verification:** Re-ran the full Task 1 acceptance check; all criteria including the `Werror` check passed; `stack build` re-run to confirm hpack regeneration was still clean (exit 0)
- **Committed in:** `6dc3107` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 bug in plan-supplied content vs. plan-supplied verification)
**Impact on plan:** Cosmetic fix to a comment string only; no functional, warning-set, or dependency change. No scope creep.

## Issues Encountered
None beyond the deviation above. GHC 9.10.3 was already available via `~/.ghcup` (not freshly downloaded by Stack), so both `stack build` and `stack test` completed in well under the 20-40 minute budget noted in the plan's environment section.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `stack.yaml`, `package.yaml`, the library module, and the test-suite are all in place and verified against a clone-equivalent pristine copy — Phase 2 (Dependency Wiring) can add git `extra-deps` entries to `stack.yaml` without re-deriving the snapshot pin
- `stack.yaml.lock` is committed and drift-free, ready for Phase 3's CI cache key
- No blockers identified for Phase 2 or Phase 3

---
*Phase: 01-scaffold*
*Completed: 2026-08-25*

## Self-Check: PASSED

All created files found on disk (stack.yaml, package.yaml, src/Sarmiento/Plugin.hs, src/Education/README.md, test/Spec.hs, sarmiento-plugins.cabal, stack.yaml.lock, SUMMARY.md) and both task commits (6dc3107, 58005a2) verified present in git log.
