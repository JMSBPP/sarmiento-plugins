||| Git pin for a GAMS-bearing dependency (from `gams-deps.toml`).
|||
||| $$
||| \mathrm{GitPin} ::= \{\,\mathrm{url},\;\mathrm{commit},\;\mathrm{subdir}\,\}
||| $$
|||
||| --- types.toml: gamsDeps.GitPin ---
module GamsDeps.GitPin

%default total

public export
record GitPin where
  constructor MkGitPin
  url : String
  commit : String
  subdir : String

public export
Eq GitPin where
  (MkGitPin u1 c1 s1) == (MkGitPin u2 c2 s2) =
    u1 == u2 && c1 == c2 && s1 == s2

public export
Show GitPin where
  show (MkGitPin u c s) =
    "MkGitPin \{show u} \{show c} \{show s}"
