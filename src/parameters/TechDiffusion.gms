$onText
================================================
	-------> INPUT <-----------------
		 TODO: Lock notation
===============================================
$offText

$include "build/deps.inc"
$if not declared Labor $include "%KALECKY_GAMS_SRC%parameters/Production.gms"

Parameter TechDiffusion(Labor, Technology);
