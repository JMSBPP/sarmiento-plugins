||| Generated GAMS `deps.inc` text (Dollar `$setGlobal` lines).
|||
||| $$
||| \mathrm{DepsInc} ::= \mathrm{MkDepsInc}(t)
||| \quad\text{where } t \text{ is the exact file contents}
||| $$
|||
||| --- types.toml: gamsDeps.DepsInc ---
module GamsDeps.DepsInc

%default total

public export
data DepsInc : Type where
  MkDepsInc : (contents : String) -> DepsInc

public export
depsIncString : DepsInc -> String
depsIncString (MkDepsInc t) = t

public export
Eq DepsInc where
  (MkDepsInc a) == (MkDepsInc b) = a == b

public export
Show DepsInc where
  show (MkDepsInc t) = "MkDepsInc " ++ show t
