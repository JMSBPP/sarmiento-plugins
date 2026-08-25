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
