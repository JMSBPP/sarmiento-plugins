$onText
================================================
	-------> TechDiffusion <-----------------
		 Parameter TechDiffusion(Labor, Technology)
================================================
$offText

$include "build/deps.inc"
$if not declared Labor $include "%KALECKY_GAMS_SRC%parameters/Production.gms"

Parameter TechDiffusion(Labor, Technology);
