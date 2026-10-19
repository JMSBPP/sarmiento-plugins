||| Absolute filesystem path carrier for a GAMS src checkout.
|||
||| $$
||| \mathrm{AbsPath} ::= \mathrm{MkAbsPath}(p)
||| \quad\text{where } p \text{ is an absolute path string}
||| $$
|||
||| --- types.toml: gamsDeps.AbsPath ---
module GamsDeps.AbsPath

%default total

public export
data AbsPath : Type where
  MkAbsPath : (path : String) -> AbsPath

public export
absPathString : AbsPath -> String
absPathString (MkAbsPath p) = p

public export
Eq AbsPath where
  (MkAbsPath a) == (MkAbsPath b) = a == b

public export
Show AbsPath where
  show (MkAbsPath p) = "MkAbsPath " ++ show p
