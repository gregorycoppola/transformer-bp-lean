# Hallucination: A Precise Technical Account

## The Problem with "Hallucination"

The word "hallucination" in AI discourse is used loosely to mean
anything from factual errors to confident confabulation to outputs
that are plausible but unsupported. This vagueness makes it hard to
reason about causes, cures, or formal guarantees.

The trilogy provides a precise technical definition and a formal
result about it. This document states both carefully.

## Definition

Within the QBBN framework:

> **Hallucination** occurs when an agent asserts a belief that is
> not the correct Bayesian posterior given its knowledge base and
> observed evidence.

Formally: let K be a QBBN knowledge base (a factor graph), let E
be observed evidence (a set of clamped node beliefs), and let P_true(j)
be the true marginal posterior of node j given K and E. An agent
hallucinates at node j if it outputs a belief b(j) ≠ P_true(j).

This definition is specific. It does not apply to:
- Errors in the knowledge base itself (wrong facts in K)
- Errors in evidence encoding (misidentified E)
- Nodes outside the knowledge base (unanswerable questions)

It applies precisely to: given a correct knowledge base and correctly
encoded evidence, does the agent compute the right answer?

## The Formal Result

**R5** (`transformer_computes_posterior`) states:

> Conditioned on ECT and PCT, a transformer with BP weights computes
> true posterior beliefs at every node after T steps.

This means: the transformer does not hallucinate, under the QBBN
definition, conditioned on ECT and PCT.

**R6** (tree case) states the same without ECT or PCT:

> On a tree-structured knowledge base, the transformer computes
> exact posteriors unconditionally.

This is the strong no-hallucination guarantee. On trees, it is
a theorem, not a conditional claim.

## What Causes Hallucination in This Framework

The constructive proof of R1 makes the cause of hallucination precise.
There are exactly three ways the transformer can fail to compute
the correct posterior:

**1. Wrong weights (FET failure)**
If the FFN does not implement updateBelief — if it computes the
wrong function of dims 4 and 5 — the belief update is wrong.
This is the weight learning problem. A transformer trained on text
has no reason to learn BP weights unless its training signal aligns
with Bayesian inference.

**2. Wrong attention routing (attention failure)**
If the attention heads do not attend to the correct neighbors —
if the score gap is insufficient and the softmax does not concentrate
on the right token — the gathered beliefs are wrong. This happens
when neighbor indices are not distinguishable, or when temperature
is too low.

**3. Non-convergence or wrong fixed point (ECT/PCT failure)**
Even with correct weights, on loopy graphs BP may not converge
(ECT failure) or may converge to the wrong fixed point (PCT failure).
This is a property of the graph structure, not the transformer.

Current LLMs hallucinate primarily for reason 1: they are not trained
to implement BP and their weights do not correspond to any known
inference algorithm. Reasons 2 and 3 are secondary — they apply to
a transformer that is *trying* to do BP but failing.

## The Scope of the Guarantee

The no-hallucination guarantee is scoped to:

1. **Structured knowledge** — facts expressible as QBBN factor graphs
2. **Binary propositions** — the current QBBN handles boolean variables
3. **Finite knowledge bases** — the factor graph has n nodes
4. **K=2 neighbors** — current construction; extends to K neighbors
   with K attention heads
5. **Tree structure** — for the unconditional guarantee (R6)

Outside this scope — open-domain text, continuous variables, unbounded
knowledge, arbitrary graph topology — the guarantee does not apply.

This is not a weakness of the result. It is a precise statement of
what "does not hallucinate" means and under what conditions it holds.

## Connection to RLHF and Alignment

The hallucination result has implications for alignment beyond
factual accuracy.

A transformer implementing BP does not assert beliefs it cannot
derive from evidence. It has no incentive to confabulate because
its output is determined by message passing, not by pattern matching
on training data. The "sycophancy" failure mode — telling users what
they want to hear rather than what is true — is structurally impossible
if the transformer is computing posteriors: posteriors are determined
by the knowledge base and evidence, not by user preferences.

This suggests a path to alignment via architecture rather than
training signal: a transformer that is constrained to implement BP
cannot hallucinate or sycophantically confabulate by construction.
The constraint is enforced by the weights, not by RLHF.

Whether this path is practical — whether real-world knowledge can
be encoded in QBBN factor graphs, whether the weights can be learned
rather than hand-constructed — is an open empirical question. The
formal result establishes that the path exists.

## Summary

| Claim | Status | Scope |
|-------|--------|-------|
| Transformer with BP weights does not hallucinate | Theorem (R6) | Tree-structured QBBN, exact |
| Transformer with BP weights does not hallucinate | Conditional theorem (R5) | Loopy QBBN, given ECT + PCT |
| Current LLMs do not hallucinate | False | General |
| QBBN agent does not hallucinate | Empirical claim (Coppola 2024) | QBBN knowledge bases |
| Hallucination is eliminable by architecture | Open question | General |