# Constrained Belief Updates Explain Geometric Structures in Transformer Representations

**Authors:** Shai et al.
**Date:** 2025 (arXiv 2502.01954)
**Venue:** ICML 2025

## Claim

Transformers trained on next-token prediction implement constrained Bayesian
belief updating — a parallelized version of partial Bayesian inference shaped
by architectural constraints.

## Method

Focus on Hidden Markov Models (Mess3 class) which admit tractable optimal
predictors. Single-layer transformers analyzed in detail; multi-layer extensions
shown. Mechanistic interpretability used to reverse-engineer the learned algorithm.

Key insight: optimal prediction *requires* Bayesian belief updating (recursive),
but transformer architecture enforces parallelized attention-driven computation.
The transformer resolves this tension by learning geometrically structured
representations that approximate Bayesian inference under the architectural
constraint.

## Relevance to This Repo

This paper shows the *constraint* side of the picture — transformers can't do
full Bayesian inference because of parallelism, so they do a constrained version.

Our repo sidesteps this by using an *agent loop*: the transformer does one round
of BP per forward pass, and the loop provides the recursion. This is exactly the
"Way 2" looping discussed in our architecture notes — the transformer as a
dynamical system converging to a fixed point.

## Key Difference

They study what transformers *learn* to do under next-token prediction training.
We study what a *constructed* transformer with specific weights does.
The two are complementary: their work suggests gradient descent finds something
like our construction; our work gives the construction explicitly.