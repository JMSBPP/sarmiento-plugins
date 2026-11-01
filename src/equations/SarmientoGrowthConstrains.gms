
* TODO: This needs to be imported
Set Horizon /SHORT_RUN, LONG_RUN/;

* TODO: This needs better naming

Variable GrowthEffectOfIncomeDist (Horizon);

$setLocal POSITIVE 0
$setLocal NEGATIVE 0

Equation SarmientoShortRunGrowthEffectOfIncome, SarmientoLongRunGrowthEffectOfIncome;
SarmientoLongRunGrowthEffectOfIncome.. GrowthEffectOfIncomeDist ('LONG_RUN') =g= %POSITIVE%;
SarmientoShortRunGrowthEffectOfIncome.. GrowthEffectOfIncomeDist('SHORT_RUN') =l= %NEGATIVE%;

