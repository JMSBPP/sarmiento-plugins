# Pitfalls Research

**Domain:** Haskell DeepSeek Harness (Cordis) plugin — contained agent over JSON-RPC, reading a Supabase macro DB via a sibling ETL package, formalizing an economist's structuralist claims as typed Kaleckian shocks
**Researched:** 2026-08-25
**Confidence:** MEDIUM — protocol/transport and Stack-tooling findings are verified against official docs and multiple independent sources (HIGH); Supabase/Supavisor findings are verified against official Supabase docs (HIGH); economics-formalization pitfalls are derived from the project's own stated constraints and domain reasoning rather than an external ecosystem (this is a bespoke formalization, not a documented pattern — treat as MEDIUM and validate against `kalecky` test suite + Blecker & Setterfield as you go)

## Critical Pitfalls

### Pitfall 1: Building the real plugin against two hello-world stubs

**What goes wrong:**
Both upstream dependencies — `d2p-finance/haskell-deepseek-plugin-sdk` and `JMSBPP/mamertomics-etl` — are `stack new` scaffolds today (no library, no exposed API). Writing plugin code "against" them right now means writing code against an API that doesn't exist yet, then discovering the real shapes (session/prompt types, RPC method names, ETL query functions) weeks later and rewriting.

**Why it happens:**
The roadmap gets sequenced as if the SDK and ETL are stable dependencies to consume, when in fact this project and its two upstreams are being developed in parallel by the same author. It's tempting to start "plugin logic" work immediately because the repo itself is initialized and eager to show progress.

**How to avoid:**
Treat "upstream API exists and is pinned" as a hard gate, not a soft assumption. Early phases should build everything that does NOT require the SDK/ETL library surface: the claim ADT, the shock ADT, the `KaleckianKernel` interface, JSON codecs, and property tests — all of which only need `kalecky` (which does have a real API, per the ETL PROJECT.md). Anything touching `dsh-sdk-protocol` types or ETL query functions stays behind an explicit "upstream API landed" checkpoint, verified by re-reading the actual exposed modules (not assumed from the SDK's README) before writing code against them.

**Warning signs:**
- Plugin code imports symbols from the SDK or ETL that only exist in a local scratch branch of those repos, not in the pinned commit
- `stack build` starts failing after every upstream bump because the API shape changed
- Test doubles/fakes for the SDK or ETL drift further from the real thing over time because nobody re-syncs them

**Phase to address:**
Phase 0 (Dependency & Protocol Foundations) — establish the gate explicitly; re-verify at the start of any phase that touches SDK or ETL surface.

---

### Pitfall 2: Resolver/GHC divergence silently forked into three snapshots

**What goes wrong:**
SDK pins lts-22.43 (GHC 9.6), ETL pins lts-24.56 (GHC 9.10). If this project picks a third snapshot, or picks one and the other repo evolves independently without anyone re-checking, you get either a resolver that can't satisfy both git extra-deps' own `stack.yaml` constraints, or (worse) a resolver that silently builds but pulls incompatible transitive versions of `kalecky` or `aeson` between the two deps.

**Why it happens:**
Stack git extra-deps do not enforce that the dependency's own stated resolver matches the consumer's resolver — Stack solves against the consumer's snapshot regardless of what `stack.yaml` says inside the dependency repo. A project can "build" while silently using dependency code that was never tested against this GHC version.

**How to avoid:**
Pick lts-24.x now (matches the ETL, the newer/more-current snapshot, and is the dependency most likely to grow real API surface first) and treat "ask the SDK to follow" as a tracked, named task — not a hope. Add a CI job that fails loudly (not just warns) if `extra-deps` git commits are bumped without a corresponding resolver compatibility check. Never assume a successful `stack build` means the dependency was tested on this GHC — grep the dependency's own CI config for its actual tested GHC version when bumping.

**Warning signs:**
- `stack build` succeeds but with a flurry of "not tested with this resolver" or version-bound warnings for `kalecky` or SDK transitive deps
- A dependency bump changes behavior at runtime with no corresponding type error at compile time (classic signature-compatible-but-semantics-changed drift)

**Phase to address:**
Phase 0 (Dependency & Protocol Foundations).

---

### Pitfall 3: Treating a developer-preview protocol as stable

**What goes wrong:**
DeepSeek Harness is explicitly a developer preview that declares breaking changes, and the wire protocol has no `cancel` method. Code that assumes today's `initialize`/`session/prompt`/`session.event` shapes are final, or that assumes a running prompt can always be cancelled cleanly, will break on the next harness bump and has no correct way to implement "stop this in-flight computation" today.

**Why it happens:**
JSON-RPC method names and params look authoritative once you've written a Haskell ADT + codec for them, which creates false confidence that the surface is fixed. Teams also tend to assume "no cancel method" just means "we won't get a cancel request" rather than actively deciding what the plugin does if the harness process is killed mid-computation without a cancel notification.

**How to avoid:**
Isolate every wire-protocol type behind a thin adapter module so a breaking harness change is a localized diff, not a rewrite. Since there's no cancel method, design long-running work (e.g., the Supabase query underlying a shock) to be safely interruptible by process termination alone — no partial writes, no half-committed state, idempotent on retry. Document the assumed protocol version/commit the plugin was built against, and re-verify it explicitly on every SDK bump rather than assuming compatibility.

**Warning signs:**
- Plugin hangs indefinitely when the harness tears down without a clean notification
- A harness upgrade produces JSON decode failures on `initialize` or `session/prompt` that surface only at runtime, not compile time
- No test exercises "harness disappears mid-request" (SIGTERM/EOF) as a first-class case

**Phase to address:**
Phase 1 (JSON-RPC Transport Implementation).

---

### Pitfall 4: Private Stack git extra-dep auth, hpack/subdir quirks, and lockfile churn

**What goes wrong:**
`JMSBPP/mamertomics-etl` is private. Stack's git extra-deps clone over whatever git transport is configured — this works transparently on a laptop with an SSH key or cached credential helper, and then fails opaquely in CI with a generic "fatal: could not read from remote repository" that gives no hint it's an auth problem versus a bad commit pin. Separately, the ETL's own `kalecky` note (Stack cannot depend on Cabal sublibraries — `commercialhaskell/stack` issues #5318/#5256) is a live landmine one level removed: if `kalecky`'s extraction into a standalone package slips, `mamertomics-etl`'s own `stack.yaml` can't express it as a normal extra-dep, and this project inherits that breakage transitively the moment it tries to build ETL as a git dep. `stack.yaml.lock` also pins the exact resolved commit/subdir combination — every deliberate upstream bump touches this lockfile, and if it's not committed atomically with the bump, other developers/CI silently build against a stale pin.

**Why it happens:**
Local dev machines have long-lived git credentials that mask the auth requirement; hpack `subdirs`/`git` extra-dep syntax is easy to get subtly wrong (missing `subdirs:` when the package isn't at repo root); and lockfiles are the kind of generated file that's easy to `.gitignore` by habit or forget to re-commit after `stack build` regenerates it.

**How to avoid:**
Use a dedicated machine-user or fine-grained PAT with read-only access to `mamertomics-etl`, injected via `GIT_ASKPASS`/`.netrc`/SSH deploy key in CI — never a personal token — and fail CI explicitly (with a clear message) rather than let a generic git error stand in for "check the credential." Confirm `kalecky` has actually landed as a standalone package (not still a sublibrary) before pinning `mamertomics-etl` as an extra-dep that transitively needs it — this is a real prerequisite blocking on the ETL project's own Phase-0 gate, not just documentation. Commit `stack.yaml.lock` alongside every deliberate extra-dep bump, and add a CI check that fails if `stack.yaml` changed but the lock didn't (or vice versa, uncommitted drift).

**Warning signs:**
- `stack build` works locally, fails in CI with a git auth error
- `stack.yaml.lock` shows uncommitted changes after a routine `stack build` in a clean checkout
- Building `mamertomics-etl` as a dependency fails with a sublibrary/package-not-found error rather than a normal compile error

**Phase to address:**
Phase 0 (Dependency & Protocol Foundations) for CI auth + lockfile discipline; re-verify at every deliberate bump, not just once.

---

### Pitfall 5: JSON-RPC stdout pollution and buffering deadlocks

**What goes wrong:**
The line-transport contract (shared ancestry with LSP/MCP stdio transports) requires that literally nothing but valid, newline-delimited JSON-RPC messages ever touch stdout. Any `putStrLn` debug print, any library that logs to stdout by default (GHC RTS warnings, a database driver's verbose mode, an uncaught exception's default handler), or any stdout buffering that delays a full line from flushing, breaks the harness's parser or deadlocks the exchange (harness waiting for a response line that's sitting in an unflushed buffer).

**Why it happens:**
Haskell's default stdout buffering is often block-buffered when not connected to a terminal (i.e., exactly the pipe-connected case a subprocess plugin runs under), so output that looks fine when run interactively in a terminal silently buffers and never reaches the parent process in production. Debug `print`/`trace` calls are also easy to leave in during development, since they don't cause visible failures locally when stdout is a TTY.

**How to avoid:**
Set `hSetBuffering stdout LineBuffering` (or `NoBuffering` for strict correctness) explicitly at startup — never rely on the default. Route every log line, warning, and diagnostic to stderr exclusively; audit every dependency pulled in (especially the DB driver and any HTTP client used for Supabase) for anything that writes to stdout by default. Add a smoke test that runs the plugin as a real subprocess (not in-process) and asserts that stdout contains only well-formed JSON-RPC lines for the duration of a session.

**Warning signs:**
- Harness reports a JSON parse error / "unexpected token" on a line that should have been valid
- The exchange hangs with no error — classic symptom of a message sitting in an unflushed buffer
- A library dependency prints version banners, deprecation notices, or connection-pool logs "for free" on stdout

**Phase to address:**
Phase 1 (JSON-RPC Transport Implementation).

---

### Pitfall 6: No teardown ladder for EOF/SIGTERM, and notification ordering races

**What goes wrong:**
Two related transport bugs: (1) the plugin doesn't implement a clean shutdown ladder (drain in-flight work → flush stderr → close stdout → exit) for both "stdin closed" (EOF, harness went away) and SIGTERM (harness explicitly killing the child), so it either hangs as a zombie or gets force-killed mid-write, corrupting a partially-written line; (2) if the plugin emits `session.event` notifications concurrently with responding to a request (e.g., streaming progress while computing a shock), unsynchronized writers can interleave two JSON objects onto stdout, producing a line that is neither valid message — a protocol-fatal error, not a recoverable one, because there's no cancel/resync method on this wire.

**Why it happens:**
Haskell's lightweight threads make it easy to fire off a notification from a worker thread without realizing that writes to the same `Handle` from multiple threads need explicit serialization; EOF and signal handling are easy to skip entirely in a first cut ("it works when I Ctrl-C it locally") and never revisited once the happy path works.

**How to avoid:**
Serialize all stdout writes through a single writer (e.g., an `MVar`-guarded handle or a bounded queue with one consumer thread) so no two messages can ever interleave, regardless of which thread produced them. Install both an EOF handler on stdin (treat as "harness gone, begin teardown") and a `SIGTERM` handler (`System.Posix.Signals` or `installHandler`) that trigger the same teardown ladder: stop starting new work, let in-flight DB queries finish or cancel cleanly, flush, exit with a defined code. Write an explicit integration test that sends SIGTERM mid-request and asserts no partial/interleaved line was ever written.

**Warning signs:**
- Killing the harness process leaves an orphaned plugin process still running
- Two concatenated JSON objects appear on one line under load/concurrency testing
- The plugin's exit code is always 0/1 regardless of how it was actually terminated

**Phase to address:**
Phase 1 (JSON-RPC Transport Implementation).

---

### Pitfall 7: Supavisor transaction-mode pooling silently breaks correctness, not just perf

**What goes wrong:**
If the plugin connects through Supabase's transaction-mode pooler (port 6543) instead of the session-mode pooler (5432) or the direct host, prepared statements can fail or behave inconsistently — Supavisor's transaction mode reassigns physical connections between logical sessions, so a prepared statement created on one physical connection may not be visible when a later logical query executes on a different one, even mid-session. `postgresql-simple` (the likely Haskell client) uses server-side prepared statements by default for parameterized queries, so this isn't a hypothetical edge case — it's the default code path. The ETL project has already documented and worked around this (session-mode pooler for its daemon); this plugin must independently make the same correct choice, not silently default to whatever connection string looks simplest to hardcode.
Separately: the direct host (`db.<ref>.supabase.co`) is IPv6-only without the paid IPv4 add-on — a plugin dev/CI environment without IPv6 egress will get connection timeouts that look like a firewall problem, not a protocol-family problem.

**Why it happens:**
Connection-pooler documentation defaults and marketing lead with the transaction-mode pooler as "the scalable option," and it's the connection string most likely to be copy-pasted from a Supabase dashboard without reading the prepared-statement caveat. IPv6-only failures are especially confusing because `psql` or a browser test against a *different* Supabase endpoint (the pooler, which is IPv4-reachable) can succeed while the direct host silently doesn't work in the same environment.

**How to avoid:**
Default to the session-mode pooler (5432) for this plugin's read path, matching the ETL's own resolved decision, and treat "switch to transaction mode for throughput" as a deliberate, tested opt-in later — never a default. If direct-host access is ever needed (e.g., for a migration-adjacent read), verify IPv6 egress in the target environment (dev laptop, CI runner) before assuming a connection failure is a credentials problem. Require SSL (`sslmode=require` or stronger) explicitly rather than relying on a driver default that may vary between `postgresql-simple`/`hasql`/`resource-pool`-based stacks.

**Warning signs:**
- Prepared-statement or parameterized queries intermittently return stale or wrong results, or throw "prepared statement already exists"/"does not exist" errors, only under concurrent load
- Connection attempts to the direct host succeed from one network but time out from another (CI vs laptop) with no other symptom
- SSL is silently disabled because a connection string was copied without the parameter, and nobody diffed it against the ETL's already-solved config

**Phase to address:**
Phase 2 (Data Access Layer) — before any query code is written, not discovered after the first flaky-test bug report.

---

### Pitfall 8: Hardcoded "illustrative" numbers smuggled in as if grounded

**What goes wrong:**
Under time pressure ("I just need to see the JSON codec round-trip"), it's tempting to write a shock output with a plausible-looking magnitude (e.g., `markupShock = 0.03`) as a placeholder — and then never come back to wire it to a real `mamertomics-db` query, or worse, ship it. This project's own constraints explicitly forbid this ("no hardcoded 'illustrative' numeric literals — magnitudes come from `mamertomics-db` with provenance, or the work stops"), and the predecessor monorepo has the identical rule for the same reason: it has already been an ongoing discipline problem in this economist's toolchain, not a hypothetical risk.

**Why it happens:**
Placeholder values are the path of least resistance when the ETL API isn't ready yet (see Pitfall 1) — a developer wants forward progress on the claim→shock mapping logic without being blocked on data access, so a stand-in number creeps in and, once tests pass against it, there's no forcing function to replace it before it looks "done."

**How to avoid:**
Make the type system enforce the rule where possible: a shock value's constructor should require a provenance/query-reference field (not just a bare `Double`), so a hardcoded literal is a visible type-level anomaly (e.g., `Provenance = Unverified` with a mandatory review flag) rather than indistinguishable from a real grounded value. Any test fixture using illustrative numbers must be clearly named and isolated from "this compiles, therefore it's grounded" claims in status reports. Treat "no data source available yet" as a blocking question to surface, exactly as the constraint says, not a reason to fabricate a plausible number and move on.

**Warning signs:**
- A shock value has no accompanying provenance/query reference in code or tests
- Status updates describe claim→shock logic as "working" when the underlying data path is still a stub
- A magic-number literal appears in production code (not a clearly-marked test fixture) for anything the plugin is supposed to compute from real data

**Phase to address:**
Phase 3 (Claim/Shock Type Design) — bake provenance into the type from the start; Phase 4 (Formalization) verifies no literal slipped through.

---

### Pitfall 9: Unit, basis, and sign mismatches presented as validated

**What goes wrong:**
Colombian macro series mix nominal COP, real (deflated) COP, and index numbers (base-year-normalized, unitless) — and `kalecky`'s own documented gap is that `PriceIndex` is an opaque tag, not a full dimensional type, so index-vs-currency confusion is not fully caught by the type system today. A shock computed from a nominal series but interpreted as real (or vice versa) will type-check and produce a plausible-looking number that is economically wrong. Sign conventions compound this: whether "markup shock = +0.02" is expansionary or contractionary depends on the demand regime (wage-led vs profit-led) implied by the rest of the closure — a shock module that hardcodes one sign convention regardless of regime will silently misrepresent claims that describe the opposite regime.

**Why it happens:**
Dimensional-analysis type systems close the "you added COP to a growth rate" class of bug, but they don't close the "you deflated with the wrong index" or "you assumed a regime" class of bug, because those require economic domain knowledge that isn't encoded in the type — it's a modeling decision. This is exactly the kind of error that looks fine in a code review by someone without the economics context, and fine in an economics review by someone without visibility into which series was actually queried.

**How to avoid:**
Every claim→shock translation must state, in code (not just prose comments), which valuation basis (nominal/real) and which regime assumption it depends on, and that must be checked against the queried series' actual `dim_status`/valuation metadata from the ETL staging schema at runtime, not assumed. Property tests should include basis-mismatch cases as explicit negative tests (e.g., "computing this shock from a nominal series when the claim requires real should fail loudly, not silently produce a number"). Treat `PriceIndex`'s "opaque tag" gap as an active risk area requiring extra scrutiny in this project specifically, since it sits directly in the claim→shock path.

**Warning signs:**
- A shock's magnitude looks "off by an order of magnitude" or has an implausible sign when sanity-checked against the source claim's plain-English direction
- No test exercises what happens when a real-valued claim is fed a nominal series (or vice versa)
- Regime assumption (wage-led/profit-led) is implicit in code rather than an explicit, inspectable parameter

**Phase to address:**
Phase 4 (Claim→Shock Formalization).

---

### Pitfall 10: Over-claiming a deterministic "mapping" that is actually a modeling choice

**What goes wrong:**
The requirement is "a deterministic, testable translation into a shock" for each claim class. There's a real risk of over-selling what this can be: Sarmiento's structuralist claims are prose, often qualitative and directional ("distribution has shifted against wages," "the external constraint binds"), not pre-quantified. Any function that turns such prose into a single numeric shock is making a modeling choice about magnitude, not discovering one — and presenting that choice as "the mapping" (implying uniqueness/correctness) rather than "a documented, testable interpretation" overstates what's actually been built. This is the formalization-project version of the same "no hardcoded illustrative numbers" discipline, one level up: the danger isn't a fake number, it's a real number computed by an unexamined, unstated interpretive step.

**Why it happens:**
"Deterministic, testable translation" is a satisfying engineering framing that quietly elides the fact that going from prose to a parameter perturbation requires an economic judgment call (how much markup change does "distribution has shifted against wages" imply, quantitatively, given the queried data?) that itself needs to be documented and defensible, not just implemented.

**How to avoid:**
For each claim class, the formalization artefact must document the interpretive step explicitly — what judgment call turns "claim + queried series" into "shock magnitude," and why that judgment call is defensible — alongside the code, not as an afterthought. Frame outputs as "shock under interpretation X" with the interpretation inspectable/citable, rather than implying a single canonical mapping exists. Where a claim is genuinely under-determined by available data (no series exists to ground a magnitude), that is exactly the "work stops, question surfaced" case from the data-integrity constraint — not a case for inventing an interpretation to fill the gap.

**Warning signs:**
- The formalization doc describes the mapping as "the" translation rather than "a" documented interpretation
- No traceable link from a specific sentence/claim class to the specific queried series and specific interpretive rule that produced a given shock
- A claim class produces a shock even though no grounding data exists for the specific magnitude implied

**Phase to address:**
Phase 4 (Claim→Shock Formalization) — this is the core deliverable risk of the whole project, not a side concern.

---

### Pitfall 11: Forking a third dimensional/units system instead of converging on `kalecky`

**What goes wrong:**
The ETL project already flags unresolved overlap between `kalecky` (values/units) and `mamertomics-core` (provenance/temporal/`Scale`/`Basis`/`Dimension`) with an explicit "do not fork a third dimensional system" warning. This plugin sits downstream of both: it consumes `kalecky`-typed values from the ETL staging schema and must express shock parameters in a way that's coherent with the `KaleckianKernel`'s state/parameter types. If this project's own convenience leads to defining ad hoc unit/valuation wrappers around what it reads (because the ETL API isn't finalized yet, see Pitfall 1), that's a third system, and every future integration point becomes a manual, error-prone conversion.

**Why it happens:**
When the upstream API isn't ready, writing a local placeholder type "just for now" is the natural workaround — and local placeholder types have a strong tendency to become permanent once other code is built on top of them, because migrating away later touches everything.

**How to avoid:**
Any local type standing in for an ETL/`kalecky` type while waiting on the real API must be named and isolated in a way that makes it impossible to mistake for the real thing (e.g., a clearly-marked `Stub.` module, not a same-named shadow type), and must be deleted — not adapted — the moment the real type lands. The `KaleckianKernel`'s parameter/state types should be designed against `kalecky`'s actual unit vocabulary from day one (even before ETL's API exists, since `kalecky` itself is real and testable today), so there's no separate "kernel units" concept to reconcile later.

**Warning signs:**
- A module defines its own `newtype` wrapper for something `kalecky` already has a type for (COP, price index, growth rate)
- Conversion functions exist between "this project's units" and "kalecky's units" anywhere in the codebase
- The formalization doc's math↔type correspondence table has a row that doesn't map to an existing `kalecky` or `KaleckianKernel` type

**Phase to address:**
Phase 3 (Claim/Shock Type Design).

---

### Pitfall 12: Scope creep into solving the model or re-ingesting data

**What goes wrong:**
Two specific scope boundaries are stated as explicit out-of-scope items and are also the two most tempting things to accidentally start doing: (1) adding any code that closes/solves the Kaleckian system (computing equilibrium `I^d = S`, running a GAMS-equivalent closure locally) instead of stopping at "produce the shock"; (2) adding any code that fetches/parses source data directly (DANE, BanRep, ANDI) instead of reading only the ETL's staging schema. Both are easy to justify locally — "I just need to sanity-check this shock by running it through a tiny toy closure," or "the ETL doesn't have this series yet, I'll just pull it myself for now" — and both quietly duplicate ownership that already lives, deliberately, in other repos (monorepo's GAMS bridge; `mamertomics-etl`'s fetch/parse layer).

**Why it happens:**
Both boundaries are easy to cross when the other project isn't ready (again, Pitfall 1's shadow): if ETL doesn't have a series yet, going and fetching it directly feels like unblocking yourself rather than scope creep, even though it creates a second, divergent ingestion path with no reconciliation against the ETL's provenance/watermark discipline. Similarly, sanity-checking a shock's plausibility naturally invites "let me just see what it does to the model," which is a small step from building a second, informal model-solving path that competes with the monorepo's.

**How to avoid:**
When a needed series doesn't exist in staging yet, the correct action is the same "work stops, question surfaced" rule as Pitfall 8 — file it as a gap against `mamertomics-etl`, don't fetch around it. When a shock needs sanity-checking, do it by inspecting its type/units/magnitude against the claim and existing test oracles, not by executing it against an ad hoc closure implementation living in this repo. Any code that looks like it's computing an equilibrium, a closure solution, or fetching from DANE/BanRep/ANDI URLs directly is a scope violation by definition, regardless of how small or "just for testing" it's framed as.

**Warning signs:**
- Any import of an HTTP client aimed at a DANE/BanRep/ANDI URL, or an `.xlsx`/API parser, appears in this repo
- Any function computes a fixed point, equilibrium, or iterative solve over Kaleckian state
- A "quick script" in this repo queries a data source that isn't `mamertomics-db`

**Phase to address:**
Ongoing — call out explicitly in every phase's success criteria as a negative check, not just once at kickoff.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|-----------------|------------------|
| Hand-rolled fake/stub of the SDK's JSON-RPC types instead of waiting for the real API | Unblocks transport-layer work now | Stub drifts from real shape; rewrite when SDK lands; risk of shipping against the fake by mistake | Only if isolated in a clearly-marked `Stub.` module, deleted (not adapted) once the real SDK type lands |
| Placeholder numeric shock values in early codec tests | Lets JSON round-trip tests run before data access exists | Violates the project's own no-hardcoded-numbers rule if it leaks past tests; erodes the discipline everywhere else | Only inside test fixtures explicitly named `*Fixture`/`*Illustrative`, never in non-test code paths |
| Connecting via transaction-mode pooler "because it's the recommended scalable default" | Slightly simpler connection story, matches generic Supabase docs | Silent prepared-statement correctness bugs under concurrency | Never for this plugin's default read path; only after an explicit, tested opt-in |
| Skipping the SIGTERM/EOF teardown ladder in an early transport prototype | Faster to get request/response working | Orphaned processes, corrupted stdout lines once real harness lifecycle exercises it | Acceptable only in a throwaway spike explicitly not wired to the real harness |
| Defining a local unit wrapper instead of waiting on `kalecky`/ETL types | Keeps kernel-design work moving while ETL API is unfinished | Becomes the "third dimensional system" the ETL project explicitly warns against | Only if isolated and provably deleted before the corresponding phase closes |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|-----------------|-------------------|
| Stack git extra-dep (private `mamertomics-etl`) | Rely on a personal, long-lived git credential that "just works" locally and fails opaquely in CI | Dedicated read-only machine-user/PAT, injected explicitly in CI, with a clear auth-failure message distinguished from a bad-commit-pin failure |
| Stack git extra-dep (`kalecky` transitively via ETL) | Assume `kalecky` is a normal dependency without checking it has actually been extracted from the hevm-fork sublibrary | Verify `kalecky` is a standalone package (not a Cabal sublibrary) before pinning ETL as a dependency; this is a hard prerequisite, not a soft assumption |
| DeepSeek Harness JSON-RPC (developer preview) | Treat method/param shapes as stable API; assume a clean `cancel` exists | Isolate wire types behind an adapter; design for interruption-by-termination since there's no cancel method; re-verify protocol version on every SDK bump |
| Supabase Postgres (Supavisor) | Copy the transaction-mode (6543) connection string from a dashboard example | Default to session-mode pooler (5432), matching the ETL's own resolved decision; require SSL explicitly |
| Supabase Postgres (direct host) | Assume a direct-host connection timeout is a credentials/firewall problem | Check IPv6 egress first — the direct host is IPv6-only without the paid IPv4 add-on |
| `mamertomics-etl`'s query API | Query the staging Postgres schema directly with hand-rolled SQL instead of going through the ETL's exposed types/functions | Use only the ETL package's own API surface — "no second schema, no hardcoded values" is a stated project constraint |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|-----------------|
| Loading a full macro series into memory per claim query instead of a scoped/windowed query | Fine in dev with small fixture data, slow/memory-heavy once staging tables have years of history | Push date/series filtering into the ETL query API rather than filtering client-side after a full fetch | Once staging tables accumulate multi-year daily/monthly history across many source families |
| One DB round trip per field of a claim instead of a single scoped query per claim class | Not noticeable at single-claim test scale | Design the ETL query API call per claim class to fetch everything that claim needs in one query | Once the harness starts issuing many claims per session, or batch/backfill-style usage appears |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Supabase DSN or CI git token committed to `stack.yaml`, a `.env` file tracked in git, or logged in plugin stderr output during debugging | Credential leak from a private repo that may later be shared/reviewed; DB or repo compromise | Environment/vault only, as the project's own constraint already states; add a pre-commit or CI secret-scan check specifically because this has already been an explicit rule in the predecessor monorepo |
| Logging query parameters or fetched series values to stderr for debugging | Structured logs (even to stderr, even in a private repo) can leak data provenance details or, combined with DSN leakage, raw macro data that should stay behind the ETL's own access boundary | Log query *shape* (claim class, series ID, timestamp) not raw values; mirror the ETL project's own "no raw data values in logs" rule |
| Machine-user PAT for the private `mamertomics-etl` extra-dep scoped broader than read-only on that one repo | Compromised CI secret grants more access than needed | Fine-grained PAT/deploy key scoped to exactly the one private repo, read-only |

## "Looks Done But Isn't" Checklist

- [ ] **JSON-RPC transport:** Often "done" after a happy-path request/response test — verify SIGTERM mid-request, stdin EOF, and concurrent notification-plus-response writes are all covered by tests, not just the single-threaded round trip
- [ ] **Data access layer:** Often "done" once one query type-checks against a fixture — verify it's tested against the session-mode pooler with SSL, and against a `dim_status`-unconstructible case (kalecky gap: negative values, opaque `PriceIndex`, USD money), not just a clean happy-path series
- [ ] **Claim→shock mapping:** Often "done" once one claim class produces a plausible number — verify every claim class has its interpretive judgment call documented in the formalization artefact, and that basis/regime/sign are explicit, inspectable parameters rather than implicit in the function body
- [ ] **CI on the private repo:** Often "done" once a build passes once — verify it passes from a clean checkout with the CI-scoped machine-user credential (not a cached personal credential), and that `stack.yaml.lock` is actually committed and in sync
- [ ] **`KaleckianKernel` genericity:** Often "done" once the Sarmiento/Colombia instance works — verify the interface doesn't silently bake in Colombia-only assumptions (e.g., a hardcoded currency, a hardcoded regime) that would block a second country instance later, since the stated design goal is genericity even though only Colombia is built here

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|-----------------|------------------|
| Upstream SDK/ETL API shape changed after code was written against a stub | MEDIUM | Because wire types and query calls are isolated behind adapter modules (Pitfall 1/3 prevention), the fix is localized to the adapter — re-verify, don't rewrite the claim/shock logic that never touched the raw types |
| Discovered transaction-mode pooler was in use and prepared-statement bugs were silently corrupting results | MEDIUM-HIGH | Switch connection string to session-mode pooler; audit recent shock outputs for the affected window against a re-run through the corrected connection, since past results may be silently wrong, not just future ones |
| Hardcoded illustrative number found in a code path treated as production | LOW-MEDIUM | Because provenance is meant to be a required field on shock values (Pitfall 8 prevention), an unprovenanced value should already be a type-level red flag — if one slipped through anyway, audit every shock-producing function for the same pattern, not just the one instance found |
| A third dimensional/unit system was accidentally forked | HIGH | Requires migrating every consumer of the local wrapper type to the real `kalecky`/kernel type; the cost scales with how much code was built on top before it was caught — this is why the prevention (name/isolate stubs, delete on landing) matters more than the recovery |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-------------------|---------------|
| Building against hello-world stubs (P1) | Phase 0: Dependency & Protocol Foundations | Explicit "upstream API landed" gate re-checked before any phase touches SDK/ETL surface |
| Resolver/GHC snapshot divergence (P2) | Phase 0: Dependency & Protocol Foundations | CI job fails on extra-dep bump without a resolver compatibility re-check |
| Developer-preview protocol assumed stable, no cancel path (P3) | Phase 1: JSON-RPC Transport Implementation | Test exercises harness disappearing mid-request with no cancel notification |
| Private git extra-dep auth / hpack / lockfile churn (P4) | Phase 0: Dependency & Protocol Foundations | CI build from clean checkout with scoped machine-user credential; lockfile-drift check |
| Stdout pollution / buffering deadlock (P5) | Phase 1: JSON-RPC Transport Implementation | Subprocess-level smoke test asserting stdout is pure JSON-RPC for a full session |
| No teardown ladder / notification interleaving (P6) | Phase 1: JSON-RPC Transport Implementation | SIGTERM/EOF integration test; concurrent-write serialization test |
| Supavisor transaction-mode / IPv6 / SSL (P7) | Phase 2: Data Access Layer | Query tests run against session-mode pooler with SSL required; IPv6 egress checked in CI environment |
| Hardcoded illustrative numbers (P8) | Phase 3: Claim/Shock Type Design (type-level enforcement); Phase 4 verifies | Provenance field required on shock constructors; audit for bare literals in non-test code |
| Unit/basis/sign mismatches (P9) | Phase 4: Claim→Shock Formalization | Negative property tests for basis mismatch; regime assumption is an explicit inspectable parameter |
| Over-claiming a deterministic mapping (P10) | Phase 4: Claim→Shock Formalization | Formalization artefact documents the interpretive judgment call per claim class, traceable to queried series |
| Forking a third dimensional system (P11) | Phase 3: Claim/Shock Type Design | No local `newtype` duplicates a `kalecky` type; no conversion functions between "kernel units" and `kalecky` units |
| Scope creep into solving the model / re-ingesting data (P12) | Ongoing, every phase | Explicit negative check in every phase's success criteria: no equilibrium-solving code, no direct source-URL fetches |

## Sources

- [Stack yaml_configuration — official docs on `extra-deps`/git dependencies](https://docs.haskellstack.org/en/v1.0.2/yaml_configuration/) — HIGH
- [commercialhaskell/stack #4546 — extra-dep from GitHub issues](https://github.com/commercialhaskell/stack/issues/4546) — MEDIUM (community issue, corroborates auth/config friction)
- [Private package repositories using just Stack and Git](https://nikita-volkov.github.io/private-package-repositories-using-just-stack-and-git/) — MEDIUM
- [Supabase Docs — Supavisor FAQ](https://supabase.com/docs/guides/troubleshooting/supavisor-faq-YyP5tI) — HIGH (official)
- [Supabase Docs — Supavisor and Connection Terminology Explained](https://supabase.com/docs/guides/troubleshooting/supavisor-and-connection-terminology-explained-9pr_ZO) — HIGH (official)
- [Supabase Docs — Disabling Prepared Statements](https://supabase.com/docs/guides/troubleshooting/disabling-prepared-statements-qL8lEL) — HIGH (official)
- [Supabase — Connect to your database](https://supabase.com/docs/guides/database/connecting-to-postgres) — HIGH (official)
- [supabase/discussions #28239 — Disabling Prepared statements](https://github.com/orgs/supabase/discussions/28239) — MEDIUM (community, corroborates official docs)
- [Model Context Protocol — Transports (stdio hygiene, newline-delimited framing)](https://modelcontextprotocol.io/specification/2025-06-18/basic/transports) — HIGH (official spec; JSON-RPC line-transport rules are shared ancestry with LSP/MCP/DSH's own protocol)
- [Transport I, stdio: Two Pipes and a Subprocess](https://imti.co/mcp-transport-stdio/) — MEDIUM
- Project-internal sources verified directly: `/home/jmsbpp/mamertomics/sarmiento-plugins/.planning/PROJECT.md`, `/home/jmsbpp/mamertomics-etl/.planning/PROJECT.md` (Stack sublibrary issue #5318/#5256 citation, Supavisor pooler port decision, IPv6-only direct host, `kalecky` `PriceIndex`/`Unit` gaps, `mamertomics-core` overlap warning), `/home/jmsbpp/mamertomics-monorepo/CLAUDE.md` (predecessor's hard rules on no-hardcoded-illustrative-numbers and CI/local-resource discipline, used as evidence this is a live discipline problem in this toolchain, not hypothetical) — HIGH (primary source, this project's own stated facts)

---
*Pitfalls research for: Haskell DeepSeek Harness plugin over JSON-RPC with Supabase-backed economics formalization*
*Researched: 2026-08-25*
