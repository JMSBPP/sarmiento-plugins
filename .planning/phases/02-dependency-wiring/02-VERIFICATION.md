---
phase: 02-dependency-wiring
verified: 2026-08-25T21:13:57Z
status: passed
score: 6/6 must-haves verified
---

# Phase 2: Dependency Wiring Verification Report

**Phase Goal:** The project is wired to its three pinned upstream git extra-deps
(`mamertomics-etl`, `haskell-deepseek-plugin-sdk`, `kalecky-semantics`), each either
importable or documented as executable-only (or, as it turned out, library-present-but-empty),
with the pin/bump discipline recorded.
**Verified:** 2026-08-25T21:13:57Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `stack build` / `stack --lock-file error-on-write build` resolves all three pinned upstream git extra-deps and compiles the project end to end | ✓ VERIFIED | `stack --lock-file error-on-write build` run live, exit 0, compiled `Sarmiento.Plugin` and `Sarmiento.Upstream` |
| 2 | A module imports a real symbol from `kalecky-semantics` and from `mamertomics-etl`, so a broken dependency edge is a compile error | ✓ VERIFIED | `src/Sarmiento/Upstream.hs` contains `import Kalecky.Types.Units.Unit (Unit)` and `import qualified Lib`; `type UnitProof basis = Unit basis`; `etlEntryPoint = Lib.someFunc` — module compiled successfully in the live build |
| 3 | `stack test` passes, with a property whose subject is drawn from the proof module (broken edge = compile error, not silent pass) | ✓ VERIFIED | `stack test` run live: `All 2 tests passed`; `test/Spec.hs` imports `Sarmiento.Upstream (upstreamProofTag)` and uses it in `prop_upstreamLinked` |
| 4 | Every extra-dep is pinned by a 40-character commit SHA; no `branch:` key anywhere in `stack.yaml` | ✓ VERIFIED | `grep -cE '^  commit: [0-9a-f]{40}$' stack.yaml` → `3`; `grep -E '^[[:space:]]*branch:' stack.yaml` → no matches |
| 5 | `haskell-deepseek-plugin-sdk` is pinned in `stack.yaml` `extra-deps:` and absent from `package.yaml` `dependencies:`, with the reason documented (updated: empty-stub library, not S-4804) rather than the plan's stale literal | ✓ VERIFIED | `stack.yaml` extra-dep present with commit `242ebfa05acd318326aea7f35508d7d4c1bbdbfa`; `package.yaml` contains no `haskell-deepseek-plugin-sdk` dependency line; README/CHANGELOG both document the empirically-verified "library stanza with 7 empty-export stub modules, no importable symbol" reason instead of the plan's obsolete "executable-only"/S-4804 framing |
| 6 | No local dimensional/unit type is declared; the guard script enforces this and the pin/bump discipline is recorded in README | ✓ VERIFIED | `./scripts/check-no-local-dimensional-types.sh` → `no-local-dimensional-types: OK`; README's "Pin and bump discipline" section states "never track a branch" with the mechanical `pantry-tree` reason and a numbered 7-step bump procedure ending in `stack --lock-file error-on-write build` |

**Score:** 6/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `stack.yaml` | Three git extra-deps pinned by commit SHA | ✓ VERIFIED | 3 `commit:` lines, all 40-hex, no `branch:`, HTTPS URLs only |
| `stack.yaml.lock` | Pantry-resolved lock for all three git extra-deps plus the snapshot | ✓ VERIFIED | `pantry-tree` count = 3, `commit:` count = 6; tracked in git (`git ls-files` confirms) |
| `package.yaml` | Library dependencies on the two upstreams exposing a library | ✓ VERIFIED | `- kalecky-semantics` and `- mamertomics-etl` present; SDK absent, with an up-to-date comment explaining why |
| `src/Sarmiento/Upstream.hs` | Compile-time proof-of-import module for both library extra-deps | ✓ VERIFIED | Exports `UnitProof`, `etlEntryPoint`, `upstreamProofTag`; imports `Kalecky.Types.Units.Unit` and `Lib`; compiled cleanly in live build |
| `scripts/check-no-local-dimensional-types.sh` | Automated negative check for DEPS-02's "no local dimensional types" clause | ✓ VERIFIED | Executable, exits 0 on tree; per SUMMARY, demonstrated RED against a planted probe during execution |
| `.planning/phases/02-dependency-wiring/02-VALIDATION.md` | Filled-in Nyquist validation contract for Phase 2 | ✓ VERIFIED | `nyquist_compliant: true`, `wave_0_complete: true`, per-task verification map, sign-off checklist all present |
| `README.md` | Dependency table (owner, visibility, pinned commit, why), pin/bump discipline, bump procedure, SDK note | ✓ VERIFIED | 169 lines; all three table rows present with correct visibility and SHAs matching `stack.yaml` byte-for-byte; "never track a branch" and 7-step bump procedure present; SDK note updated past the plan's stale "executable-only" framing to the empirically-verified "empty-stub library" framing |
| `CHANGELOG.md` | Unreleased entries recording the Phase 2 wiring | ✓ VERIFIED | 42 lines; `### Added` records extra-deps, package.yaml deps, proof module, guard script, README table; `### Fixed` records the visibility correction; Phase 1 bullets preserved |
| `test/Spec.hs` | Test-suite compile-linked through both dependency edges | ✓ VERIFIED | Imports `Sarmiento.Upstream (upstreamProofTag)`; `stack test` → `All 2 tests passed` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `stack.yaml` | Three upstream GitHub repos | `git:`/`commit:` pairs pinned by SHA | ✓ WIRED | Pattern `^  commit: [0-9a-f]{40}$` matches 3 times; each `git:` URL is HTTPS, no `git@github.com` in an actual `git:` value line |
| `package.yaml` | `kalecky-semantics` and `mamertomics-etl` | library dependencies list | ✓ WIRED | `^- kalecky-semantics$` and `^- mamertomics-etl$` both present |
| `src/Sarmiento/Upstream.hs` | `Kalecky.Types.Units.Unit.Unit` | explicit import | ✓ WIRED | `import Kalecky.Types.Units.Unit (Unit)`; compiles live |
| `src/Sarmiento/Upstream.hs` | `Lib` (mamertomics-etl) | qualified import used by `etlEntryPoint` | ✓ WIRED | `import qualified Lib`; `etlEntryPoint = Lib.someFunc`; compiles live |
| `test/Spec.hs` | `src/Sarmiento/Upstream.hs` | import that compile-links the test-suite through both edges | ✓ WIRED | `import Sarmiento.Upstream (upstreamProofTag)`; used in `prop_upstreamLinked`; `stack test` green |
| `README.md` dependency table | `stack.yaml` extra-deps pins | same 40-character SHA in both files | ✓ WIRED | All three SHAs cross-checked byte-for-byte between `stack.yaml` and README table rows |
| `README.md` bump procedure | Phase 3 CI-03 drift check | documented final step is the same command | ✓ WIRED | README step 5 is literally `stack --lock-file error-on-write build` |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| DEPS-01 | 02-01 | `stack.yaml` declares git extra-deps pinned by commit for `mamertomics-etl` (private) and `haskell-deepseek-plugin-sdk` (public); `stack.yaml.lock` committed | ✓ SATISFIED | Both pinned by 40-hex commit; `stack.yaml.lock` is tracked in git and regenerated; `stack --lock-file error-on-write build` exits 0 |
| DEPS-02 | 02-01 | `kalecky-semantics` pinned as extra-dep, `package.yaml` depends on it, `Kalecky.Types.*` importable, no local dimensional types | ✓ SATISFIED | Pinned in `stack.yaml`, `- kalecky-semantics` in `package.yaml`, `Kalecky.Types.Units.Unit` imported and compiled, guard script exits 0 |
| DEPS-03 | 02-02 | Each extra-dep's role and the "bump deliberately, never track a branch" rule documented in README (table with owner, visibility, pinned commit, why) | ✓ SATISFIED | README table has all 4 columns for all 3 repos; discipline section and 7-step bump procedure present |
| DEPS-04 | 02-01, 02-02 | Compile-time proof that all three deps resolve: a module importing a symbol from each that has one; for the stub, a documented note; build must succeed | ✓ SATISFIED | `Sarmiento.Upstream` imports from `Kalecky.*` and `Lib`; SDK's empty-stub-library status is documented (superseding the plan's stale "executable-only" framing, per instructed deviation acceptance); `stack build` and `stack --lock-file error-on-write build` both exit 0 |

No orphaned requirements — REQUIREMENTS.md maps exactly DEPS-01 through DEPS-04 to Phase 2, and both plans together declare all four in their `requirements:` frontmatter.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | none found | — | `grep -n -E "TODO|FIXME|XXX|HACK|PLACEHOLDER"` across `src/Sarmiento/Upstream.hs`, `test/Spec.hs`, `stack.yaml`, `package.yaml`, `scripts/check-no-local-dimensional-types.sh` returned no hits. The one match for the word "placeholder" is inside `test/Spec.hs`'s Haddock comment, describing what the test suite deliberately is *not* ("instead of a placeholder that passes vacuously") — a deliberate contrast, not a stub marker. |

### Human Verification Required

None. All must-haves are compile-time or grep-verifiable and were exercised live in this
verification pass (`stack --lock-file error-on-write build`, `stack test`,
`scripts/check-no-local-dimensional-types.sh`, and byte-for-byte SHA cross-checks between
`stack.yaml` and `README.md`).

### Deviation Note (per verification instructions)

The plan's literal acceptance-criteria strings `S-4804` and `executable-only` for the SDK are
obsolete: `haskell-deepseek-plugin-sdk`'s live HEAD moved during execution
(`21d7ac43…` → `242ebfa05acd318326aea7f35508d7d4c1bbdbfa`) and gained a `library` stanza whose
7 exposed modules are all empty stubs. Both SUMMARYs document this and both README.md and
CHANGELOG.md were empirically re-verified (by temporarily wiring the SDK into `package.yaml`
and confirming it builds without S-4804) before writing the corrected claim: "no importable
symbol at this pin" rather than "executable-only, no library." This verification judges the
intent — an honest, provable claim about the SDK's non-wiring — met, not the stale literal
strings.

### Live Pin-Drift Check (informational only)

| Repository | Pinned SHA | Live `HEAD` SHA (checked at verification time) | Drift? |
|---|---|---|---|
| `JMSBPP/kalecky-semantics` | `cd6778e2d39c5eb30549d8ff87459b5644cc18fc` | `cd6778e2d39c5eb30549d8ff87459b5644cc18fc` | No |
| `JMSBPP/mamertomics-etl` | `c8b45ac159553017df82c4258af3d2bf68b5f62e` | `c8b45ac159553017df82c4258af3d2bf68b5f62e` | No |
| `d2p-finance/haskell-deepseek-plugin-sdk` | `242ebfa05acd318326aea7f35508d7d4c1bbdbfa` | `e55128754d02229956ed2f015cf0754ea445dad3` | **Yes** — pins are deliberate, per the bump-discipline design; this is expected drift, not a defect, and is left for a future deliberate bump per the documented 7-step procedure. |

### CI Scope Check

`test -d .github` → does not exist. Confirmed no CI files were created in this phase, which
is correctly deferred to Phase 3.

### Gaps Summary

None. All six derived must-have truths, all nine required artifacts, all seven key links, and
all four requirement IDs (DEPS-01 through DEPS-04) are verified against the live codebase, not
merely against SUMMARY claims. `stack --lock-file error-on-write build`, `stack test`, and
`scripts/check-no-local-dimensional-types.sh` were all executed live during this verification
and all passed. The one deliberate deviation from the plan's literal wording (SDK's
"executable-only"/`S-4804` framing superseded by the empirically-verified "empty-stub
library" framing) is documented in both SUMMARYs and correctly propagated into README.md and
CHANGELOG.md, and was accepted per this verification's explicit instructions.

---

_Verified: 2026-08-25T21:13:57Z_
_Verifier: Claude (gsd-verifier)_
