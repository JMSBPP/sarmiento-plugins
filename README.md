# sarmiento-plugins

A private Haskell project that will ship a **DeepSeek Harness (Cordis) plugin acting as a
contained agent**. Given structured claims by the Colombian economist Eduardo Sarmiento —
statements about demand regime, markup and income distribution, the external constraint, and
productive structure — the plugin will read Colombian macroeconomic series from
`mamertomics-db` and emit **dimensionally-typed Kaleckian shocks** that a Kaleckian model
consumes.

The design rule that makes this worth building: every emitted number carries its units and
its provenance. A shock magnitude either traces back to an observation in the staging
database, or it is not emitted at all.

Alongside the runnable plugin, the project formalises Sarmiento's structuralist economic
claims as a Colombian instance of the generic `KaleckianKernel` owned by `kalecky-semantics`,
so "Sarmiento" becomes a typed plugin over a reusable kernel rather than prose.

## Status

**Scaffold only.** This repository currently contains a buildable, testable Stack skeleton
and nothing else:

- the claim input format, the shock output format, the JSON-RPC protocol client, and the
  data grounding are all deferred to v2;
- the three upstream dependencies below are **not wired yet** — that is Phase 2;
- there is no CI yet — that is Phase 3.

The deferral is deliberate, not an oversight: all three upstreams are early-stage today, so
writing code against their APIs now would mean writing against shapes that do not exist yet.

## Upstream dependencies

| Repository | Owner | Visibility | Role | Wiring |
|---|---|---|---|---|
| `mamertomics-etl` | `JMSBPP` | private | Owns `mamertomics-db`: the Supabase staging schema of Colombian macro series (DANE, BanRep, ANDI, minimum-wage decrees). This project only *reads* it; it never ingests or transforms source data. | Phase 2 |
| `haskell-deepseek-plugin-sdk` | `d2p-finance` | public | Haskell SDK for building DeepSeek Harness (Cordis) plugins over JSON-RPC. Tracked upstream; this project is a consumer, not a co-author. | Phase 2 |
| `kalecky-semantics` | `JMSBPP` | private | Sole source of dimensional and unit types (`Kalecky.Types.Units`, `Currency`, `Measure`, `Valuation`, `Prices.*`) and, in future, the generic `KaleckianKernel`. | Phase 2 |

**No third dimensional system.** Units, currencies, and price/wage types come from
`kalecky-semantics` only. This project does not define its own.

Each dependency will be pinned to an explicit commit — never a branch — and bumped
deliberately. The pinned-commit table lands with the wiring in Phase 2.

## Build and test

Prerequisites: [ghcup](https://www.haskell.org/ghcup/) with **Stack 3.11.1** on `PATH`.
Stack installs the pinned **GHC 9.10.3** itself on first build; on a cold machine expect a
several-hundred-megabyte toolchain download before anything compiles.

```sh
git clone https://github.com/JMSBPP/sarmiento-plugins.git
cd sarmiento-plugins

stack build   # builds the library
stack test    # builds and runs the tasty + QuickCheck smoke suite
```

Both commands are expected to succeed on a fresh clone with no additional setup — no
environment variables, no database, no credentials. That property is the whole point of the
scaffold phase, and it is what Phase 3's CI will assert on every push.

## Snapshot

Pinned to Stackage **`lts-24.56`** (GHC 9.10.3), declared by immutable snapshot URL rather
than by name so Stack treats it as fixed. This is the same snapshot `mamertomics-etl` uses,
which means the two projects share one compiler and one dependency set — zero cross-compiler
friction when `mamertomics-etl` is added as a git dependency in Phase 2.

## Layout

```
src/                  library sources
  Sarmiento/          the plugin's own modules
  Education/          placeholder for the claim-taxonomy notes (purpose decided later)
test/                 tasty + QuickCheck test-suite
package.yaml          hpack package description (the .cabal file is generated from it)
stack.yaml            snapshot pin; extra-deps arrive in Phase 2
```

Edit `package.yaml`, never `sarmiento-plugins.cabal` — the latter is hpack output and is
regenerated on every `stack build`.

## Conventions

- **Warnings:** the `-Wall`-plus set matches `mamertomics-etl` exactly, so a module can move
  between the two repositories without a warning-flag surprise.
- **Secrets:** database DSNs and API keys travel by environment variable only. They are never
  written to config files, logs, or commits.
- **Data integrity:** no hardcoded "illustrative" numeric literals. A magnitude either comes
  from `mamertomics-db` with provenance, or the work stops and the question is surfaced.
