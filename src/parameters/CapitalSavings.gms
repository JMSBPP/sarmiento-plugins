* TODO: import from Horizon
* TODO: Import from production on the kernel. Arguiably this should be imported from the kernel, since capital savings is used on the models for the models that determine optimal profit rate and utilization rate

Sets
    ShortRun       / SR_2026, SR_2027 /
    Capital        / structures, machinery, software / ;


Alias(ShortRun, Formation, Allocation);

Parameter Stock(Capital) / structures 500, machinery 350, software 120 /;

* 2. Use aliases to map short-run to short-run
Set AssetTransition(Formation, Allocation) /
    SR_2026 . SR_2027
    SR_2027 . SR_2027
/ ;


Parameter CapitalSavings(Allocation, Capital);
CapitalSavings(Allocation, Capital) = sum(ShortRunFrom$AssetTransition(Formation, Allocation), Stock(Capital));

Display CapitalSavings;
