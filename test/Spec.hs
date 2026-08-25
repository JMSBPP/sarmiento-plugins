-- |
-- Smoke test suite for the sarmiento-plugins scaffold.
--
-- One property, deliberately trivial in content. Its job is not to test economics — there
-- is no economics in this repository yet — but to prove that the tasty runner, the
-- QuickCheck integration, the test-suite's dependency on the library component, and the
-- @stack test@ path all work. That makes the CI test job added in Phase 3 non-trivial from
-- its very first run, instead of a placeholder that passes vacuously.
module Main (main) where

import Sarmiento.Plugin (pluginName)
import Test.Tasty (TestTree, defaultMain, testGroup)
import Test.Tasty.QuickCheck (Property, testProperty, (===))

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
  testGroup
    "sarmiento-plugins scaffold smoke tests"
    [ testProperty "reverse . reverse == id" prop_reverseInvolutive
    ]

-- | @reverse@ is an involution on lists. The subject is built from 'pluginName' rather than
-- from the generated 'String' alone, so this module fails to compile if the test-suite ever
-- loses its dependency on the library component — a property over @base@-only values would
-- compile against a broken link and prove nothing.
prop_reverseInvolutive :: String -> Property
prop_reverseInvolutive suffix = reverse (reverse subject) === subject
  where
    subject = pluginName <> suffix
