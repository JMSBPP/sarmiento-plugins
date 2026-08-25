-- |
-- Smoke test suite for the sarmiento-plugins scaffold.
--
-- Deliberately trivial in content. Its job is not to test economics — there is no economics
-- in this repository yet — but to prove that the tasty runner, the QuickCheck integration,
-- the test-suite's dependency on the library component, and the @stack test@ path all work.
-- That makes the CI test job added in Phase 3 non-trivial from its very first run, instead
-- of a placeholder that passes vacuously.
--
-- Since Phase 2 the suite also imports 'Sarmiento.Upstream', which in turn imports a symbol
-- from each of the two upstream libraries. That makes a broken dependency edge a compile
-- error in this very file, not a silently absent test.
module Main (main) where

import Sarmiento.Plugin (pluginName)
import Sarmiento.Upstream (upstreamProofTag)
import Test.Tasty (TestTree, defaultMain, testGroup)
import Test.Tasty.QuickCheck (Property, testProperty, (===))

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
  testGroup
    "sarmiento-plugins scaffold smoke tests"
    [ testProperty "reverse . reverse == id" prop_reverseInvolutive
    , testProperty "upstream proof tag survives a reverse round-trip" prop_upstreamLinked
    ]

-- | @reverse@ is an involution on lists. The subject is built from 'pluginName' rather than
-- from the generated 'String' alone, so this module fails to compile if the test-suite ever
-- loses its dependency on the library component — a property over @base@-only values would
-- compile against a broken link and prove nothing.
prop_reverseInvolutive :: String -> Property
prop_reverseInvolutive suffix = reverse (reverse subject) === subject
  where
    subject = pluginName <> suffix

-- | The same involution, with its subject drawn from 'upstreamProofTag'. The assertion is
-- not the point; the import is. 'Sarmiento.Upstream' only compiles when both upstream
-- library edges resolve, so this property cannot even be built against a broken pin.
prop_upstreamLinked :: String -> Property
prop_upstreamLinked suffix = reverse (reverse subject) === subject
  where
    subject = upstreamProofTag <> suffix
