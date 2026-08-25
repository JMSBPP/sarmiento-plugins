# Architecture Research

**Domain:** Haskell out-of-process DeepSeek Harness (Cordis) integration + typed Post-Keynesian/Kaleckian domain model
**Researched:** 2026-08-25
**Confidence:** HIGH on the wire-side question (read directly from `deepseek-harness` source + two Agent Notes); MEDIUM-HIGH on internal layering and `KaleckianKernel` design (derived from evidence in `mamertomics-core` + `kalecky-spec`, extrapolated since neither dependency has a real API yet); LOW on the exact `haskell-deepseek-plugin-sdk` surface (upstream is a `stack new` scaffold — this document specifies what it *must* expose, not what it does today)

## Part 1 — The Wire-Side Question (answered with evidence)

### What the harness repo actually shows

Read directly from `~/ai-agents/deepseek-harness` (a full checkout of `github.com/deepseek-ai/deepseek-harness`):

- **`packages/sdk/protocol/src/types.ts`** defines exactly one request/response surface, `HarnessSdkRequestMap`:
  ```
  'initialize'      : { params: InitializeParams;      result: InitializeResult }
  'session/prompt'  : { params: SessionPromptParams;    result: SessionPromptResult }
  'shutdown'        : { params: undefined;              result: {} }
  ```
  and one notification surface, `HarnessSdkNotificationMap`: `session.event`, `session.status`, `subagent.started`, `subagent.finished`. There is **no `cancel` method** (confirmed both in `types.ts` and independently in `.agents/notes/.../2026-07-27-typescript-sdk-and-sdk-subagent-backend.md`: *"the wire still has no cancel method"*).

- **`packages/sdk/protocol/src/transport.ts`** (`JsonRpcLineTransport`) is transport-symmetric: it implements newline-delimited JSON-RPC 2.0 over any `Readable`/`Writable` pair, with `request()`/`notify()`/`onRequest()`/`onNotification()`. The transport class itself does not force a role — but the request map above is asymmetric: **only one side of the wire can meaningfully answer `initialize`/`session/prompt`**, because doing so requires being a running harness (agent orchestration, LLM provider, tool loop, session persistence).

- **The Agent Note `2026-07-27-typescript-sdk-and-sdk-subagent-backend.md`** is decisive. It documents three new TypeScript packages built to let TS consumers do what only Python could do before:
  - `@deepseek-ai/dsh-sdk-protocol` — the wire types (above), extracted so **the server's own `notify()` call sites are typed against these payloads** (i.e., `dsh-sdk-jsonrpc-server`, a TypeScript/Cordis package, is the sole implementer of the *server* role — it is not a generic stub, it is the entire harness runtime compiled to a single executable, per the referenced single-file-executable Agent Note).
  - `@deepseek-ai/dsh-sdk-client` — *"the TypeScript twin of `python/sdk`"*: `HarnessClient`/`DeepSeekHarness`/`HarnessSession`. This is explicitly a **client**: it spawns the server as a subprocess, sends `initialize` + `session/prompt`, and fans out `session.event`/`subagent.*` notifications. Its own doc string: *"the client runs outside any harness context, so it cannot ride `ctx.subprocess`"* — it owns its own stdin-EOF → SIGTERM → SIGKILL teardown ladder because it is not itself a harness plugin.
  - `@deepseek-ai/dsh-subagent-dsh-sdk` — the `SubagentProvider` backend used when a **parent** harness delegates to **a child that is a complete second harness runtime with its own `cordis.yml`**. Crucially: *"same all-false capabilities and `inheritsParentContext: false`"* and *"this backend spawns through the SDK client"* — i.e., internally it is itself a `dsh-sdk-client` consumer. The child is always another instance of the same TypeScript Cordis harness; the note gives no path for a foreign-language process to assume the child role directly, because the child role requires running the full plugin tree (agent + LLM adapter + tools + session log), which only exists in the `dsh-sdk-jsonrpc-server` package.

- **`docs/subsystems/subprocess.md`** confirms process-spawning ownership: `ctx.subprocess` is a Cordis service used *inside* a running harness to spawn managed children (bash, LSP, PTY, the ACP subagent backend). The SDK client is explicitly the **documented exception** — it runs "outside any harness context" and spawns via plain OS process APIs, not `ctx.subprocess`, because it is not itself inside a Cordis context.

### Conclusion: which side of the wire the Haskell process sits on

**The Haskell process is a JSON-RPC CLIENT — the Haskell twin of `dsh-sdk-client`/`python/sdk` — never a server, and never the literal "child" of `subagent-dsh-sdk`.**

Evidence chain:
1. Serving `initialize`/`session/prompt` requires being a complete Cordis harness runtime (LLM providers, tool loop, session persistence) — that machinery lives only in `dsh-sdk-jsonrpc-server` (TypeScript, npm). Reimplementing it in Haskell would mean rebuilding the entire deepseek-harness, which is explicitly out of scope for `sarmiento-plugins` (PROJECT.md: *"Cordis/TypeScript plugin implementation — the plugin is Haskell over JSON-RPC, not an in-process Cordis plugin"*).
2. `subagent-dsh-sdk`'s child is documented as *"a complete harness runtime with its own `cordis.yml`"* — i.e., another TypeScript process, not a generic protocol endpoint. There is no evidence in the harness repo of a foreign-process child role.
3. The one role in this subsystem explicitly designed to run **outside** a harness process, own its own process lifecycle, and speak `initialize`/`session/prompt` as a caller is the SDK **client** (`dsh-sdk-client`/`python/sdk`). This is the only role with a documented Haskell-shaped analog.

**What "contained agent with specific context" means in practice, then:** the Haskell process spawns its own dedicated child harness process (its own `cordis.yml`: provider, model, tools, workspace, system prompt tuned for Sarmiento-claim analysis), drives it through exactly one bounded `initialize` → `session/prompt` → drain-`session.event`-until-terminal exchange per invocation, and tears the child down. The "contained agent" is the **child harness process configured by `cordis.yml`**, not the Haskell process itself; the Haskell process is the **driver/automation** around it — functionally equivalent to what `subagent-dsh-sdk`'s provider-side logic does inside a parent harness, but standing alone as an external Haskell program instead of a TypeScript Cordis plugin. Update PROJECT.md's framing accordingly: `sarmiento-plugins` is not "a plugin that IS an agent," it is a Haskell program that **operates** one.

### What `d2p-finance/haskell-deepseek-plugin-sdk` must therefore expose

Mirroring `@deepseek-ai/dsh-sdk-client`'s TypeScript surface, layered as four modules:

| Module | Responsibility | TS analog |
|---|---|---|
| `DeepSeek.Harness.Protocol.Types` | `InitializeParams/Result`, `SessionPromptParams/Result`, the four notification payloads, Aeson codecs matching the wire's camelCase field names verbatim | `packages/sdk/protocol/src/types.ts` |
| `DeepSeek.Harness.Protocol.Transport` | Newline-delimited JSON-RPC 2.0 over `Handle`s: request/response correlation by id, notification dispatch, `flush`; `JsonRpcResponseError` preserving wire `code`/`data` | `packages/sdk/protocol/src/transport.ts` (`JsonRpcLineTransport`) |
| `DeepSeek.Harness.Client.Process` | Explicit launch spec (`command`, `args`, `cwd`, `env` — **replace, not merge**, matching the TS client's documented asymmetry: "callers own credential policy"), spawn via `System.Process`, own the stdin-EOF → SIGTERM → SIGKILL teardown ladder | `packages/sdk/client/src/client.ts` (`HarnessClient`) |
| `DeepSeek.Harness.Client.Session` | Lazy start, memoized `initialize`, `runTurn :: [ContentBlock] -> IO TurnResult` — sends one `session/prompt`, accumulates `session.event`s until a terminal turn-end event, returns the final assistant message + structured stop reason; **no cancel** (the wire has none — client-side timeout only, settling locally without server-side effect, matching `RequestTimeoutError`'s documented behavior) | `packages/sdk/client/src/api.ts` (`HarnessSession`) |

No `subagent.started`/`subagent.finished` handling is required unless the Sarmiento child harness itself spawns nested subagents (not planned) — `session.event` and `session.status` are the only notifications this project's client needs to consume.

## Part 2 — Internal Layering

### System Overview

```
┌──────────────────────────────────────────────────────────────────────────┐
│  sarmiento-plugins (Haskell process, the DRIVER)                         │
│                                                                            │
│  ┌────────────┐  ┌───────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │ Protocol   │  │  Claim    │  │ Data-         │  │ Claim -> Shock    │  │
│  │ Adapter    │◄─┤  Parser   │  │ Grounding     │◄─┤ Translator         │  │
│  │ (SDK       │  │ (input    │  │ (ETL staging  │  │ (deterministic,    │  │
│  │  client)   │  │  ADT +    │  │  schema query)│  │  per claim class)  │  │
│  └─────┬──────┘  │  JSON     │  └───────┬───────┘  └─────────┬─────────┘  │
│        │         │  codec)   │          │                    │            │
│        │         └───────────┘          │                    │            │
│        │                                 ▼                    ▼            │
│        │                        ┌─────────────────────────────────────┐  │
│        │                        │        KaleckianKernel (typeclass)  │  │
│        │                        │        Sarmiento :: Country instance│  │
│        │                        └────────────────┬────────────────────┘  │
│        │                                          ▼                       │
│        │                                 ┌──────────────────┐             │
│        │                                 │   Shock Codec     │             │
│        │                                 │  (ADT + Aeson,    │             │
│        │                                 │   kalecky units)  │             │
│        │                                 └──────────────────┘             │
│        ▼                                                                  │
│  child harness process (spawned per invocation, its own cordis.yml)       │
└──────────────────────────────────────────────────────────────────────────┘
                │                                    │
                ▼                                    ▼
      DeepSeek Harness runtime            mamertomics-db (Supabase Postgres,
      (LLM, tools, session log)           owned by mamertomics-etl staging schema)
```

### Component Responsibilities

| Component | Responsibility | Talks to |
|---|---|---|
| **Protocol Adapter** | Owns the `haskell-deepseek-plugin-sdk` client surface: spawn child harness, `initialize`, `session/prompt`, drain `session.event`s, extract the prompt text (the Sarmiento claim, or a request to analyze one) and return the final assistant turn | Child harness process (stdio); Claim Parser (feeds it raw prompt text / receives formatted responses) |
| **Claim Parser** | Parses/validates the structured claim-input ADT (JSON in, from either the harness prompt or a direct API) into the typed `SarmientoClaim` sum type; owns the input JSON codec | Protocol Adapter (input side); Claim→Shock Translator (typed claim out) |
| **Data-Grounding** | Issues typed queries against the `mamertomics-etl` staging schema (via the ETL's exposed types/API — no second schema, no hardcoded literals) for exactly the series a claim class needs to size its shock | mamertomics-etl (Postgres client / RPC, TBD which); Claim→Shock Translator (supplies grounding data) |
| **Claim→Shock Translator** | One deterministic, testable function per claim class: `(SarmientoClaim, GroundingData) -> Either TranslationError ShockSpec` | Claim Parser (typed claim in), Data-Grounding (magnitudes in), KaleckianKernel types (shock shape out) |
| **KaleckianKernel** | Generic typed Kaleckian model interface (state, parameters, closure) that country instances implement; `Sarmiento` is the Colombian instance | Claim→Shock Translator (shock target vocabulary); Shock Codec (serializes kernel-typed shocks) |
| **Shock Codec** | Aeson `ToJSON`/`FromJSON` (or equivalent) for the output `ShockSpec`, carrying `kalecky`-typed magnitudes + `mamertomics-core`-typed provenance | Claim→Shock Translator (in); Protocol Adapter or a direct output channel (out — format TBD, PROJECT.md marks this "to be specified") |

### Reuse, not reinvention: `mamertomics-core` already has this shape

Reading `mamertomics-monorepo/src/mamertomics-core` surfaced a **pre-existing claim/shock ADT design** that this project should extend rather than duplicate:

- `Mamertomics.Core.TheoryGraph`: `NodeId` (closed, two-level: `IncomeDistribution IncomeDistributionClaim | InvestmentFirm ... | HarrodDomar ... | Financialization | EndogenousMoney | FiscalDeficit | Sollow | SectoralBalances`) is already a **claim taxonomy** — one constructor per theory-note file, sub-claims for notes with real internal structure. `Variable` is already the **closed shock-target vocabulary** (`MarkupM, WageShare, ProfitShare, RealWage, ProfitRate, CapacityUtil, CapitalStockVar, LaborLevel, LaborShare, FixedCostsLabor, ExcessInvestmentDemandVar`) — exactly the Kaleckian state vector `sarmiento-plugins`' PROJECT.md gestures at ("markup, wage share, autonomous demand, capacity utilization, external constraint").
- `Mamertomics.Core.Shock`: `VariableBinding` (a `NodeId` → `Variable` pointer), `ShockKind` (`LevelOverride | PercentChange | AdditivePerturbation`), `ShockSpec` (`TagOnly` for untyped/label-only shocks vs `NumericShock` carrying a `DataPoint` + `ShockKind`), and `PolicyEvent` (a dated, labeled shock — the minimum-wage-decree example is a complete worked instance of exactly the "claim → shock" pattern this project needs).
- `Mamertomics.Core.Provenance`/`DataPoint`/`Basis`/`Scale`/`Dimension` are the mandatory-provenance, type-safe-arithmetic, dimensionally-tagged value layer the ETL project's PROJECT.md flags as needing a Phase-1 "reuse vs converge" decision against `kalecky`.

**Recommendation:** `sarmiento-plugins`' claim-input ADT should be `NodeId`-shaped (a closed sum keyed to Sarmiento's specific claim classes — demand-regime, markup/distribution, external-constraint), and its shock-output ADT should extend `ShockSpec`/`VariableBinding`/`PolicyEvent` rather than invent a parallel vocabulary. This is a **cross-repo decision to raise explicitly in Phase 1 planning**, not merely a research note: either (a) `sarmiento-plugins` depends on `mamertomics-core` directly as a third git extra-dep, or (b) it forks the minimal claim/shock vocabulary it needs and keeps the two in sync by convention. Given the project already carries two moving-target extra-deps (the SDK, the ETL), adding a third live dependency raises the "stub blocking" risk found in Part 5 below — but *not* reusing `mamertomics-core`'s already-designed, already-reviewed `NodeId`/`Variable`/`ShockSpec` triad risks a second, drifting theory-graph taxonomy. The lower-risk path is: **vendor a frozen copy of `TheoryGraph.hs`+`Shock.hs`'s shape** (not the module, the *shape*) into `sarmiento-plugins`, scoped to only Sarmiento's claims, and reconcile with `mamertomics-core` later once both are stable.

### Where `kalecky` types travel

From `kalecky-spec/src/Kalecky/Types/*`: `Unit basis` (amount + `Scale`, `HasScale` per basis kind), `Currency` (type-level tag via DataKinds — `COP`/`USD` mixing is a compile error), `Measure`/`Agent` (type-level expectation-measure tag), `Valuation` (`Nominal | Real PriceIndex`, also type-level), `Price v a b` (a `CompoundUnit`/`Per` ratio parametrized by valuation), `Wage v c l = Price v (MoneyBasis c) l`. Operators: `GrowthRate` (exact `Rational` relative change), `Gap` (oriented expected-vs-realized difference, never realized-vs-realized).

Two concrete facts from reading the source, both load-bearing for this project's Shock Codec design:

1. **`kalecky`'s `Unit` cannot represent negative values, index numbers as first-class quantities (`PriceIndex` is an opaque tag), or USD amounts (`tradeableBase USD = Nothing`, deliberately deferred).** The `mamertomics-etl` PROJECT.md already documents the consequence at the staging-DB layer: `value_numeric NUMERIC` always plus kalecky-derived dimension columns plus a `dim_status` flag saying whether a kalecky value was constructible. **This project's Data-Grounding layer inherits that same gap**: a query against the ETL staging schema may return a grounding value that has no valid `kalecky.Unit`/`Price` construction (e.g., a negative discrepancy, a USD-denominated series). The Claim→Shock Translator must therefore accept `Either GroundingError GroundedValue` from Data-Grounding, not assume every queried series is kalecky-typed — and the Shock Codec's output ADT needs the same `dim_status`-shaped honesty (a shock magnitude with untyped/raw-numeric provenance is a valid, disclosed output, not a silently-dropped one).
2. **`kalecky`'s valuation/currency/measure gates are type-level (`DataKinds`), not runtime checks.** A `KaleckianKernel` state vector built from `kalecky` primitives (e.g., a wage-share shock as `Gap (AgentMeasure Firm) (Wage 'Nominal 'COP l)`) gets compile-time protection against mixing nominal/real or COP/USD magnitudes — but only if the kernel's own types are parametrized the same way. A `KaleckianKernel` typeclass/record whose methods are polymorphic over `v :: Valuation`/`c :: Currency` inherits this safety "for free"; one that erases to a bare `Double`/`Scientific` at the kernel boundary throws it away. This is a genuine design fork addressed in Part 3.

## Part 3 — `KaleckianKernel` Design

### Candidate shapes and the recommendation

Three encodings were considered; the record-of-functions (existential-record) shape is recommended, not a bare typeclass and not a GADT, for the following evidence-based reasons:

**1. Typeclass (`class KaleckianKernel country where ...`)** — idiomatic, but Haskell typeclasses give *global, coherence-checked* instances: exactly one `KaleckianKernel Sarmiento` instance can exist in scope anywhere the module is imported. That is fine for "one country, compiled in" but forecloses the stated future ("other countries could be" instances) from ever having two *variant* Colombian kernels (e.g., a research variant with a different closure) coexisting for A/B testing without a `newtype` wrapper per variant — which is itself the standard, low-cost Haskell answer, so this is not disqualifying, just a known cost.

**2. GADT (`data KaleckianKernel country where MkKernel :: ... -> KaleckianKernel country`)** — buys nothing here: GADTs earn their keep when different constructors carry genuinely different *type* shapes per case (e.g., "a `NumericShock` constructor requires a `DataPoint`, `TagOnly` doesn't" — the pattern `Mamertomics.Core.Shock.ShockSpec` already uses correctly for exactly that reason). A `KaleckianKernel` has one shape (state, parameters, closure) for every country; there is no branching structure a GADT would encode better than a plain record.

**3. Record-of-functions, closed over a phantom `country` type tag (recommended):**

```haskell
-- | The Kaleckian closure every country instance supplies.
-- Parametrized by an uninhabited phantom `country` tag so
-- `KaleckianState Sarmiento` and `KaleckianState Colombia2` (a future
-- research variant) are distinct types even with identical fields —
-- mirrors kalecky's own phantom-tag discipline (Amount c b, Unit basis).
data KaleckianState country = KaleckianState
  { ksMarkup            :: Unit (MarkupBasis country)         -- m
  , ksWageShare          :: Unit (ShareBasis country)          -- W/Y
  , ksProfitShare         :: Unit (ShareBasis country)          -- Pi/Y
  , ksCapacityUtil        :: Unit (UtilBasis country)           -- u
  , ksAutonomousDemand    :: Wage 'Nominal (CountryCurrency country) l  -- or a Price-shaped analog
  , ksExternalConstraint  :: ExternalConstraintValue country
  }

data KaleckianParams country = KaleckianParams
  { kpPropensityToSave    :: GrowthRate (KaleckianState country)  -- s, exact Rational
  , kpInvestmentSensitivity :: GrowthRate (KaleckianState country) -- accelerator coefficient
  , kpExternalElasticities :: ExternalElasticities country
  }

-- | The generic kernel: a record of pure functions closing the model
-- for one country, plus the shock-application map every claim
-- translator targets.
data KaleckianKernel country = KaleckianKernel
  { kkClose        :: KaleckianParams country -> KaleckianState country -> ClosureResult country
    -- ^ I^d - S -> the closure's excess-demand residual
  , kkApplyShock   :: ShockSpec -> KaleckianState country -> Either ShockApplicationError (KaleckianState country)
    -- ^ Reuses Mamertomics.Core.Shock's ShockSpec/Variable vocabulary
    -- (Part 2): applying a shock is total over the closed Variable set,
    -- so an out-of-scope Variable for this country is a genuine
    -- Left, not a partial-function crash.
  , kkRegime       :: KaleckianState country -> DemandRegime
    -- ^ wage-led vs profit-led classification, per Blecker & Setterfield
  }

-- | Uninhabited phantom tag — Sarmiento never has a runtime value,
-- only types are indexed by it.
data Sarmiento

sarmientoKernel :: KaleckianKernel Sarmiento
sarmientoKernel = KaleckianKernel { kkClose = ..., kkApplyShock = ..., kkRegime = ... }
```

**Why this shape wins on the evidence gathered:**
- It matches `kalecky`'s own idiom exactly: every kalecky type (`Unit basis`, `Amount c b` in `mamertomics-core`, `Price v a b`) is a phantom-tagged newtype/record with smart constructors, never a typeclass method dispatched on the tag. A `KaleckianKernel country` record is the same pattern one level up.
- It lets `kkApplyShock` be written once against the **existing** `Mamertomics.Core.Shock.ShockSpec`/`VariableBinding`/`Variable` vocabulary (Part 2's reuse recommendation) without needing a typeclass method per shock kind — the record field *is* the dispatch.
- Adding a second country later is "define a new phantom tag + a new `KaleckianKernel CountryTag` value" — no orphan-instance risk, no need to touch `Sarmiento`'s code, and multiple *variant* kernels for the same country are just multiple values of the same type, not multiple modules each defining a conflicting instance.
- Testability: `sarmientoKernel :: KaleckianKernel Sarmiento` is an ordinary value; property tests (already an "Active" requirement in PROJECT.md — "property tests on claim→shock invariants") can be written directly against its fields with no typeclass-resolution indirection.

**Where a lightweight typeclass still earns its place:** a `KnownCountry country` singleton-bridge class (mirroring `kalecky`'s own `KnownCurrency`/`KnownMeasure`/`KnownValuation` pattern exactly) to recover a runtime `Country` tag (`Colombia | ...`) from the phantom type when provenance/logging needs it as a value, not just a type:

```haskell
class KnownCountry (c :: Type) where countryOf :: Proxy c -> Country
instance KnownCountry Sarmiento where countryOf _ = Colombia
```

This is the one place a typeclass is the right tool — for exactly the reason `kalecky` uses it three times already (`KnownCurrency`, `KnownMeasure`, `KnownValuation`): bridging a compile-time tag back to a runtime value for I/O/display, not for dispatching model logic.

## Part 4 — Data Flow and Where Provenance Travels

```
mamertomics-db (Supabase Postgres staging schema)
   │  typed series: value_numeric NUMERIC + kalecky-derived dimension
   │  columns + dim_status flag (per mamertomics-etl PROJECT.md)
   ▼
Data-Grounding query  ──────────────────────────────────────────┐
   │  returns: Either GroundingError                            │
   │            (GroundedValue { gvRaw :: Scientific             │
   │                           , gvKalecky :: Maybe (SomeAmount  │  <- kalecky/Amount-shaped
   │                                            or Some Unit)     │     value, absent per dim_status
   │                           , gvProvenance :: Provenance })   │  <- Mamertomics.Core.Provenance,
   ▼                                                              │     carried through UNCHANGED
Claim→Shock Translator                                           │
   │  input: SarmientoClaim (typed, from Claim Parser)           │
   │  input: GroundedValue (above)                                │
   │  output: Either TranslationError ShockSpec                  │
   │          (ShockSpec = Mamertomics.Core.Shock-shaped, Part 2) │
   ▼                                                              │
KaleckianKernel.kkApplyShock                                      │
   │  applies ShockSpec to KaleckianState Sarmiento                │
   │  Provenance rides INSIDE the ShockSpec's DataPoint-adjacent   │
   │  payload (mirrors mamertomics-core: "every series embeds a    │
   │  single Provenance value... MANDATORY, no optional wrapper")  │
   ▼                                                              │
Shock Codec (Aeson)                                               │
   │  serializes: shock target (Variable), magnitude (DataPoint-  │
   │  shaped: NumericValue Scientific | ...), ShockKind, AND       │
   │  Provenance (downloadedAt, periodicity, sampleSize, initDate, │
   │  dimension, source) — verbatim, never summarized away         │
   ▼
Protocol Adapter → child harness process (session/prompt content,
   format TBD per PROJECT.md) OR a direct file/API output channel
```

**Provenance discipline, carried over from `mamertomics-core`'s own locked decision:** every value that reaches the Shock Codec's output MUST carry its six mandatory `Provenance` fields (`downloadedAt`, `periodicity`, `sampleSize`, `initDate`, `dimension`, `source`) — never a `Maybe Provenance`. This directly satisfies PROJECT.md's stated constraint: *"no hardcoded 'illustrative' numeric literals — magnitudes come from `mamertomics-db` with provenance, or the work stops."* Concretely: **`ShockSpec`'s `NumericShock` constructor needs a `Provenance` field added** relative to `mamertomics-core`'s current definition (today it carries only `DataPoint` + `ShockKind` — that is a monorepo-internal gap this project should NOT inherit silently; either extend the vendored copy, or flag it as a required upstream change if `mamertomics-core` becomes a real dependency).

**`kalecky` vs raw-numeric fork, and where it resolves:** because `kalecky.Unit`/`Price` cannot represent every value the staging schema might return (negatives, indices, non-COP currencies — see Part 2), the fork is resolved as early as possible, at Data-Grounding's boundary, and carried as an explicit `Maybe` all the way to the Shock Codec's output rather than being silently coerced or dropped. A shock magnitude with `gvKalecky = Nothing` is a legitimate, disclosed output (raw-numeric, no compile-time unit safety) — never a translation failure by itself.

## Part 5 — Keeping the Two Stub Dependencies From Blocking

Both `d2p-finance/haskell-deepseek-plugin-sdk` and `JMSBPP/mamertomics-etl` were directly inspected (Bash `find`) and confirmed, as of 2026-08-25, to be **bare `stack new` scaffolds** — `haskell-deepseek-plugin-sdk` has `src/Main.hs` printing hello-world and no library section in its `.cabal`; `mamertomics-etl` has `src/Lib.hs` and no exposed staging-schema API. Neither can be depended on for real functionality today, yet PROJECT.md commits to depending on both as pinned git extra-deps.

**Interface-first, local-stub strategy (concrete, not generic advice):**

1. **Define the two boundary contracts as this project's OWN internal modules first**, named to make the eventual swap mechanical:
   - `SarmientoPlugins.Harness.ClientContract` — the four-module shape from Part 1's table (`Types`/`Transport`/`Client.Process`/`Client.Session`), written and tested against a **fake harness runtime** (a second local executable that speaks the wire protocol just enough to answer `initialize`/`session/prompt`/emit `session.event` — directly analogous to `dsh-sdk-client`'s own `tests/fake-runtime.ts`, which this project should port line-for-shape, not invent independently).
   - `SarmientoPlugins.Data.StagingContract` — a typeclass or record-of-functions (`StagingReader { fetchSeries :: SeriesQuery -> IO (Either GroundingError GroundedValue), ... }`) whose only real implementation today is a **local Postgres fixture** (docker-compose Postgres seeded with a handful of known rows matching the ETL's documented staging shape), not the live Supabase project.

2. **Depend on the real packages as git extra-deps pinned to a specific commit from day one** (per PROJECT.md's own constraint), but gate all real usage behind the two contract modules above — no call site outside `SarmientoPlugins.Harness.*`/`SarmientoPlugins.Data.*` imports the upstream packages directly. When either upstream package grows a real library section, only those two modules' internals change.

3. **Bump discipline:** because both upstreams are pre-API, the pinned commit should be re-checked (not blindly bumped) at the start of each phase that depends on new upstream surface — this is a natural, low-overhead checkpoint rather than a CI job, since both repos are private/early and a bot-driven bump would just fail silently against a moving pre-1.0 target.

4. **kalecky is a THIRD implicit stub dependency** (not named as a direct dep in PROJECT.md, but load-bearing per Part 2/4): `kalecky-spec` today lives inside a hevm fork requiring `secp256k1`/`ff` C libraries (per `mamertomics-etl` PROJECT.md's own documented blocker) and has not yet been extracted into the standalone package both this project and the ETL need. **This project should not add a fourth dependency chain by importing kalecky directly before the ETL's Phase-0 extraction lands** — instead, the `GroundedValue`/kalecky-shaped fields in Part 4's data flow should be typed against a small **local vendored subset** (just `Unit`, `Currency`, `Valuation` phantom tags — no `Price`/`Wage` arithmetic needed for shock output, only for state representation inside `KaleckianKernel` if the team chooses the phantom-tagged `KaleckianState` from Part 3) until the standalone `kalecky` package exists, then swap the import.

## Part 6 — Suggested Build Order

Ordered by which components can be built and tested with zero real upstream dependency, deferring anything that needs a working `haskell-deepseek-plugin-sdk` or live `mamertomics-etl` staging schema as late as possible:

1. **Shock/claim vocabulary** — vendor or reuse `Mamertomics.Core.Shock`/`TheoryGraph`-shaped ADTs (Part 2), scoped to Sarmiento's claim classes; Aeson codecs; property tests on round-trips and claim→shock sign-convention invariants (an explicit PROJECT.md requirement) — **zero external dependency, buildable and testable on day one.**
2. **`KaleckianKernel` typed interface + `Sarmiento` instance** (Part 3) — pure functions, no I/O, testable against hand-constructed `KaleckianState`/`KaleckianParams` fixtures — **zero external dependency.**
3. **Local kalecky-subset vendoring** (Part 5, point 4) — the minimal phantom-tag types needed for `KaleckianState`'s fields, swappable later for the real standalone package.
4. **`StagingContract` + local Postgres fixture** (Part 5, point 2) — the Data-Grounding interface and its fake implementation; Claim→Shock Translator built and tested against the fixture, never the live Supabase project, until mamertomics-etl exposes a real API.
5. **`ClientContract` + fake harness runtime** (Part 5, point 1) — the Protocol Adapter interface and its fake implementation, ported from `dsh-sdk-client`'s own `tests/fake-runtime.ts` pattern; this is the component most exposed to upstream churn (developer-preview, breaking changes declared), so keeping it behind an interface with a fake is the highest-leverage decoupling point in the whole project.
6. **Wire the four components together** behind the two contract interfaces (still using fakes) — end-to-end claim-in/shock-out test, no live dependencies.
7. **Swap the `StagingContract` fixture for the real `mamertomics-etl` client** once the ETL's JSON-RPC daemon or exposed types exist — this is gated on the ETL's own roadmap, not on this project's internal work.
8. **Swap the `ClientContract` fake for the real `haskell-deepseek-plugin-sdk`** once upstream grows a library section — gated on `d2p-finance`'s own roadmap.
9. **CI on the private repo** (build + tests) — deferred until steps 1-6 are stable, since CI against two moving pinned-commit dependencies before their APIs stabilize will be noisy without earning anything.

This ordering directly serves PROJECT.md's own "Active" requirement list: the codec/property-test/protocol-conformance-against-a-fake-harness-runtime requirements are all reachable without either real upstream dependency, so the roadmap's earliest phases should be scoped to steps 1-6 above, with steps 7-9 explicitly flagged as blocked-on-external-roadmaps rather than schedulable.

## Sources

- `~/ai-agents/deepseek-harness/packages/sdk/protocol/src/types.ts` — wire request/notification maps (HIGH confidence, primary source, read directly)
- `~/ai-agents/deepseek-harness/packages/sdk/protocol/src/transport.ts` — `JsonRpcLineTransport` implementation (HIGH confidence, primary source)
- `~/ai-agents/deepseek-harness/docs/subsystems/subprocess.md` — `ctx.subprocess` seam, SDK-client-as-exception note (HIGH confidence, primary source)
- `~/ai-agents/deepseek-harness/.agents/notes/implemented/architecture/2026-07-26-subprocess-seam.md` — subprocess capability-seam rationale (HIGH confidence, primary source)
- `~/ai-agents/deepseek-harness/.agents/notes/implemented/feature/2026-07-27-typescript-sdk-and-sdk-subagent-backend.md` — decisive evidence for client-vs-server role and `dsh-subagent-dsh-sdk`'s child-is-a-full-harness design (HIGH confidence, primary source)
- `/home/jmsbpp/mamertomics-monorepo/src/mamertomics-core/src/Mamertomics/Core/{Provenance,DataPoint,Series,Shock,Basis,Scale,Dimension,TheoryGraph,Markup}.hs` — existing claim/shock/provenance/dimensional-safety ADT layer (HIGH confidence, primary source, read directly)
- `/home/jmsbpp/learning/kalecky-semantics/kalecky-spec/src/Kalecky/Types/{Units/Unit,Currency,Measure,Valuation,Prices/Wage,Prices/Price}.hs` and `Kalecky/Operators/{GrowthRate,Gap}.hs` — value-type layer, phantom-tag discipline, gap in negative/index/USD representation (HIGH confidence, primary source, read directly)
- `/home/jmsbpp/mamertomics/sarmiento-plugins/.planning/PROJECT.md` — project scope, constraints, key decisions (HIGH confidence, primary source)
- `/home/jmsbpp/mamertomics-etl/.planning/PROJECT.md` — ETL's staging schema, kalecky-extraction blocker, `dim_status` gap documentation (HIGH confidence, primary source)
- `~/ai-agents/haskell-deepseek-plugin-sdk` and `~/mamertomics-etl` repo trees — confirmed bare `stack new` scaffolds as of 2026-08-25 (HIGH confidence, verified directly via `find`)

---
*Architecture research for: Haskell out-of-process DeepSeek Harness plugin + typed Kaleckian domain kernel*
*Researched: 2026-08-25*
