||| CLI edge: read `gams-deps.toml`, resolve checkout, emit `src/build/deps.inc`.
|||
||| Candidate order: absolute CLI path, then `$KALECKY_CHECKOUT/<subdir>`,
||| else clone/checkout the pin from git into `.cache/gams-deps/`.
module GamsDepsEmit

import Data.List
import Data.String
import GamsDeps.AbsPath
import GamsDeps.DepsInc
import GamsDeps.GitPin
import GamsDeps.Ops
import System
import System.Directory
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

||| Last path segment of a git URL, without `.git`.
repoName : String -> String
repoName url =
  let segs = filter (not . null) (words (pack (map slashToSpace (unpack url))))
  in case segs of
       [] => "dep"
       (x :: xs) => stripGit (last (x :: xs))
  where
    slashToSpace : Char -> Char
    slashToSpace c = if c == '/' then ' ' else c

    stripGit : String -> String
    stripGit s =
      if isSuffixOf ".git" s
         then substr 0 (length s `minus` 4) s
         else s

||| Relative cache dir: `.cache/gams-deps/<repo>/<commit>`.
cacheRelDir : GitPin -> String
cacheRelDir pin =
  ".cache/gams-deps/" ++ repoName pin.url ++ "/" ++ pin.commit

q : String -> String
q s = "'" ++ s ++ "'"

||| Non-zero exit → Left with command text.
sh : String -> IO (Either String ())
sh cmd = do
  code <- system cmd
  pure $ if code == 0 then Right () else Left ("git failed: " ++ cmd)

||| True if path is an existing directory.
dirExists : String -> IO Bool
dirExists p = do
  Right _ <- listDir p
    | Left _ => pure False
  pure True

||| Ensure parent dirs of the cache path exist.
ensureCacheParents : GitPin -> IO ()
ensureCacheParents pin = do
  ignore $ createDir ".cache"
  ignore $ createDir ".cache/gams-deps"
  ignore $ createDir (".cache/gams-deps/" ++ repoName pin.url)

||| Absolute path to pin cache + GAMS subdir, based on cwd.
absGamsSrc : GitPin -> String -> IO (Either String AbsPath)
absGamsSrc pin rel = do
  Just cwd <- currentDir
    | Nothing => pure (Left "getcwd failed")
  pure (Right (MkAbsPath (cwd ++ "/" ++ rel ++ "/" ++ pin.subdir)))

||| Clone (or update) the pin at the pinned commit; return absolute GAMS `subdir` path.
ensureGitCheckout : GitPin -> IO (Either String AbsPath)
ensureGitCheckout pin = do
  ensureCacheParents pin
  let rel = cacheRelDir pin
  hasGit <- dirExists (rel ++ "/.git")
  if hasGit
     then do
       ignore $ system ("git -C " ++ q rel ++ " fetch --quiet origin " ++ q pin.commit ++ " 2>/dev/null")
       Right () <- sh ("git -C " ++ q rel ++ " checkout --quiet " ++ q pin.commit)
         | Left e => pure (Left e)
       absGamsSrc pin rel
     else do
       ignore $ system ("rm -rf " ++ q rel)
       Right () <- sh ("git clone --quiet " ++ q pin.url ++ " " ++ q rel)
         | Left e => pure (Left e)
       Right () <- sh ("git -C " ++ q rel ++ " checkout --quiet " ++ q pin.commit)
         | Left e => pure (Left e)
       absGamsSrc pin rel

||| Candidate GAMS src: CLI, then env, else git pin cache.
candidateFor : GitPin -> IO (Either String AbsPath)
candidateFor pin = do
  args <- getArgs
  case cliAbsPath (userArgs args) of
    Just path => pure (Right path)
    Nothing => do
      mRoot <- getEnv "KALECKY_CHECKOUT"
      case mRoot of
        Just root =>
          let base = if isSuffixOf "/" root then root else root ++ "/"
          in pure (Right (MkAbsPath (base ++ pin.subdir)))
        Nothing => ensureGitCheckout pin

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
      eCand <- candidateFor pin
      case eCand of
        Left err => pure (Left err)
        Right cand =>
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
