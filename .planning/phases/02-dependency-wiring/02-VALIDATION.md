---
phase: 2
slug: dependency-wiring
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-25
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | tasty 1.5.4 + tasty-quickcheck 0.11.1 + QuickCheck 2.15.0.1 (wired in Phase 1); Stack 3.11.1 / GHC 9.10.3 as the compile-time oracle |
| **Config file** | `package.yaml` → `tests.sarmiento-plugins-test` |
| **Quick run command** | `stack build` |
| **Full suite command** | `stack --lock-file error-on-write build && stack test && ./scripts/check-no-local-dimensional-types.sh` |
| **Estimated runtime** | < 2 s warm (all extra-deps precompiled); several minutes cold on first extra-dep fetch |

Phase 2 is a wiring phase, so most of its verification is **compile-time**: the proof module
either compiles against the pinned extra-deps or it does not. A red build, not a red test, is
the failure signal for DEPS-01/02/04.

---

## Sampling Rate

- **After every task commit:** `stack build` (incremental; sub-second once deps are cached)
- **After every plan wave:** `stack --lock-file error-on-write build && stack test && ./scripts/check-no-local-dimensional-types.sh`
- **Before `/gsd:verify-work`:** the full suite command above must be green
- **Max feedback latency:** 2 s warm

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 2-01-01 | 01 | 1 | DEPS-02 | guard script | `./scripts/check-no-local-dimensional-types.sh` | ✅ (created by this task — Wave 0) | ⬜ pending |
| 2-01-02 | 01 | 1 | DEPS-01, DEPS-02 | build/config | `stack --lock-file error-on-write build` | ✅ | ⬜ pending |
| 2-01-03 | 01 | 1 | DEPS-02, DEPS-04 | compile + unit | `stack test && ./scripts/check-no-local-dimensional-types.sh` | ✅ | ⬜ pending |
| 2-02-01 | 02 | 2 | DEPS-03, DEPS-04 | doc grep vs. `stack.yaml` | README pin/visibility cross-check script (see 02-02-PLAN.md Task 1 verify) | ✅ | ⬜ pending |
| 2-02-02 | 02 | 2 | DEPS-03 | doc grep + phase gate | `stack --lock-file error-on-write build && stack test` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

No three consecutive tasks lack an automated verify: every task above has one.

---

## Wave 0 Requirements

- [x] `scripts/check-no-local-dimensional-types.sh` — automates DEPS-02's "no local
      dimensional types are defined" clause, which was manual-review-only before this phase
      (02-RESEARCH.md Wave 0 Gap 1). Created by task 2-01-01, i.e. *before* the proof module
      that first legitimately imports from `Kalecky.*`.

02-RESEARCH.md's Wave 0 Gap 2 ("no test exercises `stack --lock-file error-on-write build`")
is closed by wiring that exact command into the wave-merge and phase-gate sampling above,
rather than into `stack test` — it is a Stack invocation, not a Haskell test, and Phase 3's
CI-03 automates it on every push.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| README dependency table is accurate and readable prose | DEPS-03 | Documentation quality is not machine-checkable; the *facts* in it are | Read the table; the automated cross-check in 02-02-PLAN.md Task 1 already asserts owner, visibility, and that each pinned SHA in README matches `stack.yaml` byte-for-byte |
| `haskell-deepseek-plugin-sdk` executable-only note is honest | DEPS-04 | The claim's strength is a judgement call | Confirm the note claims only what is provable today: the pinned commit exists, its `.cabal` parses, and `stack build` succeeds with it declared — **not** that it compiles or is importable |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 2s (warm)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-08-25
