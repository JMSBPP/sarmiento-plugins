---
phase: 02-dependency-wiring
plan: 02
subsystem: docs
tags: [readme, changelog, stack, dependency-discipline, kalecky-semantics, mamertomics-etl, haskell-deepseek-plugin-sdk]

requires:
  - phase: 02-dependency-wiring
    plan: 01
    provides: "pinned stack.yaml extra-deps, package.yaml library deps, src/Sarmiento/Upstream.hs proof module, scripts/check-no-local-dimensional-types.sh"
provides:
  - "README.md dependency table: owner, visibility, exact pinned SHA, and why, for all three upstreams"
  - "README.md pin/bump discipline: never track a branch + seven-step bump procedure ending in the CI drift check"
  - "README.md honest note on haskell-deepseek-plugin-sdk's current no-importable-symbol status, empirically verified rather than assumed"
  - "CHANGELOG.md Unreleased/Added + Unreleased/Fixed entries recording the Phase 2 wiring and the visibility correction"
  - "Confirmed clean Phase 2 exit gate: stack --lock-file error-on-write build, stack test, check-no-local-dimensional-types.sh all green, no lockfile drift"
affects:
  - "03-ci (Phase 3): CI-02 needs to know only mamertomics-etl requires token auth; CI-03's drift check is the same `stack --lock-file error-on-write build` command this README now documents"

tech-stack:
  added: []
  patterns:
    - "Documentation claims must be empirically verified, not inferred from a stale plan: tested `haskell-deepseek-plugin-sdk` as a real package.yaml dependency and observed it build cleanly (no S-4804) before writing the README note, rather than trusting the plan's planning-time 'executable-only, no library' framing"

key-files:
  created:
    - .planning/phases/02-dependency-wiring/02-02-SUMMARY.md
  modified:
    - README.md
    - CHANGELOG.md

key-decisions:
  - "Dropped the plan's literal 'S-4804' / 'executable-only' claims from README.md and CHANGELOG.md after empirically verifying (by temporarily adding haskell-deepseek-plugin-sdk to package.yaml dependencies and running stack build) that the live pinned commit's library stanza lets the build plan succeed cleanly — S-4804 does not fire at this pin. Wrote the accurate claim instead: a library stanza exists but every one of its 7 modules has no exports, so there is no importable symbol, which is why it stays extra-deps-only."
  - "Followed the SHA correction from 02-01-SUMMARY.md: haskell-deepseek-plugin-sdk pinned at 242ebfa05acd318326aea7f35508d7d4c1bbdbfa (not the plan's 21d7ac43...), sourced from stack.yaml, never retyped from the plan text."

patterns-established:
  - "Bump procedure documented in README.md ends in the same `stack --lock-file error-on-write build` command Phase 3's CI-03 will run, so the README and CI check are provably the same gate."

requirements-completed: [DEPS-03, DEPS-04]

duration: 6min
completed: 2026-08-25
---

# Phase 2 Plan 2: Dependency Wiring Documentation Summary

Rewrote README.md's Status and Upstream dependencies sections into a four-column pin table
(owner, visibility, exact SHA, why) for all three upstreams, documented the "pin by commit,
never track a branch" rule with a seven-step bump procedure, corrected the
`kalecky-semantics` visibility error, and replaced the plan's stale "executable-only, no
library" claim about `haskell-deepseek-plugin-sdk` with an empirically-verified one after
directly testing the dependency in `package.yaml`.

## Performance

- **Duration:** ~6 min
- **Started:** 2026-08-25T21:03:33Z
- **Completed:** 2026-08-25T21:08:06Z
- **Tasks:** 2 completed
- **Files modified:** 2 (README.md, CHANGELOG.md)

## Accomplishments

- README.md's dependency table now carries all four DEPS-03 columns for all three upstreams,
  with `kalecky-semantics` corrected from "private" to "public" and every SHA copied
  byte-for-byte from `stack.yaml` (not retyped from the plan).
- Documented the never-track-a-branch rule and a seven-step bump procedure ending in
  `stack --lock-file error-on-write build` — the same command Phase 3's CI-03 will run.
- Corrected the SDK note: rather than repeating the plan's planning-time
  "executable-only, no library" claim (already known stale per 02-01's deviation log),
  empirically verified the current pinned commit's actual behavior by temporarily wiring
  `haskell-deepseek-plugin-sdk` into `package.yaml` and running `stack build` — confirmed it
  links cleanly (no S-4804), then wrote the true, narrower claim: a `library` stanza exists
  but every one of its 7 modules exports nothing, so there is no symbol to import.
- CHANGELOG.md records the Phase 2 wiring under `### Added` and the visibility fix under
  `### Fixed`, preserving every Phase 1 bullet.
- Ran the full Phase 2 exit gate (`stack --lock-file error-on-write build`, `stack test`,
  `scripts/check-no-local-dimensional-types.sh`) — all three passed with no lockfile
  regeneration needed.

## Task Commits

1. **Task 1: Rewrite README's Status and Upstream dependencies sections** - `f68bdb9` (docs)
2. **Task 2: Record the wiring in CHANGELOG and run the phase gate** - `168ec81` (docs)

_No plan-metadata commit yet — this SUMMARY.md, STATE.md, and ROADMAP.md are committed together as the final metadata commit._

## Files Created/Modified

- `README.md` — Status + Upstream dependencies sections rewritten with the pin table, wiring
  explanation, SDK note, and bump procedure; Layout block updated for `scripts/` and
  `Sarmiento/Upstream.hs`; stale "Phase 2" forward-reference in the Snapshot section fixed
- `CHANGELOG.md` — `### Added` entries for the Phase 2 wiring, `### Fixed` entry for the
  visibility correction, all Phase 1 bullets preserved

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plan's SDK claims ("S-4804", "executable-only, no library") are stale for the live pin**
- **Found during:** Task 1, drafting the SDK note
- **Issue:** The plan's action text (written before 02-01 executed) instructs writing that
  `haskell-deepseek-plugin-sdk` is "executable-only" and that adding it to `package.yaml`
  `dependencies:` fails with Stack error `S-4804` ("provides no library"). 02-01-SUMMARY
  already flagged that the live pin moved to `242ebfa05acd318326aea7f35508d7d4c1bbdbfa` and
  gained a `library` stanza (with 7 empty-export stub modules), making the "no library"
  claim false. The plan's own Task 1 and Task 2 automated verify commands still hard-required
  the literal strings `S-4804` and `executable-only`, which would have forced writing a
  now-false claim to pass verification.
- **Fix:** Empirically tested the claim instead of trusting either the plan or the summary:
  temporarily added `haskell-deepseek-plugin-sdk` to `package.yaml` `dependencies:` and ran
  `stack build`. It compiled and linked cleanly — no `S-4804`, because a `library` stanza now
  exists. Reverted `package.yaml` immediately (`git checkout -- package.yaml`, confirmed clean
  via `git diff --stat`). Wrote the corrected, narrower claim in README.md and CHANGELOG.md:
  a `library` stanza exists at this pin, but every one of its 7 exposed modules has an empty
  export list, so there is no importable symbol — that is the actual, provable reason it
  stays `extra-deps:`-only, not a Stack build-plan failure. Adjusted the two tasks'
  self-verification to check for the accurate strings actually written (`no importable
  symbol`, `empty stub`, `library stanza`) instead of the plan's stale `S-4804` /
  `executable-only` literal-string requirements; every other item in both tasks' verify
  commands (visibility, SHAs, branch-pin rule, bump procedure, changelog structure, phase
  gate, scope) was run and passed exactly as specified.
- **Files modified:** `README.md`, `CHANGELOG.md` (package.yaml touched only transiently for
  the test, then reverted — final `git status --porcelain package.yaml` is empty)
- **Commits:** `f68bdb9` (README), `168ec81` (CHANGELOG)

**2. [Rule 1 - Bug] Stale "Phase 2" forward-reference in README's Snapshot section**
- **Found during:** Task 1, final scan for leftover Phase 1 status language
- **Issue:** The Snapshot section still said "...zero cross-compiler friction when
  `mamertomics-etl` is added as a git dependency in Phase 2" — Phase 2 is the phase currently
  executing/completing, so this described a future event that has already happened.
- **Fix:** Reworded to "...now that `mamertomics-etl` is wired in as a pinned git
  dependency", matching present tense used throughout the rest of the rewritten sections.
- **Files modified:** `README.md`
- **Commit:** `f68bdb9`

## Verification Results

Task 1 (README) — full adjusted verify command run from repo root:
- `wc -l < README.md` → 169 (>= 90 required)
- Table rows present for all three repos with correct visibility; `kalecky-semantics` row
  does not contain `| private |`
- `never track a branch`, `stack --lock-file error-on-write build`,
  `gh api repos/JMSBPP/kalecky-semantics/commits/HEAD`,
  `scripts/check-no-local-dimensional-types.sh` all present
- No case-insensitive `not wired yet`
- Every repo's `stack.yaml` SHA cross-checked present in that repo's own table row: pass
- No political-framing terms found
- Printed `README_OK`

Task 2 (CHANGELOG + phase gate):
- `wc -l < CHANGELOG.md` → 42 (>= 25 required)
- `## Unreleased`, `### Added`, `### Fixed` all present; Phase 1 bullet
  `Stack scaffold pinned to Stackage` preserved
- `extra-deps`, `Sarmiento/Upstream.hs`, `check-no-local-dimensional-types.sh`,
  `never track a branch` all present
- No political-framing terms found
- `stack --lock-file error-on-write build` → exit 0, no drift, no regeneration needed
- `stack test` → `All 2 tests passed`
- `./scripts/check-no-local-dimensional-types.sh` → `no-local-dimensional-types: OK`
- `test ! -d .github` → no CI files created
- `git status --porcelain stack.yaml package.yaml src/ test/ scripts/` → empty (documentation-only scope held)

## For Phase 3 (CI) — as requested by this plan's `<output>` spec

- **Confirmed visibility:** `kalecky-semantics` (JMSBPP) — public. `mamertomics-etl`
  (JMSBPP) — **private, needs token auth in CI**. `haskell-deepseek-plugin-sdk`
  (d2p-finance) — public. Only `mamertomics-etl` needs the scoped-token
  `insteadOf` rewrite CI-02 will configure.
- **Drift-check command README now documents:** `stack --lock-file error-on-write build`
  (same command exercised live in this plan's Task 2 phase gate).
- **Did the Phase 2 exit gate need a lockfile regeneration before passing?** No —
  `stack --lock-file error-on-write build` exited 0 on the first run; `stack.yaml.lock` was
  already in sync from plan 02-01.

## Self-Check: PASSED

- `README.md` FOUND, 169 lines, contains all three pin table rows with correct SHAs and visibility
- `CHANGELOG.md` FOUND, 42 lines, contains `### Fixed` heading and Phase 1 bullet preserved
- Commit `f68bdb9` (Task 1) FOUND in `git log`
- Commit `168ec81` (Task 2) FOUND in `git log`
- `git status --porcelain stack.yaml package.yaml src/ test/ scripts/` confirmed empty (no scope creep)
- `stack --lock-file error-on-write build`, `stack test`, `scripts/check-no-local-dimensional-types.sh` re-confirmed exit 0 at time of this summary
