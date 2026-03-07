# Abstract

We present a formal proof, verified in Lean 4, that a single forward
pass of a transformer with appropriately structured weights implements
one round of belief propagation (BP) on a factor graph. Specifically,
we construct explicit attention weight matrices and FFN weights such
that the transformer's attention heads gather neighbor beliefs into
scratch dimensions, and the FFN combines them via the BP update rule.
The proof is fully mechanized with zero sorries in the Lean source,
modulo a small set of named axioms corresponding to standard results
in linear algebra, concentration of measure, and universal approximation.

Combined with the standard result that BP computes exact marginal
posteriors on tree-structured graphs, this gives a formal account of
why transformer agents operating over structured knowledge bases can
perform exact Bayesian inference — and do not hallucinate in the
technical sense that their beliefs are determined by message passing
from evidence, not by pattern completion.

This repo is the third in a trilogy formalizing the Quantified Boolean
Bayesian Network (QBBN) system introduced in Coppola (2024).