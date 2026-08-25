# Requirements: sarmiento-plugins

**Defined:** 2026-08-25
**Core Value:** A Sarmiento claim goes in, a dimensionally-typed Kaleckian shock grounded in real `mamertomics-db` data comes out — through the harness plugin protocol, with every number carrying provenance and units. (v1 lays the foundation: a buildable, CI-verified Stack project wired to its upstreams; the translation itself is v2, gated on those upstreams.)

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Scaffold

- [ ] **SCAF-01**: Developer can run `stack build` on a fresh clone of `JMSBPP/sarmiento-plugins` (hpack `package.yaml`, library + test-suite skeleton, `-Wall` warnings set matching sibling repos) on snapshot **lts-24.56** (GHC 9.10.3)
- [ ] **SCAF-02**: Repo has a `src/Education/README.md` placeholder (one-line stub; purpose decided later) and the module tree compiles with it present
- [ ] **SCAF-03**: Repo has `README.md` stating what the plugin is, its upstreams, how to build, and `.gitignore` excluding `.stack-work/`, `.env`, credentials
- [ ] **SCAF-04**: `stack test` runs a minimal tasty + QuickCheck suite (smoke test) so the CI test job is non-trivial from day one

### Dependencies

- [ ] **DEPS-01**: `stack.yaml` declares git extra-deps pinned by commit for `JMSBPP/mamertomics-etl` (private) and `d2p-finance/haskell-deepseek-plugin-sdk` (public); `stack.yaml.lock` committed
- [ ] **DEPS-02**: `stack.yaml` declares `JMSBPP/kalecky-semantics` (now a plain Stack project) as a pinned git extra-dep, and `package.yaml` depends on `kalecky-semantics` so `Kalecky.Types.*` are importable — no local dimensional types are defined
- [ ] **DEPS-03**: Each extra-dep's role and the "bump deliberately, never track a branch" rule are documented in README (dependency table with owner, visibility, pinned commit, why)
- [ ] **DEPS-04**: A compile-time proof that all three deps resolve: a module importing at least one symbol from each (or, for stubs with no library, a documented note that the dep is executable-only until upstream exposes a library — the build must still succeed)

### CI

- [ ] **CI-01**: GitHub Actions workflow on `push`/`pull_request` runs `stack build --test --no-run-tests` then `stack test` on ubuntu, with Stack + `~/.stack` caching keyed on `stack.yaml.lock`
- [ ] **CI-02**: CI can fetch the private `JMSBPP/mamertomics-etl` extra-dep via a scoped token injected through `git config url.insteadOf` (token in repo secrets, never in files); public `d2p-finance` dep fetches without auth
- [ ] **CI-03**: CI fails loudly if `stack.yaml.lock` is out of date with `stack.yaml` (no silent re-resolution)
- [ ] **CI-04**: A green CI run exists on `main` after the scaffold lands (observable in `gh run list`)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap. All are gated on upstream repos exposing real APIs (`haskell-deepseek-plugin-sdk` library, `mamertomics-etl` read surface, `kalecky-semantics` KaleckianKernel).

### Protocol

- **PROT-01**: Plugin drives a dedicated DeepSeek Harness child runtime as a JSON-RPC line-transport **client** (`initialize`, `session/prompt`, `session.event`, `shutdown`), via the SDK's client library
- **PROT-02**: Process lifecycle: spawn → handshake → run → stdin-EOF → SIGTERM → SIGKILL ladder; no wire cancel — settle locally as `aborted`
- **PROT-03**: stdout carries protocol lines only; logs to stderr; line-buffered handles
- **PROT-04**: Scripted fake harness runtime for keyless protocol tests

### Claim / Shock formats

- **FMT-01**: Closed claim ADT + JSON codec; claim classes decided from `src/Education/` notes (candidates: markup/distribution, demand-regime, external-constraint, productive-structure)
- **FMT-02**: Closed shock ADT + JSON codec with `kalecky` units, `value/value_low/value_high` band, `is_assumed`, structured provenance (`source_observation_ids`, `derivation_note`)
- **FMT-03**: Ungrounded/unsupported claim → typed rejection, never a best-effort number
- **FMT-04**: Codec round-trip and dimensional/sign property tests

### Data grounding

- **DATA-01**: Shock magnitudes read from `mamertomics-db` through `mamertomics-etl`'s read API (session-mode pooler, DSN via env) — blocked until that API exists
- **DATA-02**: Claim → data-query traceability recorded in the shock's provenance

### Formalization

- **FORM-01**: Sarmiento claims expressed as an instance of `kalecky-semantics`' `KaleckianKernel` (consumed from its API docs, not implemented here)
- **FORM-02**: LaTeX/markdown artefact documenting math ↔ type correspondence per claim class

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Implementing `KaleckianKernel` | Owned by `JMSBPP/kalecky-semantics`; this project only reads its API docs (user decision 2026-08-25) |
| Solving the Kaleckian model | Monorepo GAMS bridge owns solving; plugin emits shocks only |
| Ingesting / transforming source data | `mamertomics-etl` owns fetch/parse/load |
| Writing the SDK's library API here | Evolves upstream at `d2p-finance`; we sync |
| In-process Cordis/TypeScript plugin | Constraint: Haskell over JSON-RPC |
| Any local dimensional/unit types | "No third dimensional system" — `kalecky` only |
| Bespoke wire cancel, session pooling, streaming intermediate steps | Fight the harness's documented seam contract |
| Countries other than Colombia | No grounded data; kernel genericity is `kalecky-semantics` scope |
| Web UI / CLI beyond run/test | Not needed |
| Querying live Supabase before the ETL read API exists | User decision: wait for the ETL API |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SCAF-01 | Phase 1 | Pending |
| SCAF-02 | Phase 1 | Pending |
| SCAF-03 | Phase 1 | Pending |
| SCAF-04 | Phase 1 | Pending |
| DEPS-01 | Phase 2 | Pending |
| DEPS-02 | Phase 2 | Pending |
| DEPS-03 | Phase 2 | Pending |
| DEPS-04 | Phase 2 | Pending |
| CI-01 | Phase 3 | Pending |
| CI-02 | Phase 3 | Pending |
| CI-03 | Phase 3 | Pending |
| CI-04 | Phase 3 | Pending |

**Coverage:**
- v1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0 ✓

---
*Requirements defined: 2026-08-25*
*Last updated: 2026-08-25 after roadmap creation (3 phases: Scaffold, Dependency Wiring, CI)*
