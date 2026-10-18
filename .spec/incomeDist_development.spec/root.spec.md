


\[
	\begin{aligned}
		\texttt{IncomeDist} \\
		\texttt{Development}
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

