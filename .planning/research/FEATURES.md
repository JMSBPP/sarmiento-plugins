# Feature Research

**Domain:** DeepSeek Harness (Cordis) contained-agent plugin that translates Eduardo Sarmiento's Colombian structuralist/Post-Keynesian claims into Kaleckian macro shocks grounded in the macro data resource
**Researched:** 2026-08-25
**Confidence:** MEDIUM-HIGH (harness surface: HIGH, read directly from `deepseek-harness` docs/source/notes and the monorepo's GAMS bridge; economics claim taxonomy: MEDIUM, standard Post-Keynesian literature synthesized against training data and lightly web-verified; shock/scenario file-format conventions: MEDIUM-HIGH, Dynare verified via official manual, GAMS/SFC verified against this project's own existing `mamertomics-gams-bridge` code)

## Two ecosystems, one plugin

This project sits at the intersection of two feature landscapes that don't normally meet:

1. **Harness/agent plugin surface** — what `dsh` (DeepSeek Harness / Cordis) expects a contained subagent to speak, sourced from `~/ai-agents/deepseek-harness/docs/architecture.md`, `docs/cordis-primer.md`, `docs/cordis-tutorial/01-first-plugin.md`, `.agents/notes/implemented/feature/2026-06-21-subagent-capability-seam.md`, `.agents/notes/implemented/feature/2026-07-27-typescript-sdk-and-sdk-subagent-backend.md`, `.agents/notes/implemented/feature/2026-07-12-subagent-persona-tool-filter-and-depth.md`, `.agents/notes/implemented/architecture/2026-07-20-canonical-tool-output-contract.md`, and `packages/subagent/subagent-dsh-sdk/README.md`.
2. **Claim → model-shock translation tooling** in computational macro — how Dynare, GAMS, and SFC/Kaleckian practice specify a scenario/shock, cross-checked against this project's own sibling code, `mamertomics-monorepo/src/mamertomics-gams-bridge`, which is the actual downstream consumer of whatever this plugin emits.

The features below are organized by the six axes the question named — claim input format, shock output format, provenance/units, determinism, explainability of the mapping, kernel genericity — plus the harness protocol surface as a seventh axis, because a feature that is table-stakes on the harness side (e.g. JSON-RPC `initialize`) is invisible to the economics side and vice versa.

## Feature Landscape

### Table Stakes (Users Expect These)

Users here are threefold: the harness process spawning this plugin as a child (`subagent-dsh-sdk` backend), the downstream GAMS closure consuming the shock, and the human reviewing whether a Sarmiento claim was translated honestly. Missing any of these makes the plugin either unusable as a harness child, untrustworthy as a data source, or silently wrong.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| JSON-RPC line protocol conformance: `initialize`, `session/prompt`, `session.event` notifications | This is the entire contract `subagent-dsh-sdk` uses to drive a child harness runtime over stdio; without it the harness cannot spawn, handshake, or read the plugin's output at all | MEDIUM | `@deepseek-ai/dsh-sdk-protocol` names every payload (`InitializeParams/Result`, `SessionPromptParams/Result`); this project depends on the Haskell SDK exposing the equivalent wire shapes, currently a scaffold |
| Clean process lifecycle: spawn → `initialize` handshake → run → `shutdown`/stdin-EOF→SIGTERM→SIGKILL ladder | `subagent-dsh-sdk`'s own dispose path expects this exact ladder (`shutdownTimeoutMs`, `disposeEofGraceMs`, `disposeGraceMs`); a child that hangs on SIGTERM or ignores stdin EOF breaks the parent's teardown budget | LOW-MEDIUM | Documented explicitly in the SDK README's Configuration table |
| No wire-level cancel — settle locally to `aborted` on dispose | "The wire currently has no cancel method" is stated as a durable protocol fact in both `PROJECT.md` and the SDK README; a plugin that blocks waiting for a cancel RPC that will never arrive is broken | LOW | This is a constraint to *accept*, not a feature to build around — see anti-features |
| Structured **claim input**: closed ADT + JSON codec, not free text | The downstream consumer (GAMS closure) and the property tests both need a value, not a string; PROJECT.md already commits to "Haskell ADT with JSON codec" | MEDIUM | Codec round-trip tests are already a named requirement |
| Structured **shock output**: closed ADT + JSON codec, with `kalecky` units | Same reasoning, mirrored on the output side; the GAMS bridge's own `scenario_scalars` are exactly this shape (named parameter + typed value) | MEDIUM | See "Shock output format" comparison below |
| Every numeric output carries provenance: source series/observation ids, not just a number | `mamertomics-gams-bridge`'s `ManifestInput`/`ManifestWedge` and the `scenario-baseline-2023.json` fixture already do this for every single input and parameter (`source_observation_ids`, `derivation_note`, `effective_from`) — this is the established convention in the sibling codebase this plugin feeds | MEDIUM | Table stakes *because* the immediate downstream consumer already enforces it; a shock without provenance would be a regression relative to the existing pipeline |
| Bands, not bare point estimates, when the underlying magnitude is uncertain | `ManifestWedge` carries `value`, `value_low`, `value_high` for every structural parameter (`a0`, `a1`, `g0`, `g1`, `g2`, `pi_anchor`, `tau_consumer`, `tau_producer`); `pi_anchor`'s own derivation note explicitly warns "NOT a statistical CI, NOT centered — consumers must not assume interiority" | MEDIUM | A shock schema that only carries `value_numeric` and drops the band silently loses information the existing closure treats as load-bearing |
| Explicit `is_assumed`/`constructed` flags — never a silently interpolated or default number | `ManifestWedge.mwIsAssumed`, `ManifestInput.miConstructed`, and PROJECT.md's own constraint ("no hardcoded illustrative numeric literals — magnitudes come from the macro data resource with provenance, or the work stops") converge on the same rule | LOW-MEDIUM | This is a hard constraint, already stated twice independently (project constraint + sibling code convention) |
| Fail-loud, refuse-partial when a claim cannot be grounded | `Mamertomics.Gams.Import.importSolve` refuses to import *anything* from a `NonOptimal` solve rather than landing partial results ("fail-loud/nothing-partial, per CONTEXT's standing doctrine") | LOW-MEDIUM | The plugin should mirror this: an unsupported or ungrounded claim is a typed error result, never a best-effort guess |
| Deterministic, testable claim→shock mapping per supported claim class | PROJECT.md requirement; also matches Dynare/GAMS practice where a `.mod`/`.gms` scenario file is a deterministic function of its inputs, never a sampled or model-dependent guess | MEDIUM | Property tests on dimensional consistency and sign conventions are already scoped |
| A single fixed, versioned dimensional/unit vocabulary (`kalecky`) shared end-to-end | The gams-bridge already treats units/valuation/dimension as first-class (`Mamertomics.Core.Dimension`, `EconomicDimension`, `ValueSpec`); PROJECT.md explicitly forbids forking "a third dimensional system" | MEDIUM | Both the data resource and this project must consume the same extracted `kalecky` package — a hard cross-project dependency, not optional |

### Differentiators (Competitive Advantage)

There is no real "competitor" ecosystem for this exact plugin — the differentiation is against (a) generic subagent tool-calling patterns in the harness ecosystem, and (b) the ad hoc, hand-tuned way shock magnitudes are normally chosen in Dynare/GAMS/SFC practice.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| `KaleckianKernel`: a generic, typed model interface (state, parameters, closure) with country instances | Reusable formalization instead of "Sarmiento" being prose; the parameter *shape* already exists empirically in `mamertomics-gams-bridge`'s closure (`a0`, `a1`, `g0`, `g1`, `g2`, `pi_anchor`, `tau_consumer`, `tau_producer`, `s_band`) — the kernel's job is to abstract that shape so a second country instance is a new parameter *vector*, not new code | HIGH | This is the project's stated second goal; genericity should be validated by designing the interface so the existing Colombian closure is a special case, not by speculatively supporting a hypothetical second country |
| Claim → data-query traceability: every shock documents *which* series/observation grounded its magnitude and *why* the claim maps to that parameter | No standard tool in the DSGE/Dynare/GAMS/SFC world connects a stated economic thesis to a specific parameter perturbation with a machine-checkable data query; shock files in that world are hand-authored by the modeler with the reasoning left in a comment at best | MEDIUM-HIGH | Directly extends the existing `derivation_note` convention from a per-parameter free-text field into a structured, testable claim→shock relation |
| Dimensionally-typed claim AND shock ADTs sharing one unit system (`kalecky`) | Prevents the classic Dynare/GAMS failure mode of a scenario file silently mixing a percentage-point shock with a share-of-GDP shock on the same exogenous variable name; the type system catches it at compile time instead of at solve time | MEDIUM | Differentiator specifically *because* Dynare's `shocks` block and GAMS `Parameter` declarations carry no unit typing at all — units are tribal knowledge in the `.mod`/`.gms` file's comments |
| Shock magnitude always derived from live the macro data resource data, never a calibrated/illustrative literal | Standard Dynare/DSGE practice calibrates shock size from priors, historical SD, or literature values baked into the `.mod` file; standard GAMS scenario practice hand-edits `scenario_scalars.inc`. This plugin instead re-derives magnitude from the same staging schema the baseline itself came from, so a claim and the baseline it perturbs are provenance-consistent by construction | MEDIUM-HIGH | This is the "Core Value" line from PROJECT.md restated as a feature; its cost is that unsupported claim classes must be rejected rather than shipped with a placeholder |
| Formalization artefact (LaTeX/markdown) documenting the math ↔ type correspondence for each claim class | Makes the Kaleckian closure and Sarmiento's specific claims auditable by an economist who does not read Haskell, closing the loop between the typed kernel and the literature it claims to represent | MEDIUM | Not a runtime feature, but a differentiator relative to "prose-only" structuralist commentary, which is the actual status quo being replaced |
| Property-based invariant tests across the whole claim→shock surface (dimensional consistency, sign conventions) | Dynare/GAMS scenario files have no equivalent test surface at all — a sign error in a `shocks` block is caught only by an economist noticing an implausible result post-solve | MEDIUM | Builds directly on the existing "no hardcoded illustrative literals" discipline; turns a review-time convention into a compile/test-time guarantee |

### Anti-Features (Commonly Requested, Often Problematic)

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|------------------|-------------|
| The plugin solves the Kaleckian model itself | Seems convenient — "just give me the answer," skip the round-trip to the GAMS closure | Duplicates solver logic that already exists and is tested in `mamertomics-gams-bridge`'s `Solve.hs`/`kalecki.gms`; conflates "translate a claim into a shock" with "compute an equilibrium," which are genuinely different responsibilities with different failure modes (a bad translation is a modeling error, a bad solve is a numerical/solver error) | Emit the typed shock; the monorepo's GAMS bridge solves it, exactly as PROJECT.md's Out of Scope already states |
| Free-text-only claim input and/or free-text-only shock output | Feels natural for an LLM-facing tool — "just let the model describe the claim in prose and describe the shock back" | Makes the claim→shock mapping untestable (no invariant to check against prose), non-reproducible (the same claim phrased two ways could map differently), and breaks the downstream GAMS bridge, which needs a named parameter + typed value, not a paragraph | Closed ADT for both claim and shock, each with a JSON codec; unsupported claim phrasing is a typed rejection, not a best-effort paraphrase |
| An in-process Cordis/TypeScript plugin implementation | Cordis plugins are the harness's native extension mechanism, so it looks like the "proper" way to extend `dsh` | Directly contradicts the project's constraint (Haskell over JSON-RPC, not in-process) and would require reimplementing the entire economics stack in TypeScript to run inside the harness's own process | Contained agent over `subagent-dsh-sdk`'s stdio JSON-RPC surface — a full peer harness runtime with its own `cordis.yml`, exactly the pattern the SDK backend already documents |
| Implementing a bespoke wire-level prompt-cancellation mechanism | Feels like a gap when "the wire has no cancel method" is read as a missing feature rather than a documented constraint | The harness's own `subagent-dsh-sdk` provider already handles this by settling the run result locally as `aborted` and closing the runtime through the shutdown ladder — inventing a second, incompatible cancel channel would fight the parent's dispose semantics instead of using them | Rely on process teardown (stdin EOF → SIGTERM → SIGKILL) for cancellation, matching the documented backend behavior exactly |
| Free-form / open-ended "explain any economist's claims" NLP layer with no closed claim taxonomy | Appears more general-purpose and future-proof | Makes "deterministic, testable translation" (a hard project requirement) impossible — an open-ended interpreter has no fixed invariant to test against, and it invites exactly the "illustrative numeric literal" failure the project constraints explicitly forbid | A closed ADT of supported claim classes (demand-regime, markup/distribution, external-constraint, productive-structure — see Kaleckian grounding below); a claim outside the closed set is a loud, typed rejection, and adding a new class is a deliberate code change with its own tests, not a runtime capability |
| Session pooling / warm-child reuse across plugin invocations | Looks like an obvious performance win once the "fresh runtime process per run — no pooling" limitation is noticed in the SDK README | The SDK provider's own documented limitation states pooling is out of scope for the backend itself ("a harness runtime boots a full plugin tree, so per-run spawn cost is higher than the ACP backend's typical child" — accepted, not solved); building pooling inside this plugin would require reimplementing session/state isolation the harness itself does not provide across runs | Accept per-run spawn cost; if it becomes a real bottleneck, that is upstream `subagent-dsh-sdk` scope, not this plugin's |
| Streaming intermediate claim-parsing/shock-construction steps into the parent's session log | Seems like good transparency/observability | The seam's own documented behavior is "only lifecycle + the final result surface" for out-of-process subagent providers — the parent log records just the delegation `tool/call`/`tool/result`, and the child's own transcript stays in the child's session root; fighting this to bridge intermediate state would go against the documented seam contract | Emit a complete, provenance-carrying shock as the one durable output; keep intermediate reasoning inside the child's own session/log, inspectable there if needed |
| Countries other than Colombia in v1 | The generic `KaleckianKernel` naturally invites "why not add Brazil/Chile now, it's almost free" | PROJECT.md scopes this out explicitly; a second country instance without a second country's grounded data (from the data resource, which is Colombia-only) would force exactly the "illustrative literal" failure mode the whole project is designed to prevent | Keep the kernel generic in *type*, ship exactly one instance (Sarmiento/Colombia) backed by real data; a second country is a future consumer of the same interface, not v1 scope |
| A parallel/competing dimensional-unit system for claims or shocks | Every new ADT needs *some* numeric representation, and it's tempting to define one locally for speed | PROJECT.md explicitly forbids forking a third dimensional system beyond `kalecky` and `mamertomics-core`; a locally-invented unit type would silently diverge from the one the GAMS bridge and the data resource already share | Depend on the extracted `kalecky` package transitively; if it lacks a needed unit, that is upstream scope in `kalecky-semantics`, not a local fork |
| A Web UI or CLI beyond what's needed to run/test the plugin | Feels incomplete without a way to "see" the plugin working outside the harness | Explicitly out of scope in PROJECT.md; the harness (or a fake-runtime test harness) is already the intended surface | Test against a scripted fake harness runtime (the same pattern `subagent-dsh-sdk`'s own test suite uses: `tests/fake-runtime.ts`-equivalent) |

## Kaleckian claim taxonomy (grounds the "claim input" ADT)

The claim ADT should be a **closed sum type**, not an open/extensible one, mirroring the literature's own closed set of standard Kaleckian/neo-Kaleckian mechanisms (Blecker & Setterfield 2019; Bhaduri–Marglin 1990; Onaran–Galanis empirical wage-led/profit-led work) and Sarmiento's structuralist emphases. Four claim classes cover the domain and map cleanly onto the parameter vector `mamertomics-gams-bridge`'s closure already solves:

| Claim class | Kaleckian mechanism | Target parameter(s) in the existing closure | Confidence |
|---|---|---|---|
| Demand-regime (wage-led / profit-led) | Bhaduri–Marglin: sign of `du/dπ` (utilization response to a profit-share change) determines the regime; Onaran–Galanis extend this empirically across open economies | `pi_anchor` (distribution anchor), `g0`/`g1`/`g2` (investment-function coefficients, whose relative weight on profit share vs. utilization encodes the regime) | MEDIUM — standard textbook mechanism, mapping onto this project's specific parameter names is this research's own synthesis |
| Markup / distribution | `P = (1+m)·wL/Y` closure already named in PROJECT.md's Context section; a markup claim is a claim about `m` (or equivalently the wage share `W/Y`) | `pi_anchor`, `a0`/`a1` (labor/capital productivity, which the wage share is defined relative to) | HIGH — this is the closure PROJECT.md itself names |
| External constraint | Sarmiento's structuralist emphasis on balance-of-payments-constrained growth (Thirlwall-tradition external constraint); a claim here is about the tax/trade wedge structure limiting sustainable demand expansion | `tau_consumer`/`tau_producer` (tax wedges), and indirectly the `s_band` (savings propensity band) | MEDIUM — the specific parameter mapping is this research's synthesis; the external-constraint literature itself is well established |
| Productive structure / heterogeneity | Sarmiento's claims about Colombia's productive-structure limits (capital intensity, informality) constraining accumulation | `a0`/`a1` (capital/labor productivity parameters, already carrying a derivation note about K-concept and utilization-reading ambiguity in the fixture read) | MEDIUM — directly evidenced by the `a1` parameter's own derivation note in `scenario-baseline-2023.json`, which already encodes exactly this kind of structural ambiguity as a band |

This taxonomy is a **starting hypothesis for the requirements phase**, not a finished spec — it should be validated against Sarmiento's actual published claims (a task for requirements/roadmap, not this research pass) before the ADT is finalized. Its value here is showing that a closed, four-class taxonomy is plausible and already has a natural target in the existing closure's parameter vector, which de-risks "kernel genericity" as a differentiator rather than speculative scope.

## Shock/scenario format comparison (grounds the "shock output" ADT)

| Convention | Dynare `shocks` block | GAMS scenario parameters (`mamertomics-gams-bridge`) | Typical SFC/Kaleckian practice | This project's target |
|---|---|---|---|---|
| Shock target | Named `varexo`/`varexo_det` | Named `Parameter`/`Scalar`, read from `scenario_scalars.inc` | Named behavioral parameter or exogenous flow in a stock-flow matrix (tool-specific DSL, e.g. Minsky/PySFC) | Named field of a closed shock ADT, keyed to the `KaleckianKernel`'s parameter vector |
| Magnitude representation | Bare numeric `values`, no units | Bare `Scientific`/`Double`, units carried only in prose comments and this project's own `Mamertomics.Core.Dimension` layer | Bare numeric, units are modeler convention | `kalecky`-typed value with explicit units — table stakes here, absent everywhere else |
| Uncertainty | None natively — a single deterministic value per period, or a `stderr` for the stochastic case | Explicit band (`value_low`/`value_high`) plus `is_assumed` flag, already implemented | Rare — usually a single scenario run, sensitivity done by re-running with different literals | Carry the band and `is_assumed`-equivalent flag through — table stakes, matching the existing GAMS-bridge convention |
| Temporal scope | Explicit (`periods 1:9`) — shocks are inherently time-indexed | Single-period per scenario (v1, per this project's own `06-CONTEXT.md` note read in `Import.hs`) | Usually a permanent shift from one steady state to another, or a bounded transition path | Single scenario-year shock in v1, matching the GAMS bridge's own v1 scope — no need to over-build temporal generality this plugin's consumer doesn't use yet |
| Provenance | None — the `.mod` file itself, under version control, is the only record | Explicit, structured (`derivation_note`, `source_observation_ids`, `effective_from`) | None standard | Mandatory structured provenance — differentiator relative to Dynare/typical SFC, parity with the existing GAMS bridge |
| Baseline relationship | Shock is a *delta* on an exogenous variable relative to steady state | Result quantities are explicitly noted as "CHANGE-RELATIVE, not a peso level" (`Import.hs` haddock) | Usually delta from an established baseline run | Shock is a *perturbation* on the baseline scenario's parameter vector, never an absolute replacement — table stakes, consistent across all three reference ecosystems and this project's own consumer |

## Feature Dependencies

```
Extracted `kalecky` package (the data resource prerequisite)
    └──requires──> Typed claim ADT + JSON codec
    └──requires──> Typed shock ADT + JSON codec (units)

Typed claim ADT ──enables──> Claim→shock mapping (per claim class)
Typed shock ADT ──enables──> Claim→shock mapping (per claim class)
                                  └──requires──> KaleckianKernel parameter-vector definition
                                                     └──requires──> Sarmiento/Colombia instance

the macro data resource read API (the data resource staging schema) ──requires──> Grounded shock magnitudes
                                                                            └──enables──> "no hardcoded literal" invariant tests

JSON-RPC protocol conformance (initialize/session-prompt/session.event) ──requires──> Haskell SDK protocol types (d2p-finance, currently a scaffold)
                                                                              └──enables──> Fake-harness-runtime test suite

Claim→shock mapping (all classes) ──enables──> Property tests (dimensional consistency, sign conventions)
Formalization artefact (math ↔ type doc) ──enhances──> Claim→shock explainability, but does not gate runtime behavior

Solving the model (GAMS bridge) ──conflicts──> Plugin solving the model itself (anti-feature)
Free-text claim/shock IO ──conflicts──> Deterministic, testable claim→shock mapping
```

### Dependency Notes

- **Typed claim/shock ADTs require the extracted `kalecky` package:** both PROJECT.md and the data resource's own plan name this extraction as a Phase-0 gate; this plugin cannot define dimensionally-honest types before it lands, and must not fork a temporary substitute given the explicit "no third dimensional system" constraint.
- **Grounded shock magnitudes require the the macro data resource read API:** the ETL's staging schema is the only source of real Colombian series; until it exposes a stable read surface, claim classes that need live data cannot be implemented without violating the "no hardcoded illustrative literals" constraint — this is a hard external dependency, not a design choice.
- **KaleckianKernel parameter-vector definition must precede claim→shock mapping implementation:** the mapping's output type *is* a perturbation of the kernel's parameter vector, so the vector's shape (informed by the existing GAMS-bridge closure: `a0`, `a1`, `g0`, `g1`, `g2`, `pi_anchor`, `tau_consumer`, `tau_producer`) has to be fixed first.
- **Solving the model conflicts with the plugin's scope:** this is a hard boundary, not a soft preference — the GAMS bridge already owns solving, and blurring the line would duplicate tested solver logic and confuse where a wrong number came from (bad translation vs. bad solve).
- **Free-text IO conflicts with determinism and testability:** these two requirements are structurally incompatible with each other; picking typed ADTs on both ends is what makes the property-test suite (an explicit project requirement) possible at all.

## MVP Definition

### Launch With (v1)

Minimum viable product — enough to validate that a claim really does become a grounded, typed shock through the harness protocol.

- [ ] JSON-RPC `initialize`/`session/prompt`/`session.event` handling against a scripted fake harness runtime (no real `dsh` process needed for CI)
- [ ] One claim class end-to-end — markup/distribution is the strongest candidate since PROJECT.md already names its closure (`P = (1+m)·wL/Y`) and its target parameter (`pi_anchor`) already exists with a derivation note in the sibling GAMS bridge
- [ ] Typed claim ADT + JSON codec (even if only one constructor is populated at launch, the type is closed and extensible by adding constructors, not by loosening the schema)
- [ ] Typed shock ADT + JSON codec with `kalecky` units, band (`value_low`/`value_high`), and `is_assumed` flag
- [ ] Read path into the macro data resource staging schema for the one supported claim class's grounding data — no hardcoded literals
- [ ] `KaleckianKernel` skeleton (state/parameters/closure) with the Colombia/Sarmiento instance wired to the one supported claim class
- [ ] Codec round-trip tests + at least one dimensional-consistency property test on the one supported mapping

### Add After Validation (v1.x)

- [ ] Remaining claim classes (demand-regime, external-constraint, productive-structure) — add once the markup/distribution path proves the ADT shape and the data-grounding pattern hold up
- [ ] Formalization artefact (LaTeX/markdown) per claim class, written once the class's mapping is stable enough to document without near-term rework
- [ ] Full property-test suite across all supported claim classes (sign conventions, dimensional consistency) — trigger: two or more claim classes exist, so cross-class invariants become meaningful to test

### Future Consideration (v2+)

- [ ] A second country `KaleckianKernel` instance — defer until a second country's the data resource-equivalent data source exists; building it earlier would force illustrative literals
- [ ] Multi-period/path shocks (beyond the current single-scenario-year v1 scope) — defer until the GAMS bridge itself grows path-solving beyond its own current single-period v1 scope, since there is no consumer for a richer shock shape yet
- [ ] Any richer bridging of intermediate claim-parsing steps into the parent session log — defer until/unless the harness's subagent seam itself grows a documented mechanism for it (currently explicitly out of scope for out-of-process providers)

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| JSON-RPC protocol conformance | HIGH | MEDIUM | P1 |
| Typed claim ADT + codec (one class) | HIGH | MEDIUM | P1 |
| Typed shock ADT + codec (units, bands, assumed-flag) | HIGH | MEDIUM | P1 |
| the macro data resource grounded magnitudes (no literals) | HIGH | MEDIUM-HIGH | P1 |
| `KaleckianKernel` skeleton + Colombia instance | HIGH | MEDIUM | P1 |
| Codec round-trip + one property test | HIGH | LOW | P1 |
| Remaining claim classes | MEDIUM-HIGH | MEDIUM per class | P2 |
| Full property-test suite across classes | MEDIUM | MEDIUM | P2 |
| Formalization artefact (LaTeX/markdown) | MEDIUM | LOW-MEDIUM | P2 |
| Second country kernel instance | LOW (v1 has no consumer) | HIGH | P3 |
| Multi-period shocks | LOW (no downstream consumer yet) | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Sources

**Harness surface (read directly, HIGH confidence):**
- `/home/jmsbpp/ai-agents/deepseek-harness/docs/architecture.md`
- `/home/jmsbpp/ai-agents/deepseek-harness/docs/cordis-primer.md`
- `/home/jmsbpp/ai-agents/deepseek-harness/docs/cordis-tutorial/01-first-plugin.md`
- `/home/jmsbpp/ai-agents/deepseek-harness/packages/subagent/subagent-dsh-sdk/README.md`
- `/home/jmsbpp/ai-agents/deepseek-harness/.agents/notes/implemented/feature/2026-06-21-subagent-capability-seam.md`
- `/home/jmsbpp/ai-agents/deepseek-harness/.agents/notes/implemented/feature/2026-07-27-typescript-sdk-and-sdk-subagent-backend.md`
- `/home/jmsbpp/ai-agents/deepseek-harness/.agents/notes/implemented/feature/2026-07-12-subagent-persona-tool-filter-and-depth.md`
- `/home/jmsbpp/ai-agents/deepseek-harness/.agents/notes/implemented/architecture/2026-07-20-canonical-tool-output-contract.md`

**Sibling/consumer code (read directly, HIGH confidence for what it establishes as this codebase's own convention):**
- `/home/jmsbpp/mamertomics-monorepo/src/mamertomics-gams-bridge/src/Mamertomics/Gams/Types.hs`
- `/home/jmsbpp/mamertomics-monorepo/src/mamertomics-gams-bridge/src/Mamertomics/Gams/Manifest.hs`
- `/home/jmsbpp/mamertomics-monorepo/src/mamertomics-gams-bridge/src/Mamertomics/Gams/Import.hs`
- `/home/jmsbpp/mamertomics-monorepo/src/mamertomics-gams-bridge/test/fixtures/scenario-baseline-2023.json`

**Project context (read directly):**
- `/home/jmsbpp/mamertomics/sarmiento-plugins/.planning/PROJECT.md`
- `/home/jmsbpp/the data resource/.planning/PROJECT.md`
- `/home/jmsbpp/mamertomics-monorepo/CLAUDE.md`

**Web-verified (MEDIUM confidence):**
- [Shocks on exogenous variables (Dynare Reference Manual)](https://archives.dynare.org/manual/Shocks-on-exogenous-variables.html) — `shocks` block syntax (`var`/`stderr` for stochastic, `periods`/`values` for deterministic)
- [4. The model file — Dynare 7.1 documentation](https://www.dynare.org/manual/the-model-file.html)
- [A note on Heterodox Macroeconomics by Blecker and Setterfield](https://www.elgaronline.com/view/journals/ejeep/17/3/article-p286.xml) — confirms Blecker & Setterfield (2019) as the standard reference covering Bhaduri–Marglin wage-led/profit-led demand-regime typology
- [Heterodox Macroeconomics: Models of Demand, Distribution and Growth — Google Books](https://books.google.com/books/about/Heterodox_Macroeconomics.html?id=1oe4DwAAQBAJ)

**Training-data synthesis, not independently web-verified this pass (LOW-MEDIUM confidence, flagged for validation against Sarmiento's actual texts during requirements):**
- The four-class claim taxonomy (demand-regime, markup/distribution, external-constraint, productive-structure) and its mapping onto the existing GAMS-bridge parameter vector (`a0`, `a1`, `g0`, `g1`, `g2`, `pi_anchor`, `tau_consumer`, `tau_producer`)
- Onaran–Galanis empirical wage-led/profit-led demand-regime estimation as the applied counterpart to Bhaduri–Marglin's theoretical mechanism

---
*Feature research for: DeepSeek Harness contained-agent plugin translating Sarmiento claims into Kaleckian shocks*
*Researched: 2026-08-25*
