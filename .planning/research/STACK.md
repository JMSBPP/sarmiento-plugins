# Stack Research

**Domain:** Haskell out-of-process DeepSeek Harness plugin (stdio JSON-RPC contained agent) reading a Supabase Postgres staging DB, emitting typed Kaleckian macro shocks
**Researched:** 2026-08-25
**Confidence:** HIGH (versions verified live against Stackage lts-24.56 and Hackage; protocol shape verified against the deepseek-harness `packages/sdk/protocol` README; Stack 3.11 verified against GitHub releases)

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| GHC | 9.10.3 | Compiler | Pinned by the chosen snapshot (below); matches the data resource's GHC exactly |
| Stack | 3.11.1 | Build tool | User-specified constraint; confirmed current stable (released 2026-06-13). A `v4.1.0.1` release candidate exists but is pre-release — stay on 3.11.1 |
| Stackage snapshot **lts-24.56** | 2026-08-24 | Dependency set | See "Single Snapshot Decision" below |
| aeson | 2.2.5.0 | JSON encode/decode | De facto standard; in-snapshot, no extra-dep. Required transitively by every other layer (protocol, codecs, kalecky types) |
| json-rpc | 1.1.3 | JSON-RPC 2.0 envelope (request/response/notification framing, ID correlation) | In-snapshot; last published 2026-08-18 (actively maintained). Transport-agnostic "supports any underlying transport" design is exactly what the harness's caller-owned-byte-stream framing needs — pair it with a ~20-line hand-written line transport (below), not a heavier Conduit-based package |
| hasql | 1.9.3.1 | Postgres client (binary protocol, prepared statements) | In-snapshot (no extra-dep needed — this alone removes a historical pain point with hasql on Stackage). Matches the data resource's chosen DB layer; sharing one client library across the two repos means the same encoder/decoder conventions for `kalecky`-derived Postgres types can eventually be shared instead of re-invented |
| hasql-pool | 1.3.0.5 | Connection pooling | In-snapshot. Pool against Supabase's **session-mode Supavisor pooler (port 5432)** — matches the data resource's decision; hasql relies on the Postgres **extended query protocol** (server-side prepared statements), which transaction-mode pooling (6543) does not reliably support even after Supavisor 1.0's partial prepared-statement work |
| autodocodec | 0.5.0.0 | Self-documenting `Codec` deriving `FromJSON`/`ToJSON` + JSON Schema together | In-snapshot. This project's claim-input and shock-output formats are explicitly "to be specified" (PROJECT.md) — autodocodec gives you the schema *as a byproduct* of writing the codec once, instead of hand-writing `FromJSON`/`ToJSON` and a separate schema/validation layer that will drift |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| autodocodec-schema | 0.5.0.0 (matches autodocodec in lts-24.56) | Emit JSON Schema from an `autodocodec` `Codec` | When you need to publish/validate the claim or shock format's schema externally (e.g. for docs, or for a Python/TS-side consumer to validate against) |
| hasql-interpolate | 1.0.1.0 (rev 3) | Type-safe SQL via `QuasiQuotes` string interpolation, no live-DB build-time check needed | Default choice for staging-schema `SELECT`s — lower ceremony than `hasql-th`, doesn't require a reachable Postgres connection at compile time (important since CI may not always have a DB) |
| hasql-th | 0.4.0.23 | Type-safe SQL via Template Haskell, checked against a **live** Postgres connection at compile time | Alternative if you want compile-time verification against the actual Supabase staging schema rather than manually declared row types; requires DB reachability during `stack build`, which complicates CI — prefer `hasql-interpolate` unless that guarantee is worth the CI complexity |
| process | 1.6.26.1 | Spawn subprocesses | Building the "fake harness" test runtime (spawn the plugin binary, feed scripted stdin lines, assert stdout lines) — see Testing below |
| bytestring | 0.12.2.0 | Line-oriented stdio I/O | The hand-written line transport (`Data.ByteString.Char8.hGetLine`/`hPutStrLn` on stdin/stdout, `\n`-terminated, matching the harness's exact framing) |
| optics-core, optics-th | (pulled transitively via `kalecky` once extracted) | Field access for `kalecky` dimensional types | `kalecky`'s source (`kalecky-spec/src/Kalecky/`) is written against `optics-core`/`optics-th`/`aeson-optics` with `NoFieldSelectors`/`OverloadedRecordDot` — depending on `kalecky` pulls this convention in; don't introduce `lens` as a second optics library |
| tasty | 1.5.4 | Test suite runner/combinator | Umbrella for unit + property + fake-harness conformance tests in one `Spec.hs` |
| tasty-hunit | (constraint `>=1.2.2 && <1.6`, resolves in-snapshot) | Example-based assertions | CASO-PRUEBA-style example tests (mirrors the pattern already used in `kalecky-spec`) |
| tasty-quickcheck | (constraint `>=1.5.1 && <1.6`, resolves in-snapshot) | QuickCheck properties under `tasty` | Dimensional-consistency and sign-convention properties on claim→shock mappings |
| QuickCheck | 2.15.0.1 (rev 1) | Property testing | See "Property Testing: QuickCheck vs Hedgehog" below |

## Installation

```bash
# ghcup-managed toolchain (matches Stack 3.11 / GHC 9.10.3 from lts-24.56)
ghcup install ghc 9.10.3
ghcup set ghc 9.10.3

# Stack resolves everything else from the snapshot; only extra-deps need explicit pins
stack build
```

`package.yaml` dependency block (hpack), core additions on top of `base`:

```yaml
dependencies:
  - base >= 4.7 && < 5
  - aeson
  - json-rpc
  - autodocodec
  - autodocodec-schema
  - hasql
  - hasql-pool
  - hasql-interpolate
  - bytestring
  - text
  - process        # test-suite only
  - tasty           # test-suite only
  - tasty-hunit     # test-suite only
  - tasty-quickcheck # test-suite only
  - QuickCheck      # test-suite only
  # once kalecky is extracted (blocking prerequisite, see Alternatives Considered):
  - kalecky
  # private git deps, see stack.yaml below:
  - the data resource
  - haskell-deepseek-plugin-sdk
```

## Single Snapshot Decision

**Recommendation: `lts-24.56`, the same snapshot already pinned by the data resource.**

- `the data resource/stack.yaml` is already pinned to `lts-24.56` (GHC 9.10.3) as of 2026-08-25 — verified by direct read of the file.
- `haskell-deepseek-plugin-sdk/stack.yaml` is pinned to `lts-22.43` (GHC 9.6.x), but its entire codebase is a `stack new` scaffold — one file, `Main.hs`, `putStrLn "hello world"`, `build-depends: base`. There is **no real dependency surface to migrate**; bumping its snapshot is a one-line change with zero blast radius. Bumping the ETL side would instead mean re-resolving a real dependency tree (`hasql`, `hasql-pool`, `amazonka` git pin, `kalecky`, warp) downward to GHC 9.6, fighting version floors that assume 9.10.
- Verified live: `lts-24.56` was Stackage's most recent LTS-24 point release as of 2026-08-24 (one day before this research), so it is not a stale pin — it is current.
- Practical effect: `sarmiento-plugins/stack.yaml` sets `snapshot: lts-24.56`; the SDK repo needs its `stack.yaml` bumped to `lts-24.x` before `sarmiento-plugins` can add it as a extra-dep without a resolver mismatch (Stack extra-deps from a different-resolver git repo generally still work — Stack resolves the extra-dep's own dependencies against *your* project's snapshot, not the extra-dep's own `stack.yaml` — but a scaffold with zero real dependencies gives zero opportunity for that to matter here anyway).

**Confidence: HIGH** — both `stack.yaml` files were read directly, and `lts-24.56`'s currency and package versions were verified live via Stackage rather than assumed from training data.

## Protocol Layer Detail (verified against deepseek-harness `packages/sdk/protocol`)

Confirmed live from the `packages/sdk/protocol/README.md`:

- **Framing:** newline-delimited JSON-RPC 2.0 — "one compact JSON frame per `\n`-terminated line" over caller-owned byte streams. **Not** Content-Length-headers like LSP.
- **Methods (client→server):** `initialize`, `session/prompt`, `shutdown`.
- **Notifications (server→client):** `session.event`, `session.status`, `subagent.started`, `subagent.finished`.
- **No cancel method** — explicitly documented as deferred; a client abandons a turn by closing the process. Confirms the PROJECT.md's note; do not design around a cancel RPC that doesn't exist.
- Frame classification is exactly per JSON-RPC 2.0: requests have `id`+`method`, responses have `id` only, notifications have `method` only.

**Implementation shape:** `json-rpc` (Hackage) provides the request/response/notification envelope and ID bookkeeping; write a small `LineTransport` module (`Data.ByteString.Char8.hGetLine`/`hPutStrLn`, `stdin`/`stdout` set to `NoBuffering`/line-buffering, UTF-8) that feeds/drains it — this is intentionally thin and project-owned rather than a dependency, because the harness's framing (bare `\n`, no length header, no batching mentioned) doesn't need a general-purpose streaming library like `conduit`.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| `json-rpc` + hand-written line transport | `jsonrpc-conduit` | If you later need backpressure-aware streaming over a socket transport instead of stdio pipes; adds a `conduit` dependency that buys nothing for a 7-method, unbatched, line-framed stdio protocol |
| `json-rpc` | Hand-roll the entire envelope with bare `aeson` | Only if `json-rpc`'s ID-correlation model turns out to fight the notification-heavy shape of this protocol during implementation — treat as a fallback, not a first choice, since re-deriving JSON-RPC 2.0 framing correctness (batch detection, error object shape, ID type polymorphism) is exactly the kind of thing a maintained library exists to get right once |
| `autodocodec` | Bare `aeson` `FromJSON`/`ToJSON` instances, hand-maintained | If the claim/shock format ends up genuinely simple (few constructors, no evolving schema needs) and the schema-as-byproduct benefit isn't worth the extra dependency and the `Codec` combinator learning curve |
| `hasql` + `hasql-pool` | `postgresql-simple` | If a future contributor is unfamiliar with `hasql`'s statement/session/pool separation and needs faster onboarding — but this forfeits sharing conventions with the data resource's data layer, and reintroduces stringly-typed row decoding |
| `hasql-interpolate` | `hasql-th` | If you want SQL checked against a **live** Supabase connection at compile time, and are willing to make CI provision that connection for every build |
| QuickCheck + tasty | Hedgehog + tasty-hedgehog | See dedicated section below |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `opaleye` | This is `mamertomics-monorepo`'s **predecessor** storage layer for the macro data resource (per both PROJECT.md files) — it's being actively superseded, not the live schema's access pattern. Depending on it here would create a second, divergent Postgres access convention alongside the ETL's `hasql` choice | `hasql` + `hasql-pool`, matching the data resource |
| A second, independently-defined dimensional/units type (`Price`, `Wage`, `Currency`, etc.) | The ETL's PROJECT.md is explicit: "Do not fork a third dimensional system." `kalecky` is the single source of truth once extracted | `kalecky` (`JMSBPP/kalecky-semantics`), reused as a shared dependency |
| Depending directly on `kalecky-spec`'s cabal **sublibrary** as it exists today (`kalecky-spec/src/Kalecky/*` inside the hevm fork) | Stack cannot depend on cabal internal sublibraries at all — this is a confirmed upstream Stack limitation (commercialhaskell/stack issues #5318 and #5256), not a version-pinning problem you can work around with `extra-deps`. the data resource's own PROJECT.md names this as a **hard Phase-0 gate**: extraction into a standalone base-only package is a prerequisite, not optional | Wait on (or contribute to) the `kalecky` extraction that the data resource already scoped as a blocking prerequisite; once it lands as its own git repo/subdir, add it as a normal Stack `git` extra-dep. `sarmiento-plugins` inherits this exact blocker transitively — it cannot get typed dimensional units before the data resource (or a shared extraction effort) finishes Phase 0 |
| Content-Length/LSP-style framing assumptions, or a general streaming/Conduit-based transport for stdio | The harness protocol is confirmed newline-delimited with no documented batching — a heavier framing library solves a problem this protocol doesn't have | The hand-written `\n`-line transport described above |
| Designing around a `session/cancel` or similar RPC | Confirmed not to exist in the protocol as of 2026-08-25 ("deferred work"); the harness's only abort path is closing the child process | Handle `SIGPIPE`/EOF-on-stdin as the harness's actual cancel signal; document this as a real protocol limitation, not an oversight in this project's design |

## Property Testing: QuickCheck vs Hedgehog

**Recommendation: QuickCheck (2.15.0.1) + `tasty-quickcheck`, not Hedgehog.**

Rationale, in order of weight:

1. **Ecosystem precedent.** `kalecky-spec` (the fork that currently hosts the `kalecky` types this project's shock output depends on) already uses `QuickCheck` + `Tasty`/`tasty-hunit` for its 107 tests + 6 compile-fail boundaries (verified by direct read of `kalecky-spec.cabal` and `kalecky-semantics/.planning/PROJECT.md`: "QuickCheck + Tasty test infrastructure"). Property tests on claim→shock invariants will very likely need `Arbitrary` instances for `kalecky` types (`Unit`, `Price`, `Wage`, `Measure`) — reusing/extending existing `Arbitrary` instances from the `kalecky` side (once extracted) is cheaper than maintaining a parallel `Gen`-based Hedgehog generator set for the same types.
2. **Both are current and in-snapshot** at lts-24.56 (QuickCheck 2.15.0.1, hedgehog 1.5), so this is not a currency/availability tradeoff — it's purely a convention-consistency call.
3. Hedgehog's integrated-shrinking and `Gen`-composability are a real ergonomic advantage in general, and would be the right call if this project had no upstream precedent to match — flag it as the fallback if `Arbitrary` instances for `kalecky` types turn out not to exist upstream and this project has to author generators from scratch anyway (in which case Hedgehog's generator model is nicer to write by hand).

**Confidence: MEDIUM** — the precedent is directly verified (not inferred), but the "reuse upstream `Arbitrary` instances" argument is conditional on `kalecky`'s extraction actually exposing them, which hasn't happened yet.

## Fake-Harness Test Runtime

No dedicated Hackage package exists for this (nor should one — it's protocol-specific to `deepseek-harness`). Build it from primitives already in the recommended stack:

- `process` to spawn the compiled plugin binary as a subprocess with piped `stdin`/`stdout`.
- The hand-written line transport module, reused on the test side to write scripted `initialize`/`session/prompt` request lines and read back `session.event`/response lines.
- `tasty` + `tasty-hunit` to assert the emitted frames match expected JSON-RPC shapes (`id` correlation, `session.event` payload structure) and that the process doesn't hang or crash on EOF (the harness's only "cancel" signal, per the protocol section above).

This mirrors the standard pattern for testing LSP-like stdio servers in any language: black-box the binary, script the wire protocol, assert on stdout — there's nothing DeepSeek-Harness-specific here that would justify a library dependency over a project-local test helper module.

## Stack Git Extra-Deps for Private Repos in CI

### `stack.yaml` shape

```yaml
snapshot: lts-24.56

packages:
  - .

extra-deps:
  - git: <data-resource-url>
    commit: <pin to a specific commit SHA — moving target, bump deliberately>
  - git: https://github.com/d2p-finance/haskell-deepseek-plugin-sdk.git
    commit: <pin to a specific commit SHA>
  # once kalecky is extracted from kalecky-spec's sublibrary:
  - git: https://github.com/JMSBPP/kalecky-semantics.git
    commit: <pin to a specific commit SHA>
    # subdirs: [kalecky]   # only if the extraction lands as a subdirectory rather than its own repo root
```

Both `git`/`commit` fields (and `subdirs` when a monorepo-style extra-dep is needed) are the standard Stack `extra-deps` git-dependency shape — unchanged in Stack 3.11.1; no new git-extra-dep syntax was introduced in 3.11 (verified against the 3.11.1 release notes, whose additions are `!include` YAML directives, `recent-snapshots`, and `config set snapshot`/`--reach`, none of which touch git extra-deps).

### Private-repo authentication in CI

Stack has no auth mechanism of its own for git extra-deps — it shells out to the system `git` binary to clone, so **any git-level authentication is transparent to Stack**. The standard, verified-current (2026) pattern for GitHub Actions:

```yaml
- name: Configure git for private extra-deps
  run: |
    git config --global url."https://x-access-token:${{ secrets.PRIVATE_DEPS_TOKEN }}@github.com/".insteadOf "https://github.com/"

- name: Build
  run: stack build
```

- `PRIVATE_DEPS_TOKEN` should be a **fine-grained GitHub Personal Access Token**, scoped only to the specific private repos this project depends on (the data resource (HTTP pointer, v2), and `d2p-finance/haskell-deepseek-plugin-sdk` if/when it goes private) — not a classic PAT with broad `repo` scope.
- The default `GITHUB_TOKEN` that Actions injects automatically works **only** for repos within the same GitHub org/owner as the workflow; since the data resource is under the same `JMSBPP` account as `sarmiento-plugins`, `GITHUB_TOKEN` (with `contents: read` permission and, if needed, cross-repo access via an org setting) may suffice for that dependency without a separate PAT — but the SDK repo (`d2p-finance` org) will always need an explicit PAT or GitHub App installation token, since it's a different owner.
- Because `insteadOf` rewrites at the git-config level, it applies uniformly to every `https://github.com/...` URL Stack tries to clone — including any future private extra-dep — without touching `stack.yaml`.

**Confidence: HIGH** for the mechanism (this is standard, widely-used git config, not Stack-specific magic, and matches multiple independently-verified current sources) — **MEDIUM** for the exact token-scoping recommendation across the two owners (`JMSBPP` vs `d2p-finance`), since it depends on org-level cross-repo `GITHUB_TOKEN` settings this research didn't (and can't, without repo admin access) directly verify.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| GHC 9.10.3 (lts-24.56) | the data resource's pinned GHC | Identical — verified by reading both `stack.yaml` files; zero cross-compiler friction on that side |
| GHC 9.10.3 (lts-24.56) | `haskell-deepseek-plugin-sdk`'s current pin (GHC 9.6.6 / lts-22.43) | **Mismatched today.** The SDK repo needs its snapshot bumped before/while adding it as an extra-dep here; low risk given it's a one-file scaffold with only a `base` dependency |
| `hasql` 1.9.3.1 / `hasql-pool` 1.3.0.5 | Supabase Supavisor **session-mode pooler**, port 5432 | Required — `hasql` uses the Postgres extended query protocol (server-side prepared statements); Supavisor's transaction-mode pooler (6543) does not reliably support this even post-1.0, per Supabase's own troubleshooting docs |
| `kalecky` (once extracted) | Stack (any recent version) | Only resolvable once extraction out of the `kalecky-spec` cabal **sublibrary** happens — this is a hard blocker independent of snapshot choice, per Stack issues #5318/#5256 |
| `autodocodec` 0.5.0.0 | `aeson` 2.2.5.0 | Both resolve cleanly from lts-24.56 together; no manual pinning needed |

## Sources

- `the data resource/stack.yaml` (read directly) — confirms `lts-24.56` pin, GHC 9.10.3
- `the data resource/.planning/PROJECT.md` (read directly) — confirms hasql-pool + Supavisor session-mode decision, `kalecky` extraction as Phase-0 gate, Stack sublibrary limitation (#5318/#5256)
- `haskell-deepseek-plugin-sdk/stack.yaml`, `.cabal`, `src/Main.hs` (read directly) — confirms scaffold-only state, `lts-22.43` pin, zero real dependencies
- `kalecky-semantics/.planning/PROJECT.md`, `kalecky-spec/kalecky-spec.cabal` (read directly) — confirms QuickCheck + Tasty precedent, `aeson`/`optics-core` conventions already in use for `kalecky` types
- https://www.stackage.org/lts-24.56 and per-package pages (`aeson`, `hasql`, `hasql-pool`, `hasql-interpolate`, `hasql-th`, `autodocodec`, `hedgehog`, `tasty`, `QuickCheck`, `process`, `bytestring`, `containers`, `json-rpc`) — HIGH confidence, versions fetched live 2026-08-25
- https://github.com/commercialhaskell/stack/releases — confirms Stack 3.11.1 as current stable (2026-06-13), no git-extra-deps syntax changes in 3.11
- `packages/sdk/protocol/README.md` in `github.com/deepseek-ai/deepseek-harness` (fetched live) — confirms newline-delimited JSON-RPC 2.0 framing, exact method set (`initialize`, `session/prompt`, `shutdown`, `session.event`, `session.status`, `subagent.started`, `subagent.finished`), and the absence of a cancel method
- https://supabase.com/docs/guides/troubleshooting/supavisor-faq-YyP5tI and related Supabase docs (WebSearch, MEDIUM confidence, not fetched from primary doc page directly) — confirms session-mode vs transaction-mode prepared-statement support tradeoff
- Standard `git config url.insteadOf` GitHub Actions pattern (WebSearch across multiple independent sources: Elixir Forum, Tim Searle's blog, GitHub App token docs) — MEDIUM-HIGH confidence, cross-verified across sources but not GitHub's own official Actions docs directly

---
*Stack research for: Haskell out-of-process DeepSeek Harness plugin (JSON-RPC contained agent) with Supabase Postgres data access and dimensional Kaleckian types*
*Researched: 2026-08-25*
