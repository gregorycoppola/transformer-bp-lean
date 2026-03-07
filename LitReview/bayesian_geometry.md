# The Bayesian Geometry of Transformer Attention

**Authors:** Naman Agarwal, Siddhartha R. Misra (Vishal Misra group)
**Date:** December 2025 (arXiv 2512.22471)
**Venue:** arXiv preprint; part of a claimed trilogy

## Claim

Transformers implement Bayesian inference through a consistent three-component
geometric mechanism:
- Residual stream = belief substrate
- Feed-forward networks = posterior update
- Attention = content-addressable routing

## Method

"Bayesian wind tunnels" — controlled synthetic tasks where the true posterior
is known in closed form and memorization is provably impossible:
1. Bijection elimination
2. Hidden Markov Model state tracking

Small transformers trained on these tasks reproduce Bayesian posteriors with
10^-3 to 10^-4 bit accuracy. Capacity-matched MLPs fail by orders of magnitude.

## Key Finding

The role decomposition (attention=routing, FFN=update, residual=belief) matches
our architectural decomposition in this repo almost exactly:
- Their "attention as routing" = our attention heads locating neighbor tokens
- Their "FFN as posterior update" = our FFN computing updateBelief
- Their "residual as belief state" = our dim 0 carrying the belief scalar

## Critical Difference from This Repo

Their result is **empirical**: they observe the geometry in trained transformers.
They do not:
- Specify which graphical model the transformer is computing over
- Prove from weight matrices that the computation is BP
- Give a formal constructive proof

This repo is **formal and constructive**: we exhibit specific weight matrices
and prove they implement specific BP message updates.

## Notable Quote

"This paper provides the first empirical proof that transformers can realize
exact Bayesian posteriors" — their own framing distinguishes empirical from formal.

## Relevance to This Repo

High. This is the closest prior work. Our contribution is to make their empirical
claim formal, and to specify the graphical model (QBBN) being computed over.

## Also Notable

They find Mamba (a state-space model without attention) performs equally well,
suggesting the key mechanism is content-based value routing, not attention per se.
This is consistent with our proof: we use attention for *routing* (finding the
right neighbor token), not for the inference computation itself.