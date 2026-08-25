-- |
-- Module      : Sarmiento.Upstream
-- Description : Compile-time proof that this project's upstream dependencies resolve.
--
-- This module exists to be compiled, not to be called. Each declaration below touches one
-- upstream package, so a broken dependency edge shows up as a GHC "Could not find module"
-- error during @stack build@ rather than as a surprise much later, when the real claim and
-- shock types are written against those packages in v2.
--
-- Two of the three upstreams are represented here. The third,
-- @haskell-deepseek-plugin-sdk@, provides a @library@ stanza at its pinned commit, but every
-- exposed module has an empty export list, so there is no symbol to import: it is pinned in
-- @stack.yaml@ @extra-deps@ only, and README.md records the pinned commit's status until
-- upstream's library modules gain real exports.
--
-- No dimensional or unit type is declared here. 'UnitProof' is a synonym over a type
-- imported from @kalecky-semantics@, which remains this project's single source of units.
module Sarmiento.Upstream
  ( UnitProof
  , etlEntryPoint
  , upstreamProofTag
  ) where

import Kalecky.Types.Units.Unit (Unit)
import qualified Lib

-- | A synonym over the imported unit type. Its only job is to force GHC to resolve
-- @Kalecky.Types.Units.Unit@ at compile time. @Unit@ is exported abstractly upstream — its
-- data constructor is hidden — so naming the type is the strongest proof available without
-- committing this project to upstream's smart constructors, which is v2 work.
type UnitProof basis = Unit basis

-- | The entry point exposed by the ETL package today. Re-exported rather than called: the
-- real read API for @mamertomics-db@ does not exist yet, so this is a dependency-edge
-- proof, not a feature.
etlEntryPoint :: IO ()
etlEntryPoint = Lib.someFunc

-- | A value the test-suite can hold onto, so the test-suite's own compilation depends on
-- this module and therefore on both upstream edges. A property over @base@-only values
-- would compile against a broken link and prove nothing.
upstreamProofTag :: String
upstreamProofTag = "upstream-libraries-wired"
