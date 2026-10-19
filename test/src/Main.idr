module Main

import GamsDeps.AbsPath
import GamsDeps.DepsInc
import GamsDeps.GitPin
import GamsDeps.Ops
import System

%default total

||| Behavioral: rendering an absolute GAMS src path yields the Dollar global
||| with a trailing slash.
|||
||| $$
||| \mathrm{render}(\texttt{/home/kalecky/src})
|||   = \texttt{\$setGlobal KALECKY\_GAMS\_SRC '/home/kalecky/src/'}
||| $$
render_sets_kalecky_global : Bool
render_sets_kalecky_global =
  let path = MkAbsPath "/home/kalecky/src"
      expected = MkDepsInc "$setGlobal KALECKY_GAMS_SRC '/home/kalecky/src/'\n"
  in render path == expected

||| Behavioral: empty / relative candidate does not resolve.
resolve_rejects_empty : Bool
resolve_rejects_empty =
  let pin = MkGitPin "https://example.com/r.git" "abc" "src"
  in resolve pin (MkAbsPath "") == Nothing
     && resolve pin (MkAbsPath "relative/src") == Nothing

||| Behavioral: absolute path ending in pin subdir resolves.
resolve_accepts_subdir : Bool
resolve_accepts_subdir =
  let pin = MkGitPin "https://example.com/r.git" "abc" "src"
      cand = MkAbsPath "/home/kalecky/src"
  in resolve pin cand == Just (MkAbsPath "/home/kalecky/src")

||| Behavioral: `[[pin]]` manifest parses url/commit/subdir.
parse_one_pin : Bool
parse_one_pin =
  let toml = """
             [[pin]]
             url = "https://github.com/JMSBPP/kalecky-semantics.git"
             commit = "d724d67bd7fa18da559d6902bb3882159a901ac8"
             subdir = "src"
             """
      pins = parseManifest toml
  in case pins of
       [MkGitPin u c s] =>
         u == "https://github.com/JMSBPP/kalecky-semantics.git"
         && c == "d724d67bd7fa18da559d6902bb3882159a901ac8"
         && s == "src"
       _ => False

covering
main : IO ()
main = do
  let checks =
        [ ("render_sets_kalecky_global", render_sets_kalecky_global)
        , ("resolve_rejects_empty", resolve_rejects_empty)
        , ("resolve_accepts_subdir", resolve_accepts_subdir)
        , ("parse_one_pin", parse_one_pin)
        ]
  let failed = filter (\(_, ok) => not ok) checks
  case failed of
    [] => putStrLn "Test successful!"
    xs => do
      putStrLn ("FAILED: " ++ show (map fst xs))
      exitWith (ExitFailure 1)
