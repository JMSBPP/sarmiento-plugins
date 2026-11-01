* TODO: This needs better organization and explitting

Sets
    IncomeGroup  / Bottom, Mean /;

Parameter TrendIncome(IncomeGroup);


Variable Covariance(IncomeGroup, IncomeGroup);

$setLocal POSITIVE 0
Equation SarmientoTrendCoMoveLaw;
SarmientoTrendCoMoveLaw.. Covariance('Bottom', 'Mean') =g= %POSITIVE%;
