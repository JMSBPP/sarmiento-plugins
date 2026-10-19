||| CLI edge: read `gams-deps.toml`, resolve checkout, emit `src/build/deps.inc`.
module GamsDepsEmit

import Data.String
import GamsDeps.AbsPath
import GamsDeps.DepsInc
import GamsDeps.GitPin
import GamsDeps.Ops
import System
import System.File

%default covering

||| Drop program name and optional `--` separators; keep real argv tokens.
userArgs : List String -> List String
userArgs args =
  filter (\a => a /= "--") (drop 1 args)

||| First absolute path on the CLI, if any.
cliAbsPath : List String -> Maybe AbsPath
cliAbsPath [] = Nothing
cliAbsPath (a :: as) =
  if isPrefixOf "/" a then Just (MkAbsPath a) else cliAbsPath as

||| Candidate GAMS src path: absolute CLI arg or `$KALECKY_CHECKOUT/<subdir>`.
candidateFor : GitPin -> IO (Maybe AbsPath)
candidateFor pin = do
  args <- getArgs
  case cliAbsPath (userArgs args) of
    Just path => pure (Just path)
    Nothing => do
      mRoot <- getEnv "KALECKY_CHECKOUT"
      case mRoot of
        Nothing => pure Nothing
        Just root =>
          let base = if isSuffixOf "/" root then root else root ++ "/"
          in pure (Just (MkAbsPath (base ++ pin.subdir)))

failMsg : String -> IO ()
failMsg msg = do
  putStrLn ("gams-deps-emit: " ++ msg)
  exitWith (ExitFailure 1)

||| Resolve every pin; concatenate rendered `DepsInc` fragments.
resolveAll : List GitPin -> IO (Either String DepsInc)
resolveAll [] = pure (Left "no pins in gams-deps.toml")
resolveAll pins = go pins ""
  where
    go : List GitPin -> String -> IO (Either String DepsInc)
    go [] acc =
      if acc == ""
         then pure (Left "empty DepsInc after resolve")
         else pure (Right (MkDepsInc acc))
    go (pin :: rest) acc = do
      mCand <- candidateFor pin
      case mCand of
        Nothing =>
          pure (Left "missing checkout (pass absolute GAMS src path or set KALECKY_CHECKOUT)")
        Just cand =>
          case resolve pin cand of
            Nothing =>
              pure (Left ("resolve failed for subdir=" ++ pin.subdir
                           ++ " path=" ++ absPathString cand))
            Just path =>
              go rest (acc ++ depsIncString (render path))

main : IO ()
main = do
  Right toml <- readFile "gams-deps.toml"
    | Left err => failMsg ("cannot read gams-deps.toml: " ++ show err)
  let pins = parseManifest toml
  Right deps <- resolveAll pins
    | Left err => failMsg err
  emit deps
