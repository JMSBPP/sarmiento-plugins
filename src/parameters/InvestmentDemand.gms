* TODO: Import from production on the kernel. Arguiably this should be imported from the kernel, since capital savings is used on the models for the models that determine optimal profit rate and utilization rate

Sets
    ShortRun       / SR_2026, SR_2027 /
    Capital        / structures, machinery, software /;

Alias (ShortRun, Commitment, Installment);

Parameter Stock(Capital)
    / structures 500, machinery 350, software 120 /;

Set CapitalGestation(Commitment, Installment) /
    SR_2026.SR_2027
    SR_2027.SR_2027
/;

Parameter
    PublicInvestment(Capital)
        / structures 40, machinery 60, software 35 /
    InvestmentDemand(Installment, Capital);

InvestmentDemand(Installment, Capital) =
    sum(Commitment$CapitalGestation(Commitment, Installment),
        PublicInvestment(Capital));

Display InvestmentDemand;

