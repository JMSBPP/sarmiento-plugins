# sarmiento-plugins

## What This Is

A private Haskell Stack project that ships a DeepSeek Harness (Cordis) plugin which is itself a contained agent: given Sarmiento claims in a structured input format (to be specified), it reads Colombian macroeconomic data from `mamertomics-db` (the Supabase staging database owned by `JMSBPP/mamertomics-etl`) and emits Kaleckian macro shocks in an output format (to be specified) that a Kaleckian model consumes. Alongside the runnable plugin, the project types and formalizes Eduardo Sarmiento's structuralist claims as a Colombian instance of a generic `KaleckianKernel` model, so "Sarmiento" becomes a typed plugin over a reusable kernel rather than prose.

## Core Value

A Sarmiento claim goes in, a dimensionally-typed Kaleckian shock grounded in real `mamertomics-db` data comes out — through the harness plugin protocol, with every number carrying provenance and units.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Stack project builds against git extra-deps `JMSBPP/mamertomics-etl` (private) and `d2p-finance/haskell-deepseek-plugin-sdk` (public), pinned by commit and bumped as the SDK evolves
- [ ] Plugin speaks the DeepSeek Harness JSON-RPC line protocol (`dsh-sdk-protocol`: `initialize`, `session/prompt`, `session.event` notifications) as a contained agent whose context is supplied by the harness, in the shape the SDK exposes
- [ ] Structured **claim input** format defined and typed: a Sarmiento claim (e.g. demand-regime, markup/distribution, external-constraint statements about the Colombian economy) as a Haskell ADT with JSON codec
- [ ] Structured **shock output** format defined and typed: a Kaleckian shock (parameter/exogenous perturbation on the kernel: markup, wage share, autonomous demand, capacity utilization, external constraint) as a Haskell ADT with JSON codec, units from `kalecky`
- [ ] Data access: plugin reads series from `mamertomics-db` (Supabase Postgres staging schema populated by `mamertomics-etl`) via the ETL package's types/API — no second schema, no hardcoded values
- [ ] Claim → shock mapping: for each supported claim class, a deterministic, testable translation into a shock, with the data query that grounds its magnitude
- [ ] `KaleckianKernel`: a generic, typed Kaleckian model interface (state, parameters, closure) that country plugins instantiate; `Sarmiento` = the Colombian instance
- [ ] Formalization artefact: the Sarmiento-as-kernel-plugin mapping documented (LaTeX/markdown) with the math ↔ type correspondence
- [ ] Test suite: codec round-trips, property tests on claim→shock invariants (dimensional consistency, sign conventions), protocol conformance against a fake harness runtime
- [ ] CI on the private GitHub repo (build + tests), given private deps need a token

### Out of Scope

- Solving the Kaleckian model — the plugin *produces shocks*; solving stays in the monorepo's GAMS closure / downstream model
- Ingesting or transforming source data — `mamertomics-etl` owns fetch/parse/load; this project only reads staging tables
- Writing the SDK's library API from this repo — the SDK (`d2p-finance`) evolves upstream; this project syncs to it and stubs only what it needs until the SDK lands it
- Cordis/TypeScript plugin implementation — the plugin is Haskell over JSON-RPC, not an in-process Cordis plugin
- A Web UI or CLI beyond what is needed to run/test the plugin
- Countries other than Colombia — the kernel is generic by design, but only the Sarmiento/Colombia instance is built here

## Context

- **Harness:** `github.com/deepseek-ai/deepseek-harness` ("Everything is a plugin", Cordis, developer preview with breaking changes). Native plugins are TypeScript; out-of-process integration is via the stdio JSON-RPC surface (`@deepseek-ai/dsh-sdk-protocol`, `JsonRpcLineTransport`, `InitializeParams/Result`, `SessionPromptParams/Result`, `session.event`/`subagent.started` notifications) used by the Python/TS SDKs and by the `subagent-dsh-sdk` backend, where a child is a complete harness runtime with its own `cordis.yml`. "Contained agent with specific context" maps onto that subagent model. The wire currently has no cancel method.
- **SDK:** `d2p-finance/haskell-deepseek-plugin-sdk` — "Haskell SDK for building DeepSeek Harness (Cordis) plugins over JSON-RPC". As of 2026-08-25 it is a `stack new` scaffold (executable printing hello world, lts-22.43, no library). Fork `JMSBPP/haskell-deepseek-plugin-sdk-develop` (pushed 2026-08-25) is identical. Local clone: `~/ai-agents/haskell-deepseek-plugin-sdk`. Dependency tracks **upstream d2p-finance** (user decision 2026-08-25).
- **mamertomics-db = `JMSBPP/mamertomics-etl`** (private). As of 2026-08-25 a `stack new` scaffold (lts-24.56, `Lib.hs`) with a GSD plan: Haskell ETL landing raw Colombian sources (DANE, BanRep, ANDI, minimum-wage decrees) into Supabase Storage + a typed staging schema on Supabase Postgres (project `xztxzcmjvluvddczdmra`), value types from `kalecky`. It exposes a JSON-RPC daemon and CLI. Its staging schema is the data this plugin reads. The name `mamertomics-db` today also exists as an executable in `mamertomics-monorepo/src/mamertomics-storage` (opaleye layer, 11 migrations) — that is the *predecessor*, not the dependency.
- **Type source of truth:** `kalecky` (`JMSBPP/kalecky-semantics`, sublibrary, base-only): `Kalecky.Types.Units`, `Currency`, `Measure`, `Valuation`, `Prices.{Price,PriceIndex,Wage}`, operators `Gap/Delta/GrowthRate`. Extraction into a standalone package is already a prerequisite in the ETL plan; this project inherits it transitively and must not fork a third dimensional system.
- **Economic frame:** Post-Keynesian / structuralist (Blecker & Setterfield 2019; Eduardo Sarmiento as Colombian referent). Kaleckian closure in use: `P = (1+m)·wL/Y` → `(W/Y, Π/Y)` → `I^d − S`; Sarmiento claims are read as statements about that closure's parameters and regime.
- **Snapshot mismatch:** SDK on lts-22.43 (GHC 9.6), ETL on lts-24.56 (GHC 9.10). One snapshot must be chosen here; likely lts-24.x with the SDK asked to follow.
- **Related repos:** `mamertomics-monorepo` (Codeberg canonical, GitHub CI mirror — never run its full test suite locally), `mamertomics-etl`, `kalecky-semantics`.
- Repo: `https://github.com/JMSBPP/sarmiento-plugins` (private), local `~/mamertomics/sarmiento-plugins`, initialized 2026-08-25.

## Constraints

- **Tech stack:** Haskell, Stack 3.11 via ghcup, hpack `package.yaml` — user-specified
- **Dependencies:** `JMSBPP/mamertomics-etl` and `d2p-finance/haskell-deepseek-plugin-sdk` as Stack git extra-deps; both are moving targets — pin commits, bump deliberately
- **Protocol:** DeepSeek Harness JSON-RPC as exposed by the SDK; harness is in developer preview with declared breaking changes
- **Formats:** claim input and shock output formats are *to be specified* in this project (Phase-level decisions), not pre-given
- **Data integrity:** no hardcoded "illustrative" numeric literals — magnitudes come from `mamertomics-db` with provenance, or the work stops and the question is surfaced
- **Process:** two-step review (Reality Checker + one AI-agency specialist, in parallel) before any spec/plan executes; every plan subtask names its executing specialist agent
- **Secrets:** DB DSNs and API keys via environment only; never in config files, logs, or commits
- **Content:** no political framing in any generated artefact

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| `mamertomics-db` dependency = `JMSBPP/mamertomics-etl` | User decision 2026-08-25; the ETL's Supabase staging schema is the live DB, the monorepo storage layer is the predecessor | — Pending |
| Track upstream `d2p-finance` SDK, sync as it evolves | User decision 2026-08-25; the SDK is developed upstream, this project is a consumer | — Pending |
| Plugin is a contained agent (harness-supplied context), not a tool-only plugin | Matches the harness's `subagent-dsh-sdk` model and the user's framing | — Pending |
| Generic `KaleckianKernel` + Sarmiento as Colombian instance | Second stated goal; keeps the formalization reusable and testable | — Pending |
| Repo lives at `~/mamertomics/sarmiento-plugins` | Empty `~/mamertomics/` becomes the workspace for mamertomics-related repos | — Pending |

---
*Last updated: 2026-08-25 after initialization*
