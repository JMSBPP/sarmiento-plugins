


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
		\texttt{BottomIncome}\ \text{(poorest incomes)} \\
		\texttt{TrendCoMoveSign} :: \texttt{Trend}(\texttt{BottomIncome}) \times \texttt{Trend}(\texttt{MeanIncome}) \mapsto \texttt{Sign} \\
		\texttt{SarmientoTrendCoMoveLaw}:\
			\texttt{TrendCoMoveSign}(\texttt{Trend}(\texttt{BottomIncome}), \texttt{Trend}(\texttt{MeanIncome})) = \texttt{Positive}
	\end{aligned}
\]


