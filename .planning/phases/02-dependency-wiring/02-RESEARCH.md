# Phase 2: Dependency Wiring - Research

**Researched:** 2026-08-25
**Domain:** Stack git extra-deps (private + public repos), hpack/cabal interop, lockfile discipline
**Confidence:** HIGH — every finding below was produced by actually running `stack build` against the three real upstream commits in a scratch copy of this project, not by reasoning about Stack's documented behavior.

## Summary

All three upstream dependencies were tested empirically as Stack git extra-deps against `sarmiento-plugins`' real `lts-24.56` snapshot, using a scratch copy at a throwaway path (not the real repo — `stack.yaml`/`package.yaml` here were never modified). The two libraries (`kalecky-semantics`, the data resource) build and are importable with **zero** version-bound or resolver conflicts, despite each declaring a different snapshot in its own `stack.yaml` (`lts-23.28` and `lts-24.56` respectively — Stack ignores an extra-dep's own resolver and only uses the consumer's snapshot). The third (`haskell-deepseek-plugin-sdk`) has no library component at its true GitHub HEAD (verified live, not from the possibly-stale local clone) — declaring it in `package.yaml` `dependencies:` produces a hard, well-defined Stack error (`S-4804`, "is a library dependency, but the package provides no library"); it must be listed **only** in `stack.yaml` `extra-deps:`, never in `package.yaml`.

The private repo (the data resource) cloned transparently on this machine via the existing `gh auth git-credential` helper over plain HTTPS — no SSH key, no `insteadOf` rewrite needed locally, and the same HTTPS URL form is what Phase 3's CI token injection will target. `stack --lock-file error-on-write build` is the exact, verified mechanism for CI-03 (fails loudly with exit code 1 and prints the would-be lock diff when `stack.yaml.lock` is stale; exits 0 silently when in sync) — this is directly reusable in Phase 3 and worth wiring into Phase 2's own verification.

One correction to the existing README's dependency table: `kalecky-semantics` is **public** on GitHub (verified via `gh repo view --json visibility` → `PUBLIC`), not private as currently documented. the data resource is the only genuinely private repo among the three (verified `private: true`).

**Primary recommendation:** Pin all three extra-deps by the exact commit SHAs verified below, add `kalecky-semantics` and the data resource to `package.yaml` `dependencies:` with a real imported symbol each, leave `haskell-deepseek-plugin-sdk` in `extra-deps:` only with a documented executable-only note (no import possible), and gate Phase 2's own verification on `stack --lock-file error-on-write build` succeeding.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-------------------|
| DEPS-01 | `stack.yaml` declares git extra-deps pinned by commit for the data resource (private) and `haskell-deepseek-plugin-sdk` (public); `stack.yaml.lock` committed | Verified commit SHAs, verified HTTPS clone works with existing `gh` credential helper (no CI-only mechanism needed locally), verified exact `stack.yaml.lock` shape Stack writes for git extra-deps |
| DEPS-02 | `stack.yaml` declares `kalecky-semantics` as pinned git extra-dep, `package.yaml` depends on it, `Kalecky.Types.*` importable, no local dimensional types | Verified `kalecky-semantics` builds clean on lts-24.56 from its own lts-23.28 pin; verified exact list of currently-exposed `Kalecky.Types.*`/`Kalecky.Operators.*`/`Kalecky.Equations.*` modules (not all files in `src/` are exposed) |
| DEPS-03 | Each dep's role + "bump deliberately, never track a branch" documented in README dependency table | Verified true visibility of all three repos (corrects README's `kalecky-semantics` = private → actually public); verified true GitHub HEAD SHAs for the pin table |
| DEPS-04 | Compile-time proof importing a symbol from each dep, or documented executable-only note for stubless deps; `stack build` succeeds end to end | Verified exact Stack error when a library-less extra-dep is added to `dependencies:` (`S-4804`); verified `stack build` succeeds with all three in `extra-deps:` and only the two libraries in `dependencies:`; verified concrete importable symbols from each library |
</phase_requirements>

## Empirical Method

All tests ran in a scratch copy at `/tmp/.../scratchpad/deps-probe` (copied from the real `stack.yaml`, `package.yaml`, `src/`, `test/`, `README.md`) using `/home/jmsbpp/.ghcup/bin/stack` (3.11.1, hpack 0.39.6 bundled). The real repo's `stack.yaml`/`package.yaml` were never edited; `git status --short` on the real repo confirmed no tracked-file changes after the session (one stray `stack exec` accidentally ran against the real repo's already-gitignored `.stack-work/` — harmless, no tracked file touched). The scratch directory was deleted at the end of the session.

## Standard Stack

### Core (verified by direct build, not inferred)

| Extra-dep | Repo | Visibility (verified live) | True GitHub HEAD (verified live) | Has library? | Verified importable symbol |
|-----------|------|------------------------------|-----------------------------------|---------------|------------------------------|
| `kalecky-semantics` | `JMSBPP/kalecky-semantics` | **public** (`gh repo view` → `PUBLIC`) — README currently says "private", this is wrong | `cd6778e2d39c5eb30549d8ff87459b5644cc18fc` (2026-08-25T19:01:29Z) — matches local clone at `/home/jmsbpp/learning/kalecky-semantics`, no drift | Yes — `library` stanza, 20 `exposed-modules` | `Kalecky.Types.Units.Unit (Unit)` (built successfully) |
| the data resource | the data resource (HTTP pointer, v2) | **private** (`gh repo view` → confirmed `private: true`) | `<removed>` (2026-08-25T19:31:39Z) — matches local clone, no drift | Yes — hpack-generated, exposes `Lib` only | `Lib (someFunc)` (built successfully) |
| `haskell-deepseek-plugin-sdk` | `d2p-finance/haskell-deepseek-plugin-sdk` | **public** (matches README) | `de98b6c2c4a49aa9893730fd0c6eee3d489a9a24` (2026-08-25T19:03:41Z) — **local clone at `/home/jmsbpp/ai-agents/haskell-deepseek-plugin-sdk` was behind** (`bd66ebe0...`); diffed the two commits and confirmed the drift is `.planning/` docs only — `src/`, `.cabal`, `stack.yaml` are byte-identical, so the "executable-only, no library" finding below holds at the true current HEAD too | **No** — single `executable` stanza only, no `library` stanza | None possible — see DEPS-04 finding below |

None of the three had any `base` version-bound conflict with GHC 9.10.3 / `base-4.20.2.0` (verified: `stack exec ghc-pkg -- list base` inside the scratch project → `base-4.20.2.0`). `kalecky-semantics` declares `base >= 4.19 && < 5`; both the data resource and the SDK declare `base >= 4.7 && < 5`. All satisfy 4.20.2.0.

**`kalecky-semantics` has zero non-`base` dependencies.** This corrects the project-level `.planning/research/STACK.md`, which anticipated `optics-core`/`optics-th`/`aeson-optics` coupling based on an earlier fork (`kalecky-spec` inside a hevm fork). The current standalone `kalecky-semantics.cabal` (verified by direct read) has `build-depends: base >= 4.19 && < 5` only, in both the `library` and `test-suite` stanzas (test-suite additionally needs `QuickCheck`, `quickcheck-classes`, `tasty`, `tasty-hunit`, `tasty-quickcheck`, none of which are pulled transitively into `sarmiento-plugins` since it only depends on the library). `Kalecky.Types.Units.Unit`'s `Unit` type is exported abstractly (constructor hidden; `unit`/`qty`/`value`/`add`/`align`/`scaleBy` are the only public operations) — importing bare `Unit` as a type is sufficient and requires no `HasScale` instance to compile.

**Not every file in `kalecky-semantics/src/` is exposed.** The repo's `src/Kalecky/` tree has 29 `.hs` files but the `.cabal`'s `exposed-modules` list only 20. Four files are present but **not** declared as `exposed-modules` or `other-modules`, and are therefore currently un-importable from outside the package: `Kalecky.Types.Income`, `Kalecky.Types.StateVector`, `Kalecky.Types.Groups`, all four `Kalecky.Mechanisms.*` modules (`IncomeDistribution`, `ForcedSavings`, `ExpenditureCanalization`, `FundsAllocation`), and `Kalecky.Operators.Elasticity`. When Phase 2's plan writes the "no local dimensional types" verification / DEPS-02 proof, pick the compile-time-proof symbol from the confirmed-exposed list below, not from the broader file tree:

Confirmed `exposed-modules` (importable today):
```
Kalecky.Equations.WageSetting
Kalecky.Operators.Conflict
Kalecky.Operators.Delta
Kalecky.Operators.Effect
Kalecky.Operators.Expectation
Kalecky.Operators.Gap
Kalecky.Operators.GrowthRate
Kalecky.Operators.Indexation
Kalecky.Operators.ResponseMultiplier
Kalecky.Types.Currency
Kalecky.Types.Measure
Kalecky.Types.Numerics
Kalecky.Types.Prices.Price
Kalecky.Types.Prices.PriceIndex
Kalecky.Types.Prices.Wage
Kalecky.Types.Valuation
Kalecky.Types.Units.CompoundUnit
Kalecky.Types.Units.LaborUnit
Kalecky.Types.Units.MoneyUnit
Kalecky.Types.Units.TimeUnit
Kalecky.Types.Units.Unit
```

### `stack.yaml` shape (verified working, copy-paste ready)

```yaml
snapshot:
  url: https://raw.githubusercontent.com/commercialhaskell/stackage-snapshots/master/lts/24/56.yaml

packages:
- .

extra-deps:
- git: https://github.com/JMSBPP/kalecky-semantics.git
  commit: cd6778e2d39c5eb30549d8ff87459b5644cc18fc
- git: <data-resource-url>
  commit: <removed>
- git: https://github.com/d2p-finance/haskell-deepseek-plugin-sdk.git
  commit: de98b6c2c4a49aa9893730fd0c6eee3d489a9a24
```

No `subdirs:` needed for any of the three — each is a single-package repo at its root.

### `package.yaml` `dependencies:` (verified working)

```yaml
dependencies:
- base >= 4.7 && < 5
- kalecky-semantics
- the data resource
# haskell-deepseek-plugin-sdk deliberately NOT listed here — see DEPS-04 finding
```

## Architecture Patterns

### Pattern: Extra-dep resolver mismatch is a non-issue in practice

**What:** Stack solves an extra-dep's own dependencies against the *consumer's* snapshot, ignoring whatever `snapshot:`/`resolver:` the extra-dep's own `stack.yaml` declares.
**Verified:** `kalecky-semantics` declares `lts-23.28` in its own `stack.yaml`; built cleanly on the consumer's `lts-24.56` with no warnings, no version-bound errors, no re-resolution prompts. Full build log (21 modules) completed without incident.
**When it matters:** Only if the extra-dep needs a package/version genuinely absent from or incompatible with the consumer's snapshot — not the case for any of these three today, since all three have either zero or only-`base` dependencies at the library level.

### Pattern: Library-less extra-dep can only ever be `extra-deps:`-only

**What:** An extra-dep whose package provides no `library` component cannot appear in any `dependencies:` list (project, executable, or test-suite) anywhere in the consuming project.
**Verified error (`S-4804`):**
```
Error: [S-4804]
       Stack failed to construct a build plan.

       While constructing the build plan, Stack encountered the following errors:

       In the dependencies for sarmiento-plugins-0.1.0.0:
         * haskell-deepseek-plugin-sdk is a library dependency, but the package provides no library.
       The above is/are needed since sarmiento-plugins is a build target.
```
**Consequence for DEPS-04:** There is no way to write a compile-time import proof for the SDK today. The verified, working alternative is: (1) list it in `extra-deps:` only, (2) `stack build` succeeds and Stack clones + parses its `.cabal` (confirmed: `Cloning de98b6c2c4a49aa9893730fd0c6eee3d489a9a24 from https://github.com/d2p-finance/haskell-deepseek-plugin-sdk.git` appears in the log, and the resulting `stack.yaml.lock` records a real `pantry-tree` sha256/size for it) even though it is **never compiled** (no "Compiling" lines for it appear anywhere in a full `stack build` — it is dead weight in the build plan until something depends on it), (3) `stack build haskell-deepseek-plugin-sdk:exe:...` fails with `S-8506` ("Unknown project package") — Stack refuses to let you force-build an extra-dep that isn't a dependency of any local package, so there is no way to get even an indirect "it compiles" proof without first making something depend on it. The only true, tool-verified claim available today is "the pinned commit exists, its `.cabal` parses, and the overall `stack build` still succeeds with it declared" — write DEPS-04's documented note to make exactly that claim, not a stronger one.

### Pattern: `stack --lock-file error-on-write` as the lockfile-drift check

**What:** Passing `--lock-file error-on-write` makes Stack refuse to silently rewrite `stack.yaml.lock`; if the file it would write differs from what's on disk, the build fails with exit code 1 and error `S-1353`, printing the full would-be lock content as a diff-able error message. If the lock is already in sync, this flag is a no-op (exit 0, normal build).
**Verified both directions:**
- Stale lock (added a second `extra-deps` entry to `stack.yaml` without updating `stack.yaml.lock`) → `Error: [S-1353]` / exit 1.
- In-sync lock → exit 0, normal build output, lock file untouched.

This is the literal mechanism CI-03 needs in Phase 3 (`stack --lock-file error-on-write build`) — record it here so Phase 2's own plan can also self-verify its `stack.yaml.lock` commit is correct before Phase 3 exists, using the exact same command.

### `stack.yaml.lock` shape for git extra-deps (verified, all three present)

```yaml
packages:
- completed:
    commit: cd6778e2d39c5eb30549d8ff87459b5644cc18fc
    git: https://github.com/JMSBPP/kalecky-semantics.git
    name: kalecky-semantics
    pantry-tree:
      sha256: ebd89750a88ff66423b5c645ec19dd7b6d1c456f28e72443a864b2ed78bef972
      size: 9795
    version: 1.0.0
  original:
    commit: cd6778e2d39c5eb30549d8ff87459b5644cc18fc
    git: https://github.com/JMSBPP/kalecky-semantics.git
# ... one such block per extra-dep, including haskell-deepseek-plugin-sdk even though
# it's never compiled — its pantry-tree hash is still recorded, so drift on IT is
# also caught by --lock-file error-on-write.
snapshots:
- completed:
    sha256: 121a2b65e6842f67819409330694d068e6276f64df87faaf2a66c0016ddf277b
    size: 732456
    url: https://raw.githubusercontent.com/commercialhaskell/stackage-snapshots/master/lts/24/56.yaml
  original:
    url: https://raw.githubusercontent.com/commercialhaskell/stackage-snapshots/master/lts/24/56.yaml
```

`version:` in the lock is read from the extra-dep's own `.cabal`/`package.yaml` at the pinned commit (`1.0.0` for kalecky-semantics, `0.1.0.0` for the other two) — not something the consuming project controls. `pantry-tree` is a content hash of the extra-dep's source tree at that commit, so it changes if the upstream repo ever rewrites history at the same-looking commit reference (won't happen for an immutable SHA, but would for a branch — this is part of why "pin by commit, never track a branch" is enforceable: a branch ref would make the lock's `pantry-tree` the actual pin, silently, which defeats the purpose of a human-readable commit pin in `stack.yaml`).

### Private-repo fetch: verified working today with zero extra config

`git config --global --get-regexp 'credential|url\..*insteadof'` on this machine shows:
```
credential.https://github.com.helper !/usr/bin/gh auth git-credential
credential.https://gist.github.com.helper !/usr/bin/gh auth git-credential
```
No `url.insteadOf` rewrite is configured or needed locally. `git clone <data-resource-url>` (plain HTTPS, no token in the URL) succeeded directly, and `stack build` with the data resource as a git extra-dep over HTTPS cloned and built it without any prompt or failure — Stack shells out to the same `git` binary, so it transparently inherits the `gh`-managed credential helper. **Use the plain `https://github.com/...` form in `stack.yaml`** (not `git@github.com:...`), because that is exactly the form Phase 3's `git config url."https://x-access-token:${TOKEN}@github.com/".insteadOf "https://github.com/"` CI pattern rewrites — using SSH locally would require a second, CI-incompatible form to be documented and kept in sync.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|--------------|-----|
| Detecting stale `stack.yaml.lock` | A custom script diffing `stack.yaml` against `stack.yaml.lock` | `stack --lock-file error-on-write build` | Verified to already do exactly this, with the correct exit code and a readable diff, natively |
| Proving a library-less extra-dep resolves | A wrapper script that tries `git ls-remote`/manual clone-and-inspect | `stack build` with the dep in `extra-deps:` (not `dependencies:`) — the log line `Cloning <sha> from <url>` plus a `pantry-tree` entry in the resulting lock **is** the proof | Stack already fetches and content-hashes it as part of normal dependency-plan construction; a bespoke check would duplicate this for no additional certainty |

## Common Pitfalls

### Pitfall 1: Assuming `Kalecky.Types.*` means "every file in kalecky-semantics' src tree"

**What goes wrong:** DEPS-02's phrasing ("`Kalecky.Types.*` are importable") is broader than what's actually exposed. Picking `Kalecky.Types.Income`, `Kalecky.Types.StateVector`, or `Kalecky.Types.Groups` for the compile-time proof will fail to compile — not because of a Stack/dependency problem, but because those modules aren't in `exposed-modules`.
**How to avoid:** Use one of the 20 confirmed-exposed modules listed above (e.g., `Kalecky.Types.Units.Unit`, verified to build).
**Warning sign:** GHC error "Could not find module" for a `Kalecky.*` name that clearly exists as a file in the upstream repo's `src/` tree.

### Pitfall 2: Listing `haskell-deepseek-plugin-sdk` in `package.yaml` `dependencies:` "just to be consistent" with the other two

**What goes wrong:** Immediate, unambiguous build failure (`S-4804`), because the package has no `library` component to depend on.
**How to avoid:** Keep it in `stack.yaml` `extra-deps:` only. Write the DEPS-04 executable-only note explicitly in README/plan, don't attempt an import.

### Pitfall 3: Trusting the local clone of `haskell-deepseek-plugin-sdk` at `/home/jmsbpp/ai-agents/haskell-deepseek-plugin-sdk` for the pin

**What goes wrong:** That local clone's `HEAD` (`bd66ebe0...`) is stale relative to the true GitHub HEAD (`de98b6c2c4a4...`) by several commits. The drift happened to be docs-only this time (verified via `git diff HEAD origin/main -- src/ '*.cabal' stack.yaml package.yaml` → empty), but that's not guaranteed for future bumps.
**How to avoid:** Always verify the pin against `gh api repos/<owner>/<repo>/commits/HEAD --jq .sha` at plan/execution time, not against a possibly-stale local clone path.

### Pitfall 4: README's dependency table currently mis-states `kalecky-semantics` as "private"

**What goes wrong:** DEPS-03 requires documenting each dep's visibility. If the existing README wording is copied forward unchanged, it will state something the empirical check contradicts (`gh repo view JMSBPP/kalecky-semantics --json visibility` → `PUBLIC`).
**How to avoid:** Correct the table when DEPS-03 lands: `kalecky-semantics` = public. Only the data resource is genuinely private among the three (confirmed `private: true`). This also simplifies CI-02's later scope: only one repo (the data resource) needs token-based auth; both public repos fetch without credentials in CI just as they did here without any explicit config.

## Code Examples

Verified working proof-of-import module (built successfully with `stack build` against the pinned commits above):

```haskell
module Sarmiento.Plugin
  ( pluginName
  , pluginVersion
  , KaleckyUnitProof
  , etlSomeFunc
  ) where

import Kalecky.Types.Units.Unit (Unit)
import qualified Lib

-- | Compile-time proof that kalecky-semantics resolves and is importable.
type KaleckyUnitProof basis = Unit basis

-- | Compile-time proof that the data resource resolves and is importable.
etlSomeFunc :: IO ()
etlSomeFunc = Lib.someFunc

pluginName :: String
pluginName = "sarmiento-plugins"

pluginVersion :: String
pluginVersion = "0.1.0.0"
```

`stack build` output for this module (trimmed): `kalecky-semantics> ... Building library ... [21 of 21] Compiling Kalecky.Equations.WageSetting`, then `the data resource > ... [1 of 2] Compiling Lib`, then `sarmiento-plugins> ... [2 of 2] Compiling Sarmiento.Plugin`, then `Completed 3 action(s).` — full end-to-end success, no warnings beyond the pre-existing scratch-copy artefact (`CHANGELOG.md` missing, an artifact of the scratch copy, not a real finding).

`stack test` also passed cleanly against this same wiring (existing smoke test unaffected, `All 1 tests passed`).

## State of the Art

| Old (project-research assumption, from `.planning/research/STACK.md`) | Actual (verified live 2026-08-25) | Impact |
|---|---|---|
| `kalecky` is "trapped in a Cabal sublibrary" inside a hevm fork (`kalecky-spec`), blocked by Stack issues #5318/#5256 | `kalecky-semantics` is a plain standalone Stack/Cabal project at `JMSBPP/kalecky-semantics`, commit `cd6778e`, builds as a normal git extra-dep with zero issues | The blocker STACK.md and PITFALLS.md both flagged as a hard Phase-0 gate is already resolved — no vendoring, no sublibrary workaround needed in Phase 2 |
| `kalecky`'s source pulls in `optics-core`/`optics-th`/`aeson-optics` | `kalecky-semantics.cabal` has zero non-`base` dependencies in its `library` stanza | Depending on `kalecky-semantics` does not pull any optics library into `sarmiento-plugins`' dependency closure |
| README states `kalecky-semantics` visibility as private | Verified `PUBLIC` via `gh repo view` | Correct the README table in DEPS-03; simplifies CI-02 scope to one private repo, not two |
| `haskell-deepseek-plugin-sdk` local clone treated as source of truth for pin | True GitHub HEAD is several commits ahead (docs-only diff, confirmed) | Always re-verify against `gh api .../commits/HEAD`, not a local clone, when picking the pin |

## Open Questions

1. **Will `haskell-deepseek-plugin-sdk` gain a library stanza before Phase 2 executes?**
   - What we know: as of the verified HEAD (`de98b6c2c4a4`, 2026-08-25T19:03), it is still a single-file `executable` scaffold with no library.
   - What's unclear: this is a fast-moving parallel-development repo (per `.planning/STATE.md`'s own blocker note); it could change before the plan is executed.
   - Recommendation: re-run `gh api repos/d2p-finance/haskell-deepseek-plugin-sdk/commits/HEAD --jq .sha` and re-check for a `library:` in `package.yaml`/`library` stanza in `.cabal` immediately before writing the plan's actual pin — don't reuse this research's SHA blindly if significant time has passed.

2. **Does the "bump deliberately, never track a branch" discipline need a CI enforcement mechanism in Phase 2, or is documentation-only sufficient for this phase?**
   - What we know: `stack --lock-file error-on-write build` already mechanically prevents silent lock drift; this doesn't by itself prevent someone from hand-editing `stack.yaml` to point at a branch name instead of a commit SHA.
   - What's unclear: whether Phase 2's scope includes a lint/check for "extra-deps entries must have a `commit:` key, never a `branch:`", or whether that's deferred to Phase 3's CI.
   - Recommendation: Phase 2's plan can add a trivial `grep -c 'commit:' stack.yaml` sanity check (three occurrences expected) as a cheap, no-new-tooling guard; formal CI enforcement stays in Phase 3 per the roadmap's phase boundary.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | tasty 1.5.4 + tasty-quickcheck + QuickCheck (already wired in Phase 1) |
| Config file | `package.yaml` `tests.sarmiento-plugins-test` stanza |
| Quick run command | `stack build` (compile-time proof — the actual verification for DEPS-01/02/04 is that this succeeds, not a runtime test) |
| Full suite command | `stack test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|---------------------|--------------|
| DEPS-01 | `stack.yaml` extra-deps pinned by commit for the data resource + SDK; lock committed | build/compile | `stack --lock-file error-on-write build` | ✅ (existing `stack.yaml`/`stack.yaml.lock`, edited in-place) |
| DEPS-02 | `kalecky-semantics` extra-dep + `package.yaml` dependency; `Kalecky.Types.*` importable; no local dimensional types | build/compile + grep | `stack build` succeeds; `grep -rn 'newtype\|data' src/ \| grep -vi -E 'Sarmiento\.Plugin'` manually reviewed for accidental local unit types (no automated negative-grep test exists yet — Wave 0 gap below) | ⚠️ Wave 0 — no existing grep-based check |
| DEPS-03 | README dependency table documents role/visibility/pin/why per dep | manual doc review | none (documentation requirement, not code) | N/A |
| DEPS-04 | Compile-time proof module imports a symbol from each importable dep; executable-only dep documented; `stack build` succeeds end-to-end | build/compile | `stack build` (the proof module compiling *is* the test) | ✅ `src/Sarmiento/Plugin.hs` exists (Phase 1), edited in place for Phase 2 |

### Sampling Rate
- **Per task commit:** `stack build` (fast — only recompiles what changed; confirmed under ~1s once packages are precompiled/cached)
- **Per wave merge:** `stack --lock-file error-on-write build && stack test`
- **Phase gate:** `stack --lock-file error-on-write build && stack test` green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] No automated "no local dimensional type" negative check exists (DEPS-02's "no local dimensional types are defined" clause is currently manual-review-only). A cheap Wave 0 addition: a `grep`-based smoke check in the test-suite or a CI step asserting no `newtype`/`data` declaration for a units-shaped name (`Price`, `Wage`, `Currency`, `Measure`, `Unit`) appears outside of `Sarmiento.Plugin`'s import lines. Not strictly required to unblock Phase 2 (the requirement is satisfiable by code review alone at this repo's current tiny size), but flagged since it's the kind of check that gets more valuable as the codebase grows and is cheap to add now.
- [ ] No test currently exercises `stack --lock-file error-on-write build` as part of `stack test` — it's a separate Stack invocation, not a Haskell test. Document it as a manual/CI-gate step (this is exactly what Phase 3's CI-03 will automate; Phase 2 only needs to run it once by hand to confirm the committed lock is correct before commit).

*(No gaps block DEPS-01/DEPS-02/DEPS-04 — those are proven by `stack build` succeeding, which is already fully automatable with existing tooling.)*

## Sources

### Primary (HIGH confidence — empirically verified this session)
- Live `stack build`/`stack test` runs against all three pinned commits in a scratch copy — full logs captured above
- `gh api repos/the data resource/commits/HEAD`, `repos/JMSBPP/kalecky-semantics/commits/HEAD`, `repos/d2p-finance/haskell-deepseek-plugin-sdk/commits/HEAD` — live SHA + timestamp verification
- `gh repo view <repo> --json visibility,isPrivate` for all three repos — live visibility verification
- Direct read of `kalecky-semantics.cabal`, `the data resource.cabal`/`package.yaml`, `haskell-deepseek-plugin-sdk.cabal` at their pinned commits (local clones, cross-checked against true GitHub HEAD via `git diff HEAD origin/main`)
- `git config --global --get-regexp 'credential|url.*insteadof'` and a live `git clone <data-resource-url>` — verified local private-repo auth path
- `stack --lock-file error-on-write build` run twice (stale lock → `S-1353`/exit 1; in-sync lock → exit 0) — verified drift-detection mechanism
- `stack exec ghc-pkg -- list base` inside the scratch project — verified `base-4.20.2.0` for GHC 9.10.3/lts-24.56

### Secondary (MEDIUM confidence)
- None — every claim in this document traces to a command actually run this session.

## Metadata

**Confidence breakdown:**
- Standard stack (pins, versions, importable symbols): HIGH — every pin/version/symbol was compiled successfully, not inferred
- Architecture (lockfile shape, error messages, resolver-mismatch behavior): HIGH — exact error codes and log lines captured verbatim
- Pitfalls: HIGH — each pitfall was actually triggered and its exact error message recorded, except Pitfall 3 (local-clone staleness) which is HIGH by direct `git diff` comparison

**Research date:** 2026-08-25
**Valid until:** Short — 3-7 days. Two of the three upstreams (the data resource, `haskell-deepseek-plugin-sdk`) are being actively developed in parallel by the same author per `.planning/STATE.md`'s own blocker note; re-verify commit SHAs and library-stanza presence immediately before the plan is executed, not from this document alone.
