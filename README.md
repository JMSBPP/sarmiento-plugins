# sarmiento-plugins

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/assets/hero-dark.png">
    <img src="docs/assets/hero-light.png" alt="Eduardo Sarmiento over a natural-transformation diagram" width="320">
  </picture>
</p>

> **Mission.** Formalise Eduardo Sarmiento mathematically. This repository turns the Colombian
> economist's structuralist claims — demand regime, markup and income distribution, the external
> constraint, productive structure — into typed, dimensionally-checked objects, and ships them as a
> **Colombian plugin to a neo-Kaleckian model**: a concrete instance of the generic `KaleckianKernel`
> owned by [`kalecky-semantics`](https://github.com/JMSBPP/kalecky-semantics). Sarmiento stops being
> prose and becomes a plugin over a reusable kernel.

A Haskell project that will ship a **DeepSeek Harness (Cordis) plugin acting as a
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

**Scaffold plus wired dependencies.** This repository builds, tests, and resolves all three
of its upstreams; it does not yet do any economics:

- the three upstream dependencies below are pinned by commit and wired — a module in this
  project imports a real symbol from each upstream that exposes a library, so a broken pin
  is a compile error;
- the claim input format, the shock output format, the JSON-RPC protocol client, and the
  data grounding are all still deferred to v2;
- there is no CI yet — that is Phase 3.

The deferral is deliberate, not an oversight: the upstreams are early-stage today, so
writing code against their APIs now would mean writing against shapes that do not exist yet.
Wiring them first means that when those shapes land, the only change here is code — not a
dependency archaeology exercise.

## Upstream dependencies

| Repository | Owner | Visibility | Pinned commit | Why |
|---|---|---|---|---|
| `kalecky-semantics` | `JMSBPP` | public | `cd6778e2d39c5eb30549d8ff87459b5644cc18fc` | The sole source of dimensional, unit, currency and price types (`Kalecky.Types.Units.*`, `Kalecky.Types.Currency`, `Kalecky.Types.Measure`, `Kalecky.Types.Valuation`, `Kalecky.Types.Prices.*`) and, in future, the generic `KaleckianKernel` this project instantiates for Colombia. Has zero non-`base` dependencies, so depending on it pulls nothing else into the build plan. |
| `mamertomics-etl` | `JMSBPP` | private | `c8b45ac159553017df82c4258af3d2bf68b5f62e` | Owns `mamertomics-db`, the Supabase staging schema of Colombian macro series (DANE, BanRep, ANDI, minimum-wage decrees). This project only *reads* it; it never ingests or transforms source data. Its real read API is v2 — today it exposes a scaffold module, which is enough to pin and prove the dependency edge. |
| `haskell-deepseek-plugin-sdk` | `d2p-finance` | public | `242ebfa05acd318326aea7f35508d7d4c1bbdbfa` | Haskell SDK for building DeepSeek Harness (Cordis) plugins over JSON-RPC. This project is a consumer, not a co-author. **No importable symbol at this pin — see the note below.** |

### How each dependency is wired

`kalecky-semantics` and `mamertomics-etl` are declared in both `stack.yaml` `extra-deps:`
and `package.yaml` `dependencies:`. `src/Sarmiento/Upstream.hs` imports a real symbol from
each, so a broken pin fails `stack build` with a "Could not find module" error rather than
surfacing much later.

**No third dimensional system.** Units, currencies, and price/wage types come from
`kalecky-semantics` only. This project does not define its own, and
`scripts/check-no-local-dimensional-types.sh` fails the build if one appears: it rejects any
local `data`/`newtype`/`type` declaration of a unit-shaped name, and allows the tokens
`kalecky`, `Currency`, `Measure` and `Valuation` in `src/` and `test/` only on an import of a
`Kalecky.*` module or inside a comment.

### `haskell-deepseek-plugin-sdk` has no importable symbol at this pin

At the pinned commit the SDK's `.cabal` declares a `library` stanza with seven exposed
modules (`DeepSeek.Plugin`, `.Content`, `.Manifest`, `.Peer`, `.Schema`, `.Types`, `.Wire`),
plus an `executable dsh-plugin-echo` and a `test-suite conformance`. Every one of the seven
library modules is a literal empty stub — `module DeepSeek.Plugin.<X> () where`, each
documented upstream as "Empty in Phase N. Phase N fills it in." There is no symbol anywhere
in the library to import, so it is declared in `stack.yaml` `extra-deps:` only, and
deliberately **not** in `package.yaml` `dependencies:`.

This is a narrower claim than "executable-only, no library" — that description was accurate
at an earlier revision (planning-time pin `21d7ac43ec4ca2e580960d50b9f3ef5f95832264`), but
the SDK's upstream HEAD moved before this repository's pin was fixed, and the commit pinned
here now genuinely has a `library` stanza. Adding it to `package.yaml` `dependencies:` does
not fail the build plan the way a truly library-less package would (verified directly:
`stack build` links it cleanly with it declared as a dependency). What blocks wiring it like
the other two upstreams is narrower and more mechanical: there is no exported name anywhere
in its seven modules to reference, so no compile-time proof of the pin — the same kind
`src/Sarmiento/Upstream.hs` gives for `kalecky-semantics` and `mamertomics-etl` — is possible
for it today. Adding it to `dependencies:` now would add a real build edge to nothing.

What is actually proven about this dependency today, and nothing stronger: the pinned commit
exists, its `.cabal` parses, Stack clones it and records a `pantry-tree` hash for it in
`stack.yaml.lock`, and `stack build` succeeds with it declared as an `extra-dep`. It is never
compiled as part of this project's own build graph, because nothing in `package.yaml`
depends on it. When upstream's library modules gain real exports, add it to `package.yaml`
`dependencies:` and import a symbol from it in `src/Sarmiento/Upstream.hs` alongside the
other two — at which point this note comes out.

### Pin and bump discipline

**Pin by commit, never track a branch.** A branch reference does not weaken the pin so much
as *relocate* it: Stack still records an immutable `pantry-tree` content hash in
`stack.yaml.lock`, so the build stays reproducible while `stack.yaml` — the file a human
reads — stops describing what is actually built. The commit SHA in `stack.yaml` and the hash
in `stack.yaml.lock` must always name the same thing, and that is only guaranteed when the
reference is itself immutable. `stack.yaml` contains no `branch:` key, and this is checked.

**Bumping is an explicit, reviewable act**, never a side effect of running a build:

1. Read the upstream's current head, rather than trusting a local clone (local clones drift —
   one of these three was several commits stale during this project's own research):

   ```sh
   gh api repos/JMSBPP/kalecky-semantics/commits/HEAD --jq .sha
   ```

2. Edit the corresponding `commit:` line in `stack.yaml`. Change nothing else.
3. Run `stack build`. This re-fetches the dependency and rewrites `stack.yaml.lock`.
4. Run `stack test`. A bump that breaks a proof-of-import or a property is a bump to
   investigate, not to force through.
5. Confirm the lock is exactly what Stack would write, using the same command CI runs:

   ```sh
   stack --lock-file error-on-write build
   ```

   Exit 0 means in sync. Exit 1 with `Error: [S-1353]` means `stack.yaml.lock` is stale;
   re-run step 3.
6. Commit `stack.yaml` and `stack.yaml.lock` **in the same commit**, with a message naming
   the dependency and what the bump is for. Splitting them across commits leaves an
   intermediate revision that CI cannot build.
7. Update the pinned-commit column in the table above.

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
friction now that `mamertomics-etl` is wired in as a pinned git dependency.

## Layout

```
src/                  library sources
  Sarmiento/          the plugin's own modules
  Sarmiento/Upstream.hs   compile-time proof that both library upstreams resolve
  Education/          placeholder for the claim-taxonomy notes (purpose decided later)
test/                 tasty + QuickCheck test-suite
scripts/              repository guards (no-local-dimensional-types)
package.yaml          hpack package description (the .cabal file is generated from it)
stack.yaml            snapshot pin + the three commit-pinned git extra-deps
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
