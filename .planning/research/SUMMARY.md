# Project Research Summary

**Project:** sarmiento-plugins
**Domain:** Haskell out-of-process DeepSeek Harness (Cordis) contained-agent plugin — translates Eduardo Sarmiento's Colombian structuralist/Post-Keynesian claims into typed Kaleckian macro shocks, grounded in `mamertomics-db` (Supabase Postgres) via a sibling ETL package
**Researched:** 2026-08-25
**Confidence:** MEDIUM-HIGH

## Executive Summary

This is a small, tightly-scoped Haskell program that sits between three larger systems it does not own: the DeepSeek Harness (a TypeScript/Cordis agent runtime, developer preview), a Postgres staging schema owned by the sibling `mamertomics-etl` project, and the GAMS-based Kaleckian solver owned by `mamertomics-monorepo`. Its entire job is the middle step — turn a structuralist claim into a typed, provenance-carrying, dimensionally-honest shock — and explicitly *not* the steps on either side (it neither runs inside the harness as a native Cordis plugin, nor solves the model, nor re-ingests source data). Direct evidence from the harness's own source confirms the Haskell process is a JSON-RPC **client**, not a server or literal harness "child": it spawns and drives its own dedicated child harness process (its own `cordis.yml`) through a bounded `initialize -> session/prompt -> drain session.event` exchange, the same role `@deepseek-ai/dsh-sdk-client` plays in TypeScript. The recommended stack is Stack 3.11.1 / GHC 9.10.3 on Stackage `lts-24.56` (matching `mamertomics-etl` exactly), `hasql`/`hasql-pool` against Supabase's session-mode Supavisor pooler, `json-rpc` plus a ~20-line hand-written newline-delimited line transport (no LSP-style framing, no cancel method exists on the wire), and `autodocodec` for schema-as-byproduct claim/shock codecs.

The central risk this research surfaces, repeated independently across all four research files, is that **two of the three upstream dependencies this project needs — `haskell-deepseek-plugin-sdk` and `mamertomics-etl` — are today bare `stack new` scaffolds with no real API**, and a third (`kalecky`, the shared dimensional-units package) is trapped inside a hevm-fork Cabal sublibrary that Stack cannot depend on until it is extracted. Building "real" plugin logic against any of these before their APIs land guarantees rework. The mitigation, which architecture and pitfalls research converge on independently, is an interface-first strategy: define local contract modules (`ClientContract`, `StagingContract`) with fake/fixture implementations, build everything that has zero real upstream dependency first (claim/shock ADTs + codecs, the `KaleckianKernel` typed interface, property tests), and gate any code that imports the real SDK or ETL types behind an explicit "upstream API landed" checkpoint re-verified at each phase, not assumed.

The second-order risk is domain-specific and easy to under-weight relative to the engineering risk: the project's own "no hardcoded illustrative numbers" constraint is a live discipline problem in this exact toolchain (the predecessor monorepo has the identical rule for the same reason), `kalecky`'s dimensional typing has known gaps (no negative values, opaque `PriceIndex`, no USD), and "deterministic, testable translation" from prose claims to shock magnitudes is itself an interpretive modeling choice that must be documented per claim class, not presented as a discovered mapping. Mitigating this requires baking provenance and interpretive documentation into the type system and formalization artefact from the start, not bolting it on after the codec round-trips.

## Key Findings

### Recommended Stack

Stack 3.11.1 building GHC 9.10.3 via Stackage `lts-24.56` — the same snapshot already pinned by `mamertomics-etl`, chosen specifically because the SDK repo is a zero-dependency scaffold (trivial to re-pin) while the ETL repo has a real dependency tree that would be costly to re-resolve downward. Core additions: `aeson` 2.2.5.0 (JSON), `json-rpc` 1.1.3 + a hand-written line transport (the harness protocol is confirmed newline-delimited JSON-RPC 2.0 over stdio, not Content-Length/LSP-style framing, with no cancel method), `hasql` 1.9.3.1 + `hasql-pool` 1.3.0.5 (matches the ETL's Postgres layer, must connect via Supavisor's **session-mode** pooler on port 5432 since hasql relies on server-side prepared statements), `autodocodec` 0.5.0.0 (self-documenting codec, schema as byproduct — useful since claim/shock formats are explicitly "to be specified"), and `hasql-interpolate` for typed SQL without a live-DB compile-time dependency. Property tests use QuickCheck + tasty (matching the existing `kalecky-spec` precedent), not Hedgehog.

**Core technologies:**
- GHC 9.10.3 / Stack 3.11.1 / lts-24.56 — matches `mamertomics-etl` exactly, avoids cross-snapshot drift
- `json-rpc` + hand-rolled line transport — fits the harness's confirmed thin, unbatched, `\n`-delimited framing; a heavier Conduit-based library buys nothing here
- `hasql` + `hasql-pool` (session-mode Supavisor, port 5432) — required for prepared-statement correctness; transaction-mode pooling silently breaks this
- `autodocodec` — schema-as-byproduct for the claim/shock JSON formats, which are not yet finalized
- `kalecky` (once extracted) — the single shared dimensional/units vocabulary; explicitly must not be forked a third time

### Expected Features

Users of this plugin are threefold: the harness process spawning it, the downstream GAMS closure consuming its output, and the human economist reviewing whether a claim was translated honestly. Table stakes converge tightly with the existing sibling codebase's own conventions (`mamertomics-gams-bridge`'s `ManifestWedge`/`ManifestInput`), not an external ecosystem norm — this plugin would be a regression relative to its own downstream consumer if it dropped any of them.

**Must have (table stakes):**
- JSON-RPC line protocol conformance (`initialize`, `session/prompt`, `session.event`) and the clean spawn->handshake->shutdown/EOF->SIGTERM->SIGKILL lifecycle ladder
- Structured, closed-ADT claim input and shock output (never free text) — each with a JSON codec
- Every numeric shock carries provenance (source series/observation IDs) and a band (`value_low`/`value_high`), never a bare point estimate
- Explicit `is_assumed`/constructed flags; fail-loud/refuse-partial when a claim cannot be grounded
- One fixed, versioned dimensional/unit vocabulary (`kalecky`) shared end-to-end with the ETL and GAMS bridge

**Should have (competitive):**
- `KaleckianKernel`: a generic, typed model interface (state/parameters/closure) with the Colombia/Sarmiento instance as the first of potentially several country instances
- Claim -> data-query traceability: every shock documents which series and why, extending the existing `derivation_note` convention into a structured, testable relation
- Dimensionally-typed claim/shock ADTs sharing one unit system, catching unit-mixing errors at compile time (a class of bug Dynare/GAMS scenario files cannot catch at all)
- A formalization artefact (LaTeX/markdown) documenting the math <-> type correspondence per claim class

**Defer (v2+):**
- Additional claim classes beyond the first (markup/distribution) validated end-to-end
- A second country `KaleckianKernel` instance — no grounded data source exists for one yet
- Multi-period/path shocks — the GAMS bridge consumer has no path-solving to consume a richer shape
- Session pooling/warm-child reuse — explicitly out of scope in the SDK's own documented limitations
- The plugin solving the model itself, or fetching source data directly — both are explicit anti-features that duplicate ownership already held by other repos

### Architecture Approach

The Haskell process is a JSON-RPC **client** (verified directly from harness source, not inferred) that spawns and drives its own dedicated child harness process — it is the "driver" around a contained agent, not the agent itself. Internally it layers as: a Protocol Adapter (owns the SDK client surface: spawn, initialize, drain session.event), a Claim Parser (typed input ADT + codec), a Data-Grounding layer (typed queries against the ETL staging schema, never a second schema), a Claim->Shock Translator (one deterministic function per claim class), the `KaleckianKernel` (recommended as a record-of-functions closed over a phantom `country` type tag — not a typeclass or GADT — mirroring `kalecky`'s own phantom-tag idiom), and a Shock Codec (Aeson, carrying `kalecky`-typed magnitudes plus mandatory `mamertomics-core`-shaped provenance). A significant reuse finding: `mamertomics-core` already has a pre-existing claim/shock ADT design (`TheoryGraph.NodeId`, `Shock.ShockSpec`/`VariableBinding`/`PolicyEvent`) that this project should extend rather than duplicate — either as a direct dependency or, more likely given dependency-count risk, a frozen vendored copy of its shape reconciled later.

**Major components:**
1. **Protocol Adapter** — drives the child harness process over JSON-RPC (spawn, initialize, session/prompt, drain events)
2. **Claim Parser / Data-Grounding / Claim->Shock Translator** — the core pipeline: typed claim in, ETL-grounded magnitude in, typed shock out (`Either TranslationError ShockSpec`)
3. **KaleckianKernel** — generic typed model interface (state/parameters/closure), phantom-tagged per country, with `Sarmiento` as the sole v1 instance
4. **Shock Codec** — Aeson codec enforcing mandatory provenance and `kalecky` units on every output

### Critical Pitfalls

1. **Building real plugin logic against two hello-world stub dependencies** (`haskell-deepseek-plugin-sdk`, `mamertomics-etl`) — treat "upstream API exists and is pinned" as a hard, re-verified gate; build everything with zero real upstream dependency first (ADTs, codecs, kernel, property tests) behind local contract modules with fake implementations.
2. **JSON-RPC stdout pollution and buffering deadlocks** — Haskell's default block-buffering on non-TTY stdout plus any stray `putStrLn`/library log line silently corrupts or deadlocks the wire; set `LineBuffering`/`NoBuffering` explicitly, route all logging to stderr, and smoke-test the compiled subprocess's stdout.
3. **No teardown ladder for EOF/SIGTERM and notification interleaving** — the wire has no cancel method, so process termination *is* the cancel signal; serialize all stdout writes through a single writer and install both EOF and SIGTERM handlers driving the same teardown ladder.
4. **Supavisor transaction-mode pooling silently breaks correctness, not just performance** — default to the session-mode pooler (port 5432), matching the ETL's already-resolved decision; transaction-mode (6543) can fail prepared statements intermittently under load.
5. **Hardcoded "illustrative" numbers smuggled in as if grounded, and over-claiming a deterministic mapping** — both are documented, live discipline problems in this exact toolchain; enforce provenance at the type level (a shock value's constructor requires a provenance field, not a bare `Double`) and document the interpretive judgment call per claim class in the formalization artefact rather than implying a single canonical mapping exists.

## Implications for Roadmap

Based on combined research (architecture's Part 6 build order + pitfalls' phase mapping, which independently converge), suggested phase structure:

### Phase 1: Claim/Shock Vocabulary & Codecs
**Rationale:** Zero external dependency — buildable and testable on day one, unblocked by both stub upstreams. Establishes the type-level enforcement (mandatory provenance field) that prevents Pitfall 8 (hardcoded numbers) structurally rather than by convention.
**Delivers:** Closed claim-input ADT, closed shock-output ADT (with `kalecky`-shaped units, bands, `is_assumed` flag, mandatory provenance), Aeson/autodocodec codecs, codec round-trip tests.
**Addresses:** Table-stakes features — structured claim input, structured shock output, provenance-on-every-number, bands not point estimates, explicit assumed-flags.
**Avoids:** Pitfall 8 (hardcoded illustrative numbers) via type design; Pitfall 11 (forking a third dimensional system) by designing against `kalecky`'s actual vocabulary from day one, even before the ETL API exists.

### Phase 2: KaleckianKernel + Sarmiento Instance
**Rationale:** Also zero external dependency — pure functions testable against hand-constructed fixtures, no I/O. Sequenced right after the vocabulary phase since the kernel's parameter-vector shape and the shock ADT must agree.
**Delivers:** `KaleckianKernel` record-of-functions interface (phantom-tagged by country), `Sarmiento :: Country` instance wired to the existing GAMS-bridge closure's parameter shape (`a0`, `a1`, `g0`, `g1`, `g2`, `pi_anchor`, `tau_consumer`, `tau_producer`).
**Addresses:** The "generic, typed model interface" differentiator from FEATURES.md.
**Uses:** Stack elements — `optics-core`/`optics-th` (via `kalecky`), QuickCheck + tasty for property tests on the kernel's fields directly.

### Phase 3: Protocol Adapter & Fake Harness Runtime
**Rationale:** The component most exposed to upstream churn (developer-preview protocol, no cancel method) — isolating it behind an interface with a fake test double is the highest-leverage decoupling point in the project, so it should be built and proven against a fake before any real SDK dependency lands.
**Delivers:** `ClientContract` module (Types/Transport/Client.Process/Client.Session shape mirroring `dsh-sdk-client`), hand-written newline-delimited line transport, a scripted fake harness runtime (ported from `dsh-sdk-client`'s own `tests/fake-runtime.ts` pattern) for CI without a real `dsh` process.
**Implements:** Architecture's Protocol Adapter component.
**Avoids:** Pitfall 3 (treating the dev-preview protocol as stable, no cancel path), Pitfall 5 (stdout pollution/buffering deadlocks), Pitfall 6 (no teardown ladder, notification interleaving).

### Phase 4: Data-Grounding & Staging Contract
**Rationale:** Sequenced after the vocabulary/kernel phases so the grounding data has a typed destination; deliberately built against a local Postgres fixture, never the live Supabase project, until the ETL exposes a real API — this is a hard external dependency, not a design choice.
**Delivers:** `StagingContract` interface (`fetchSeries :: SeriesQuery -> IO (Either GroundingError GroundedValue)`), a docker-compose Postgres fixture seeded to the ETL's documented staging shape, connection discipline (session-mode Supavisor pooler, SSL required, IPv6 egress checked).
**Addresses:** The "grounded, never hardcoded" magnitude requirement.
**Avoids:** Pitfall 7 (Supavisor transaction-mode correctness bugs), Pitfall 12 (scope creep into re-ingesting source data directly).

### Phase 5: Claim->Shock Translation & Formalization
**Rationale:** This is the project's core deliverable risk, not a side concern — it should come after the vocabulary, kernel, and grounding contracts exist so the translation function has typed inputs/outputs on both sides. Start with exactly one claim class (markup/distribution — PROJECT.md already names its closure and target parameter) before generalizing.
**Delivers:** One deterministic `(SarmientoClaim, GroundingData) -> Either TranslationError ShockSpec` function, wired end-to-end through the fixtures from Phases 3-4; a formalization artefact documenting the interpretive judgment call, basis (nominal/real), and regime assumption explicitly.
**Addresses:** The differentiator "claim -> data-query traceability" and the core MVP scope from FEATURES.md.
**Avoids:** Pitfall 9 (unit/basis/sign mismatches presented as validated), Pitfall 10 (over-claiming a deterministic mapping that is actually a modeling choice).

### Phase 6: Upstream Integration & CI
**Rationale:** Deliberately last — gated on the SDK's and ETL's own external roadmaps, not on this project's internal work; wiring against moving pre-1.0 targets before steps 1-5 are stable would be noisy without earning anything.
**Delivers:** Swap the `StagingContract` fixture for the real `mamertomics-etl` client and the `ClientContract` fake for the real `haskell-deepseek-plugin-sdk`, once each grows a real library surface; private-repo git extra-dep CI auth (scoped machine-user PAT), `stack.yaml.lock` discipline, resolver-compatibility checks on every bump; end-to-end integration test against the real (or realistically pinned) upstreams.
**Avoids:** Pitfall 1 (building against stubs), Pitfall 2 (resolver/GHC snapshot divergence), Pitfall 4 (private git extra-dep auth and lockfile churn).

### Phase Ordering Rationale

- Phases 1-2 have zero external dependency and should be the earliest schedulable work regardless of upstream progress — this directly de-risks the project's single biggest identified pitfall (building against hello-world stubs).
- Phases 3-4 build interface contracts with fake/fixture implementations rather than waiting on real upstreams, so the plugin's transport and data-access shapes can be proven correct in isolation before either upstream API exists.
- Phase 5 is sequenced after the type/kernel/contract layers because the translation function's signature depends on all three; attempting it earlier would mean designing against unstable types.
- Phase 6 is explicitly last and flagged as blocked-on-external-roadmaps — this matches both PITFALLS.md's and ARCHITECTURE.md's independent conclusion that CI/integration against two moving pinned-commit dependencies should not be attempted before their APIs stabilize.
- Every phase should carry an explicit negative check against scope creep (no equilibrium-solving code, no direct source-data fetches) as an ongoing success-criterion, not a one-time Phase-0 warning.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Protocol Adapter & Fake Harness Runtime):** The DeepSeek Harness protocol is an explicit developer preview with declared breaking changes; the exact SDK client surface (`DeepSeek.Harness.Client.*`) doesn't exist yet upstream (LOW confidence per ARCHITECTURE.md) — needs re-verification against the actual harness repo state at the time this phase is planned, not just this research pass.
- **Phase 6 (Upstream Integration & CI):** Cross-repo token scoping (`JMSBPP` vs `d2p-finance` org `GITHUB_TOKEN` behavior) was flagged MEDIUM confidence in STACK.md and not independently verifiable without repo admin access; needs a live check when this phase is actually planned.
- **Phase 5 (Claim->Shock Translation & Formalization):** The four-class claim taxonomy (demand-regime, markup/distribution, external-constraint, productive-structure) is explicitly flagged in FEATURES.md as "a starting hypothesis... not a finished spec" needing validation against Sarmiento's actual published texts.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Claim/Shock Vocabulary & Codecs):** Standard Haskell ADT + Aeson/autodocodec codec design, with a directly-verified sibling-codebase precedent (`mamertomics-gams-bridge`, `mamertomics-core`) to extend.
- **Phase 2 (KaleckianKernel):** The record-of-functions-over-a-phantom-tag pattern is well-established Haskell practice and directly evidenced by `kalecky`'s own idiom; no external unknowns.
- **Phase 4 (Data-Grounding & Staging Contract):** Supabase/Supavisor connection pooling behavior is HIGH-confidence, officially documented, and already resolved identically by the sibling `mamertomics-etl` project.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Versions verified live against Stackage `lts-24.56` and Hackage; protocol framing verified against the harness's own `packages/sdk/protocol` README; both sibling `stack.yaml` files read directly |
| Features | MEDIUM-HIGH | Harness plugin surface read directly from source (HIGH); economics claim taxonomy synthesized from standard Post-Keynesian literature plus this project's own sibling code, not yet validated against Sarmiento's actual texts (MEDIUM) |
| Architecture | MEDIUM-HIGH | Wire-side client-vs-server question is HIGH confidence (read directly from harness TypeScript source + two Agent Notes); internal layering and `KaleckianKernel` design are MEDIUM-HIGH (derived from evidence in `mamertomics-core`/`kalecky-spec`, extrapolated since neither has a stable API); exact `haskell-deepseek-plugin-sdk` surface is LOW (upstream is a scaffold — this document specifies what it must expose, not what exists today) |
| Pitfalls | MEDIUM | Protocol/transport and Stack-tooling pitfalls verified against official docs (HIGH); Supabase/Supavisor pitfalls verified against official Supabase docs (HIGH); economics-formalization pitfalls (units, sign conventions, over-claiming determinism) are derived from this project's own stated constraints and domain reasoning, not an external documented pattern (MEDIUM) |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **`kalecky` extraction has not landed:** it remains inside a hevm-fork Cabal sublibrary that Stack cannot depend on directly (confirmed upstream Stack limitation, issues #5318/#5256). This is a hard Phase-0 blocker inherited transitively from `mamertomics-etl` — during planning, gate any real `kalecky` dependency behind a small locally-vendored phantom-tag subset (Part 5 of ARCHITECTURE.md), swapped once the real package exists.
- **`haskell-deepseek-plugin-sdk` and `mamertomics-etl` are both bare scaffolds today:** neither exposes a real API as of this research. Treat both as blocking gates rather than consumable dependencies; build behind local `ClientContract`/`StagingContract` interfaces with fake/fixture implementations, and re-verify (not assume) upstream shape before writing code against it.
- **`mamertomics-core` reuse-vs-fork decision is unresolved:** `mamertomics-core` already has a designed `NodeId`/`Variable`/`ShockSpec` claim/shock vocabulary this project could extend directly (as a third live git dependency) or vendor a frozen copy of. This is a cross-repo decision that needs to be raised explicitly during Phase 1 planning, not deferred.
- **The four-class claim taxonomy is an unvalidated hypothesis:** demand-regime, markup/distribution, external-constraint, and productive-structure classes were synthesized against training-data knowledge of Blecker & Setterfield / Bhaduri-Marglin literature and this project's own parameter vector, not verified against Sarmiento's actual published claims. Validate during requirements/roadmap definition, before finalizing the claim ADT's constructors.
- **Shock output wire format is explicitly "to be specified" per PROJECT.md:** how the Shock Codec's output actually reaches the child harness process (session/prompt content vs. a direct file/API channel) is undecided; this needs a concrete decision during Phase 3/5 planning.

## Sources

### Primary (HIGH confidence)
- `~/ai-agents/deepseek-harness/packages/sdk/protocol/src/{types.ts,transport.ts}` — wire request/notification maps, `JsonRpcLineTransport`, read directly
- `~/ai-agents/deepseek-harness/docs/subsystems/subprocess.md`, `.agents/notes/implemented/feature/2026-07-27-typescript-sdk-and-sdk-subagent-backend.md` — client-vs-server role determination, read directly
- `mamertomics-etl/stack.yaml`, `.planning/PROJECT.md` — snapshot pin, Supavisor decision, `kalecky` extraction blocker, read directly
- `haskell-deepseek-plugin-sdk/stack.yaml`, `.cabal`, `src/Main.hs` — confirms scaffold-only state, read directly
- `mamertomics-monorepo/src/mamertomics-gams-bridge/src/Mamertomics/Gams/{Types,Manifest,Import}.hs` and test fixtures — downstream consumer's existing shock/provenance conventions, read directly
- `mamertomics-monorepo/src/mamertomics-core/src/Mamertomics/Core/{Provenance,DataPoint,Series,Shock,Basis,Scale,Dimension,TheoryGraph,Markup}.hs` — existing claim/shock ADT layer, read directly
- `kalecky-semantics/kalecky-spec/src/Kalecky/Types/*` and `Kalecky/Operators/*` — value-type layer, phantom-tag discipline, documented gaps, read directly
- Stackage `lts-24.56` and per-package pages — fetched live, 2026-08-25
- Supabase official docs (Supavisor FAQ, connection terminology, disabling prepared statements) — official, HIGH

### Secondary (MEDIUM confidence)
- Post-Keynesian/Kaleckian literature (Blecker & Setterfield 2019, Bhaduri-Marglin 1990, Onaran-Galanis) — cross-checked via web search against training-data synthesis for the claim taxonomy
- Dynare Reference Manual (`shocks` block syntax) — used as a comparison baseline for the shock-format design
- Standard `git config url.insteadOf` GitHub Actions pattern for private Stack git extra-deps — cross-verified across multiple independent community sources, not GitHub's own official docs directly

### Tertiary (LOW confidence)
- Exact future `DeepSeek.Harness.Client.*` module surface for `haskell-deepseek-plugin-sdk` — specified as a requirement in this research, not observed, since upstream is currently a one-file scaffold
- Cross-org (`JMSBPP` vs `d2p-finance`) `GITHUB_TOKEN` scoping behavior for CI — needs live verification with repo admin access, not available to this research pass

---
*Research completed: 2026-08-25*
*Ready for roadmap: yes*
