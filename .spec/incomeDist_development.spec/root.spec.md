
\[
	\begin{aligned}
		\psi (Y):\texttt{IncomeDist} \\
		 \mathcal{D}:\texttt{EconDevelopment} \\
		G(Y) :\texttt{EconGrowth}
	\end{aligned}
\]

> \(\mathcal{D}\) is a placeholder for better notation for the type of econ development
> QUESTION: Is \(\mathcal{D} =\mathcal{D} (Y)\), or \(\mathcal{D} =\mathcal{D} (\text{?})\)?

- \(\texttt{IncomeDist}\): is a path-dependent type 
- \(\texttt{Development}\): is a product type of \(\texttt{MarginalDecreasingCapitalProdty}\) **and** \(\texttt{TechDiffusion}\)

> TODO: We need to further find the type structure of those two types to build development furrther
- \(\texttt{MarginalDecreasingCapitalProdty}\) is a **proof/Theorem** type over \(\texttt{Path} (\texttt{CapitalPty})\)

- \(\texttt{InelasticSubstitutionElasticity}\) is a **proof/Theorem** type over \(\texttt{SubstitutionElasticity}\)


For capitalization we have:

\[
	\begin{aligned}
		\texttt{Capitalization}:: \texttt{Income} \times \texttt{CapitalizationRate} \mapsto  \texttt{CapitalValue} \\
		\texttt{Decapitalization}:: \texttt{CapitalValue} \times \texttt{CapitalizationRate} \mapsto \texttt{Income}
	\end{aligned}
\]



For capital accumulation we have:
> This is a short run to logn run mappign as some sequence of capital saving that lead to investment demand, the ouytput space is not investmetn demand
\[
	\begin{aligned}
		\texttt{CapitalAccumulation} :: \texttt{Path}(\texttt{CapitalSaving}) \mapsto \texttt{InvestmentDemand} \\
		\quad\text{i.e.}\quad
		\texttt{InvestmentDemand} = \int \texttt{CapitalSaving}\,dt
	\end{aligned}
\]

Distinct from \(\texttt{Capitalization}\) (income \(\mapsto\) present value via a rate): accumulation integrates capital-saving along a path into investment demand.



Inhabitant of \(\texttt{SarmientoGrowthDeterminationLaw}\): \(\texttt{SurplusAbsorption}\).
> SurplusAbsortoin is the sarmiento mechanism to connect income distribution and economic growth to grow on the same directrion. The process is shwoign and invesrse relation int the short run  and FIND  the long run direct relationship naming it absortion
> From now we have stated that the mechanism is political via democracis alowwing left wing parties but we want more mechanical non political mechanims


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
		\uparrow\texttt{InvestmentDemand} &\Rightarrow \uparrow\texttt{EconGrowth}
	\end{aligned}
\]
> It is the surplus absortion mechamis what allows to define a mean reversion pattern on income distributiuon 
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

- \(\texttt{TrendCoMoveSign}(\texttt{Trend}(\texttt{BottomIncome}), \texttt{Trend}(\texttt{MeanIncome})) = \texttt{Positive}\) is a **proof/theorem** type over the types above: \\(\texttt{SarmientoTrendCoMoveLaw}\). Complements non-transmission of mean **levels** into \(\texttt{IncomeDist}\): bottom and mean **trends** co-move. Note that we can define:

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


