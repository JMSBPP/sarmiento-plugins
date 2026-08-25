# Changelog for `sarmiento-plugins`

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this
project adheres to the [Haskell Package Versioning Policy](https://pvp.haskell.org/).

## Unreleased

### Added

- Stack scaffold pinned to Stackage `lts-24.56` (GHC 9.10.3), matching `mamertomics-etl`.
- hpack `package.yaml` with a library in `src/` and a test-suite in `test/`; no executable yet.
- `-Wall`-plus warning set matching `mamertomics-etl`.
- `Sarmiento.Plugin` placeholder library module.
- `src/Education/` placeholder directory for the forthcoming claim-taxonomy notes.
- tasty + QuickCheck smoke test-suite, so the CI test job is non-trivial from its first run.
- `README.md` describing the plugin, its three upstreams, and the build/test commands.
- `.gitignore` covering build artefacts, `.env` files, and credential material.
- Three upstream git `extra-deps` in `stack.yaml`, each pinned by commit SHA and fetched over
  HTTPS: `JMSBPP/kalecky-semantics` (public), `JMSBPP/mamertomics-etl` (private), and
  `d2p-finance/haskell-deepseek-plugin-sdk` (public). No dependency tracks a branch.
- `package.yaml` library dependencies on `kalecky-semantics` and `mamertomics-etl`.
  `haskell-deepseek-plugin-sdk` is deliberately excluded: at its pinned commit its `library`
  stanza exists but every exposed module is an empty stub with no exports, so there is no
  symbol to import or compile-check against.
- `src/Sarmiento/Upstream.hs`, a compile-time proof module importing `Unit` from
  `Kalecky.Types.Units.Unit` and `someFunc` from `mamertomics-etl`'s `Lib`. A broken pin is now
  a compile error rather than a late surprise.
- A second smoke property in `test/Spec.hs` whose subject is drawn from `Sarmiento.Upstream`,
  so the test-suite fails to compile — not merely to pass — if either upstream edge breaks.
- `scripts/check-no-local-dimensional-types.sh`, which fails if any local `data`/`newtype`/`type`
  declares a unit-shaped name, or if `kalecky`/`Currency`/`Measure`/`Valuation` appears in
  `src/` or `test/` anywhere other than a `Kalecky.*` import or a comment.
- README dependency table with each upstream's owner, visibility, pinned commit and role, plus
  the "pin by commit, never track a branch" rule and a numbered bump procedure ending in
  `stack --lock-file error-on-write build`.

### Fixed

- README stated `kalecky-semantics` as a private repository. It is public; `mamertomics-etl` is
  the only private upstream of the three.
