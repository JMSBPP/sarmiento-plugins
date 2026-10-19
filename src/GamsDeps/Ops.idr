||| gamsDeps operations: manifest → pin → path → deps.inc → disk.
|||
||| $$
||| \begin{align*}
||| \mathrm{parseManifest} &: \mathrm{String} \to \mathrm{List}\,\mathrm{GitPin} \\
||| \mathrm{resolve} &: \mathrm{GitPin} \to \mathrm{AbsPath} \to \mathrm{Maybe}\,\mathrm{AbsPath} \\
||| \mathrm{render} &: \mathrm{AbsPath} \to \mathrm{DepsInc} \\
||| \mathrm{emit} &: \mathrm{DepsInc} \to \mathrm{IO}\,()
||| \end{align*}
||| $$
|||
||| Law: missing checkout $\Rightarrow$ $\mathrm{resolve}=\mathsf{Nothing}$;
||| do not emit an empty $\mathrm{DepsInc}$.
|||
||| --- types.toml: gamsDeps.Ops ---
module GamsDeps.Ops

import Data.List
import Data.String
import GamsDeps.AbsPath
import GamsDeps.DepsInc
import GamsDeps.GitPin
import System
import System.Directory
import System.File

%default total

--------------------------------------------------------------------------------
-- helpers
--------------------------------------------------------------------------------

||| Trim ASCII whitespace from both ends.
trimWS : String -> String
trimWS = trim

||| Unquote a TOML string literal (`"..."` or bare).
unquote : String -> String
unquote s =
  let t = trimWS s in
  if length t >= 2 && isPrefixOf "\"" t && isSuffixOf "\"" t
     then substr 1 (length t `minus` 2) t
     else t

eqChar : Char
eqChar = chr 61

||| Value after first equals sign on a TOML assignment line.
valueAfterEq : String -> Maybe String
valueAfterEq line =
  case break (== eqChar) (unpack line) of
    (_, _ :: rest) => Just (unquote (pack rest))
    _ => Nothing

||| Lookup a TOML key in a block's lines.
lookupField : String -> List String -> Maybe String
lookupField key lines =
  let spaced = key ++ pack [' ', eqChar]
      glued = key ++ pack [eqChar]
  in case find (\l => isPrefixOf spaced (trimWS l) || isPrefixOf glued (trimWS l)) lines of
       Nothing => Nothing
       Just line => valueAfterEq line

||| Split manifest text into `[[pin]]` blocks (header line dropped).
pinBlocks : String -> List (List String)
pinBlocks src =
  let ls = lines src
      go : List String -> List String -> List (List String) -> List (List String)
      go [] acc blocks =
        if isNil acc then reverse blocks else reverse (reverse acc :: blocks)
      go (l :: ls') acc blocks =
        if trimWS l == "[[pin]]"
           then go ls' [] (if isNil acc then blocks else reverse acc :: blocks)
           else go ls' (l :: acc) blocks
  in go ls [] []

parsePinBlock : List String -> Maybe GitPin
parsePinBlock blk = do
  url <- lookupField "url" blk
  commit <- lookupField "commit" blk
  subdir <- lookupField "subdir" blk
  pure (MkGitPin url commit subdir)

stripTrailingSlash : String -> String
stripTrailingSlash p =
  if length p > 1 && isSuffixOf "/" p
     then substr 0 (length p `minus` 1) p
     else p

ensureTrailingSlash : String -> String
ensureTrailingSlash p =
  if isSuffixOf "/" p then p else p ++ "/"

||| True when absolute path ends with `/subdir` (optional trailing `/`).
endsWithSubdir : (subdir : String) -> (path : String) -> Bool
endsWithSubdir subdir path =
  let t = stripTrailingSlash path in
  isSuffixOf ("/" ++ subdir) t || t == subdir

--------------------------------------------------------------------------------
-- operations
--------------------------------------------------------------------------------

||| Parse `gams-deps.toml` text into pins (`[[pin]]` tables).
public export
parseManifest : String -> List GitPin
parseManifest src =
  mapMaybe parsePinBlock (pinBlocks src)

||| Pure resolve: accept a non-empty absolute candidate whose path
||| ends with the pin's `subdir`; otherwise `Nothing`.
public export
resolve : GitPin -> AbsPath -> Maybe AbsPath
resolve pin (MkAbsPath p) =
  let t = stripTrailingSlash (trimWS p) in
  if t == "" || not (isPrefixOf "/" t)
     then Nothing
     else if endsWithSubdir pin.subdir t
             then Just (MkAbsPath t)
             else Nothing

||| Render one absolute GAMS src path as `$setGlobal KALECKY_GAMS_SRC`.
|||
||| $$
||| \mathrm{render}(p) = \texttt{\$setGlobal KALECKY\_GAMS\_SRC '}\,p\texttt{/'}
||| $$
public export
render : AbsPath -> DepsInc
render (MkAbsPath p) =
  MkDepsInc ("$setGlobal KALECKY_GAMS_SRC '" ++ ensureTrailingSlash p ++ "'\n")

||| Write `DepsInc` to `src/build/deps.inc` (IO edge).
public export
covering
emit : DepsInc -> IO ()
emit (MkDepsInc contents) = do
  when (contents == "") $ do
    putStrLn "gams-deps-emit: refusing to emit empty DepsInc"
    exitWith (ExitFailure 1)
  _ <- createDir "src"
  _ <- createDir "src/build"
  Right _ <- writeFile "src/build/deps.inc" contents
    | Left err => do
        putStrLn ("gams-deps-emit: write failed: " ++ show err)
        exitWith (ExitFailure 1)
  pure ()
