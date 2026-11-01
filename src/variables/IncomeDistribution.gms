* $include "gams-deps.inc"
* $if not declared Labor $include "%KALECKY_GAMS_SRC%variables/Income.gms"

$onText
\(\psi (Y):\texttt{IncomeDist}\)
- \(\texttt{IncomeDist}\): is a path-dependent type
$offText

*$if not declared Horizon $include paramters/Horizon.gms

* TODO: Have it be imported from parameters/Horizon
Set Horizon / LONG_RUN, SHORT_RUN/;



