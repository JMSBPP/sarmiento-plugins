-- |
-- Module      : Sarmiento.Plugin
-- Description : Scaffold library surface for the sarmiento-plugins harness plugin.
--
-- This module exists so the scaffold has a real, compiling library component that the
-- test-suite can link against. The plugin's actual surface — the claim ADT, the shock
-- ADT, and the JSON-RPC client — arrives once the upstream dependencies expose their
-- APIs. Nothing here encodes any economic content, and no dimensional or unit type is
-- defined in this project: those come from @kalecky-semantics@.
module Sarmiento.Plugin
  ( pluginName
  , pluginVersion
  ) where

-- | The identifier this plugin registers under with the DeepSeek Harness runtime.
pluginName :: String
pluginName = "sarmiento-plugins"

-- | The scaffold version, kept in step with the @version@ field in @package.yaml@.
pluginVersion :: String
pluginVersion = "0.1.0.0"
