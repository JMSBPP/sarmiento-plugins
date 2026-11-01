* $include "gams-deps.inc"
* $if not declared Labor $include "%KALECKY_GAMS_SRC%parameters/Production.gms"


* TODO: This is temporal while imports are solved
Set Technology, Capital, Labor;
Parameter SubstitutionElasticities(Labor,Capital);

