


\[
	\begin{aligned}
		\texttt{IncomeDist} \\
		\texttt{EconDevelopment} \\
		\texttt{EconGrowth}
	\end{aligned}
\]


- \(\texttt{IncomeDist}\): path-dependent type 
- \(\texttt{Development}\): is a product type of \(\texttt{MarginalDecreasingCapitalProdty}\) **and** \(\texttt{TechDiffusion}\)

> TODO: We need to further find the type structure of those two types to build development furrther
- \(\texttt{MarginalDecreasingCapitalProdty}\) is a **proof/Theorem** type over \(\texttt{Path} (\texttt{CapitalPty})\)
- \(\texttt{TechDiffusion}\) is a **measure** type over \(\texttt{Technology}, \texttt{Population}\)

- \(\texttt{SubstitutionElasticity}\) is a **measure** type over \(\texttt{Capital}, \texttt{Labor}\)
- \(\texttt{InelasticSubstitutionElasticity}\) is a **proof/Theorem** type over \(\texttt{SubstitutionElasticity}\)

- \(\texttt{ProfitRate} \, \{<,>, =\} \texttt{and} (\texttt{ProfitShare}, \texttt{CapitalPty}\)) is a **proof/theorem** type over the types above: \(\texttt{KaleckyProfitDeterminationLaw}\). Note that we can define:\

\[
	\texttt{KaleckyProfitDeterminationLaw} \mapsto \texttt{Equilibrium} \mid \texttt{Disequilibrium}
\]

- \(\texttt{RealWage} \, \{<,>, =\} \texttt{and} (\texttt{WageShare}, \texttt{LaborProductivity}\)) is a **proof/theorem** type over the types above: \(\texttt{KaleckyRealWageDeterminationLaw}\). Note that we can define:\

\[
	\texttt{KaleckyRealWageDeterminationLaw} \mapsto \texttt{Equilibrium} \mid \texttt{Disequilibrium}
\]



For capitalization we have:

\[
	\begin{aligned}
		\texttt{Capitalization}:: \texttt{Income} \times \texttt{CapitalizationRate} \mapsto  \texttt{CapitalValue} \\
		\texttt{Decapitalization}:: \texttt{CapitalValue} \times \texttt{CapitalizationRate} \mapsto \texttt{Income}
	\end{aligned}
\]



For capital accumulation we have:

\[
	\begin{aligned}
		\texttt{CapitalAccumulation} :: \texttt{Path}(\texttt{CapitalSaving}) \mapsto \texttt{InvestmentDemand} \\
		\quad\text{i.e.}\quad
		\texttt{InvestmentDemand} = \int \texttt{CapitalSaving}\,dt
	\end{aligned}
\]

Distinct from \(\texttt{Capitalization}\) (income \(\mapsto\) present value via a rate): accumulation integrates capital-saving along a path into investment demand.





\(\texttt{Horizon}: \texttt{LongRun} \mid \texttt{ShortRun}\)



- \(\texttt{EconGrowth}\) via \(\texttt{GrowthEffectOfDist}(\texttt{Horizon}, \texttt{IncomeDist})\) with comparative-statics sign \(\texttt{DistGrowthSign}\) is a **proof/theorem** type over the types above: \(\texttt{SarmientoGrowthDeterminationLaw}\). Note that we can define:

\[
	\begin{aligned}
		\texttt{GrowthEffectOfDist} :: \texttt{Horizon} \times \texttt{IncomeDist} \mapsto \texttt{EconGrowth} \\
		\texttt{Sign}: \texttt{Positive} \mid \texttt{Negative} \mid \texttt{Zero} \\
		\texttt{DistGrowthSign} :: \texttt{Horizon} \mapsto \texttt{Sign} \\
		\texttt{SarmientoGrowthDeterminationLaw}:\
			\texttt{DistGrowthSign}(\texttt{LongRun}) = \texttt{Positive},\ 
			\texttt{DistGrowthSign}(\texttt{ShortRun}) = \texttt{Negative}
	\end{aligned}
\]


Inhabitant of \(\texttt{SarmientoGrowthDeterminationLaw}\): \(\texttt{SurplusAbsorption}\).

- \(\texttt{SurplusAbsorption}\): mechanism that shifts surplus from \(\texttt{CapitalSaving}\) into consumption. Example mechanisms: savings\(\to\)consumption transfers, price controls, fiscal deficits.
- Judgment: \(\texttt{SurplusAbsorption} : \texttt{SarmientoGrowthDeterminationLaw}\) (conjunction \(\texttt{ShortRun} \land \texttt{LongRun}\)).

\[
	\begin{aligned}
		\texttt{SurplusAbsorption} : \texttt{SarmientoGrowthDeterminationLaw} \\
		\texttt{SarmientoGrowthDeterminationLaw} \mapsto
			(\texttt{DistGrowthSign}(\texttt{ShortRun}) = \texttt{Negative})
			\land
			(\texttt{DistGrowthSign}(\texttt{LongRun}) = \texttt{Positive})
	\end{aligned}
\]

**ShortRun** (contrapositive). Goal: \(\texttt{DistGrowthSign}(\texttt{ShortRun}) = \texttt{Negative}\). Prove contrapositive \(\downarrow\texttt{IncomeDist} \Rightarrow \uparrow\texttt{EconGrowth}\):

\[
	\begin{aligned}
		\downarrow\texttt{IncomeDist} &\Rightarrow \uparrow\texttt{CapitalSaving} \\
		\uparrow\texttt{CapitalSaving} &\Rightarrow \uparrow\texttt{InvestmentDemand}
			\quad\text{via}\quad \texttt{CapitalAccumulation} \\
		&\Rightarrow \uparrow\texttt{ProfitShare} \\
		\uparrow\texttt{ProfitShare} &\Rightarrow \uparrow\texttt{CapitalSaving} / \uparrow\texttt{InvestmentDemand} \\
		\uparrow\texttt{InvestmentDemand} &\Rightarrow \uparrow\texttt{EconGrowth}
	\end{aligned}
\]

**LongRun.** Premises: \(\texttt{IncomeDist}\) is path-dependent / accumulated; \(\texttt{InclusivePoliticalInstitutions}\) (named premise only). Past ShortRun may lower \(\texttt{IncomeDist}\) (growth via the contrapositive chain). Thin axiom:

\[
	\begin{aligned}
		\texttt{InclusivePoliticalInstitutions}\ \text{(premise)} \\
		\texttt{IncomeDistMeanReversion}:\
			\texttt{Assuming}\ \texttt{InclusivePoliticalInstitutions},\ \text{then}\ 
			\downarrow\texttt{IncomeDist}_{t}
			\Rightarrow
			\uparrow\texttt{IncomeDist}_{t+T}
			\quad (T > 0)
	\end{aligned}
\]

Hole \(\texttt{?longRunPositive}\): derivation from \(\texttt{IncomeDistMeanReversion}\) \(\land\) ShortRun path algebra to \(\texttt{DistGrowthSign}(\texttt{LongRun}) = \texttt{Positive}\) (vs merely re-entering the ShortRun Negative machine). Conjunction closes when this hole is filled.

- \(\texttt{Transmission}(\texttt{IncomeDist}, \texttt{CapitalSaving}) = \texttt{Absent}\) is a **proof/theorem** type **derived from** \(\texttt{SurplusAbsorption} : \texttt{SarmientoGrowthDeterminationLaw}\): \(\texttt{SarmientoCapitalSavingNonTransmissionLaw}\). Sibling of \(\texttt{SarmientoMeanIncomeNonTransmissionLaw}\): long-run **net** independence (ShortRun path may still move \(\texttt{CapitalSaving}\)). Conditional on closing \(\texttt{?longRunPositive}\). Note that we can define:

\[
	\begin{aligned}
		\texttt{SarmientoCapitalSavingNonTransmissionLaw}:\
			\texttt{Transmission}(\texttt{IncomeDist}, \texttt{CapitalSaving}) = \texttt{Absent} \\
		\quad\text{derives from}\ \texttt{SurplusAbsorption} : \texttt{SarmientoGrowthDeterminationLaw}
	\end{aligned}
\]

- \(\texttt{Transmission}(\texttt{MeanIncome}, \texttt{IncomeDist})\) with channel status \(\texttt{Absent}\) is a **proof/theorem** type over the types above: \(\texttt{SarmientoMeanIncomeNonTransmissionLaw}\). Mean income = average per-capita income level; raising it is not an automatic transmission channel into distribution under Sarmiento (rival monometric regression deferred). Note that we can define:

\[
	\begin{aligned}
		\texttt{ChannelStatus}: \texttt{Present} \mid \texttt{Absent} \\
		\texttt{Transmission} :: \texttt{Source} \times \texttt{Target} \mapsto \texttt{ChannelStatus} \\
		\texttt{SarmientoMeanIncomeNonTransmissionLaw}:\
			\texttt{Transmission}(\texttt{MeanIncome}, \texttt{IncomeDist}) = \texttt{Absent}
	\end{aligned}
\]

- \(\texttt{TrendCoMoveSign}(\texttt{Trend}(\texttt{BottomIncome}), \texttt{Trend}(\texttt{MeanIncome})) = \texttt{Positive}\) is a **proof/theorem** type over the types above: \(\texttt{SarmientoTrendCoMoveLaw}\). Complements non-transmission of mean **levels** into \(\texttt{IncomeDist}\): bottom and mean **trends** co-move. Note that we can define:

\[
	\begin{aligned}
		\texttt{Trend} : a \mapsto \texttt{Trend}(a) \\
		\texttt{BottomIncome}  \\
		\texttt{TrendCoMoveSign} :: \texttt{Trend}(\texttt{BottomIncome}) \times \texttt{Trend}(\texttt{MeanIncome}) \mapsto \texttt{Sign} \\
		\texttt{SarmientoTrendCoMoveLaw}:\
			\texttt{TrendCoMoveSign}(\texttt{Trend}(\texttt{BottomIncome}), \texttt{Trend}(\texttt{MeanIncome})) = \texttt{Positive}
	\end{aligned}
\]

- \(\texttt{CapitalPtySubsidyDistEffect}(\texttt{CapitalPty}, \texttt{CapitalSubsidy}) = \texttt{Negative}\) as \(\texttt{Effect}(\texttt{IncomeDist})\) is a **proof/theorem** type over the types above: \(\texttt{SarmientoCapitalDistDeterminationLaw}\). \(K/Y\) may proxy \(\texttt{CapitalPty}\) in measurement; it is not the law’s carrier. Note that we can define:

\[
	\begin{aligned}
		\texttt{Effect} : a \mapsto \texttt{Sign} \\
		\texttt{CapitalPtySubsidyDistEffect} :: \texttt{CapitalPty} \times \texttt{CapitalSubsidy} \mapsto \texttt{Effect}(\texttt{IncomeDist}) \\
		\texttt{SarmientoCapitalDistDeterminationLaw}:\
			\texttt{CapitalPtySubsidyDistEffect}(\texttt{CapitalPty}, \texttt{CapitalSubsidy}) = \texttt{Negative}
	\end{aligned}
\]


