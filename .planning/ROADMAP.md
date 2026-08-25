# Roadmap: sarmiento-plugins

## Overview

v1 lays the foundation only: a buildable, CI-verified Haskell Stack project wired to its three upstream dependencies (`mamertomics-etl`, `haskell-deepseek-plugin-sdk`, `kalecky-semantics`). The claim/shock translation, protocol adapter, and data grounding are all v2, deferred until those upstreams expose real APIs. The journey is Scaffold (a fresh clone builds and tests) → Dependency Wiring (the three pinned git extra-deps resolve and are importable) → CI (every push/PR is automatically verified, including the private-repo auth path), ending with a green run on `main`.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Scaffold** - Fresh clone builds and tests on the pinned snapshot with baseline project structure (completed 2026-08-25)
- [ ] **Phase 2: Dependency Wiring** - The three pinned upstream git extra-deps resolve and are provably importable
- [ ] **Phase 3: CI** - Every push/PR is automatically build-and-test verified, including private-repo auth, with a green run on `main`

## Phase Details

### Phase 1: Scaffold
**Goal**: A developer can clone `JMSBPP/sarmiento-plugins` and get a building, testable Haskell project on the first try — no dependency wiring or CI yet, just the skeleton.
**Depends on**: Nothing (first phase)
**Requirements**: SCAF-01, SCAF-02, SCAF-03, SCAF-04
**Success Criteria** (what must be TRUE):
  1. Developer can run `stack build` on a fresh clone on snapshot lts-24.56 (GHC 9.10.3), with hpack `package.yaml` producing a library + test-suite skeleton and `-Wall` warnings matching sibling repos
  2. `src/Education/README.md` exists as a one-line placeholder stub and the module tree compiles with it present
  3. `README.md` states what the plugin is, its upstreams, and how to build; `.gitignore` excludes `.stack-work/`, `.env`, and credentials
  4. `stack test` runs a minimal tasty + QuickCheck smoke suite successfully, so the CI test job will be non-trivial from day one
**Plans**: 2 plans

Plans:
- [ ] 01-01-PLAN.md — Repo hygiene and documentation: `.gitignore` (build artefacts + credentials), `README.md` (what the plugin is, upstream table, build/test), `CHANGELOG.md` — SCAF-03
- [ ] 01-02-PLAN.md — Buildable Stack project on lts-24.56: `stack.yaml` snapshot pin, hpack `package.yaml` (library + test-suite, sibling warning set), `Sarmiento.Plugin` module, `src/Education/` placeholder, tasty + QuickCheck smoke suite, fresh-clone build proof — SCAF-01, SCAF-02, SCAF-04

### Phase 2: Dependency Wiring
**Goal**: The project is wired to its three pinned upstream git extra-deps (`mamertomics-etl`, `haskell-deepseek-plugin-sdk`, `kalecky-semantics`), each either importable or documented as executable-only, with the pin/bump discipline recorded.
**Depends on**: Phase 1
**Requirements**: DEPS-01, DEPS-02, DEPS-03, DEPS-04
**Success Criteria** (what must be TRUE):
  1. `stack.yaml` declares git extra-deps pinned by commit for `JMSBPP/mamertomics-etl` (private) and `d2p-finance/haskell-deepseek-plugin-sdk` (public); `stack.yaml.lock` is committed
  2. `stack.yaml` declares `JMSBPP/kalecky-semantics` as a pinned git extra-dep and `package.yaml` depends on it so `Kalecky.Types.*` are importable — no local dimensional types are defined anywhere in the project
  3. README documents each dependency's role in a table (owner, visibility, pinned commit, why), stating the "bump deliberately, never track a branch" rule
  4. A module compiles importing at least one symbol from each of the three deps — or, for a dep with no library surface yet, a documented note explains it is executable-only until upstream exposes one; either way `stack build` succeeds end to end
**Plans**: 2 plans

Plans:
- [ ] 02-01-PLAN.md — Pin the three upstream git extra-deps by commit, depend on the two that expose a library, and prove the wiring with a compile-time import module plus a no-local-dimensional-types guard — DEPS-01, DEPS-02, DEPS-04
- [ ] 02-02-PLAN.md — Document the dependency contract in README (owner, visibility, pinned commit, why), the never-track-a-branch rule and bump procedure, and the SDK's executable-only note; record it in CHANGELOG — DEPS-03, DEPS-04

### Phase 3: CI
**Goal**: Every push and pull request to the private GitHub repo is automatically verified by build + test, including fetching the private extra-dep via a scoped token, with a green run observable on `main`.
**Depends on**: Phase 2
**Requirements**: CI-01, CI-02, CI-03, CI-04
**Success Criteria** (what must be TRUE):
  1. A GitHub Actions workflow runs `stack build --test --no-run-tests` then `stack test` on ubuntu for `push`/`pull_request`, with Stack + `~/.stack` caching keyed on `stack.yaml.lock`
  2. CI fetches the private `JMSBPP/mamertomics-etl` extra-dep via a scoped token injected through `git config url.insteadOf` (token stored only in repo secrets); the public `d2p-finance` dep fetches without auth
  3. CI fails loudly (not silently re-resolving) if `stack.yaml.lock` is out of date with `stack.yaml`
  4. A green CI run exists on `main` after the scaffold lands, observable via `gh run list`
**Plans**: TBD

Plans:
- [ ] 03-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Scaffold | 2/2 | Complete    | 2026-08-25 |
| 2. Dependency Wiring | 0/2 | Not started | - |
| 3. CI | 0/TBD | Not started | - |
