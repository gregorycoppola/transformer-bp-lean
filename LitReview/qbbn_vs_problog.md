# QBBN vs. Probabilistic Logic: ProbLog, MLNs, and Related Systems

## Overview

The QBBN sits in a space of systems that combine logical reasoning with
probabilistic inference. The key competitors are:

- **Markov Logic Networks** (Richardson & Domingos 2006)
- **ProbLog** (De Raedt et al. 2007)
- **Independent Choice Logic** (Poole 1997)
- **BLOG** (Milch et al. 2005)
- **Distributional Clauses** (Gutmann et al. 2011)

Understanding the differences clarifies why QBBN is the right graphical
model for a transformer to implement — and why the others are not.

## The Core Distinction: Inference Complexity

Every system in this space makes a tradeoff between:
1. Expressiveness of the logical language
2. Tractability of probabilistic inference

The QBBN makes a specific, principled choice on this tradeoff that the
others do not.

---

## Markov Logic Networks (Richardson & Domingos 2006)

### What It Is

A Markov Logic Network (MLN) is a set of first-order logic formulas,
each with a real-valued weight. The weight encodes how strongly the
formula is believed. The joint distribution over all ground atoms is:

    P(x) ∝ exp( sum_i w_i * n_i(x) )

where n_i(x) is the number of groundings of formula i satisfied by x.

### Inference

Exact inference in MLNs is #P-hard. In practice: Markov Chain Monte Carlo
(MCMC) sampling, which is slow and has no convergence guarantee in practice.
Also: MaxWalkSAT for MAP inference.

### The Key Difference from QBBN

MLNs use **MCMC for inference**. The QBBN uses **belief propagation**.

This is the central distinction. MCMC is:
- Asymptotically correct but slow to converge
- Non-deterministic (random samples)
- Hard to parallelize
- Not implementable as a fixed transformer forward pass

BP is:
- Deterministic message passing
- Parallelizable (all messages can be computed simultaneously)
- One round = one transformer forward pass (this repo)
- Convergent on trees, empirically convergent on loopy graphs (ECT)

**Why this matters for the transformer connection:** A transformer forward
pass is a deterministic, parallel computation. It can implement BP exactly.
It cannot implement MCMC — MCMC requires randomness and sequential sampling
that doesn't fit the transformer architecture.

The QBBN's choice of BP over MCMC is not just a speed optimization. It is
what makes the transformer connection possible.

### Expressiveness

MLNs are more expressive than QBBN in the logical language — full first-order
logic with arbitrary formulas and weights. QBBN restricts to AND/OR boolean
gates with specific factor types.

This restriction is deliberate. The QBBN paper argues that AND/OR boolean
gates are sufficient for logical completeness (the completeness proof in
Coppola 2024a) while keeping inference tractable. Full first-order MLN
expressiveness buys nothing if inference is intractable.

---

## ProbLog (De Raedt et al. 2007)

### What It Is

ProbLog extends Prolog with probabilistic facts. Each fact f has a
probability p(f) of being true. A query succeeds with the probability
of the most probable proof.

    0.3 :: lonely(jack).
    0.6 :: exciting(jill).
    date(X,Y) :- likes(X,Y), likes(Y,X).

The probability of a query is computed by summing over all proofs,
weighted by the probability that their assumptions hold.

### Inference

Exact inference via knowledge compilation (BDD/SDD — binary/sentential
decision diagrams). This converts the logical structure to a canonical
form over which probabilities can be computed exactly.

Cost: knowledge compilation is exponential in the worst case (treewidth
of the dependency graph). In practice: tractable for sparse, structured
programs; intractable for dense, loopy ones.

### The Key Difference from QBBN

ProbLog uses **proof-based inference** (sum over proofs). QBBN uses
**message-passing inference** (BP on a factor graph).

These are fundamentally different computational paradigms:

**Proof-based (ProbLog):**
- Enumerate proofs of the query
- Weight each proof by its probability
- Sum weights
- Sequential, depth-first, requires explicit proof trees

**Message-passing (QBBN/BP):**
- Pass messages along factor graph edges
- Update beliefs iteratively
- Parallel, local, no explicit proof enumeration

The transformer implements message passing naturally — each token sends
a message (attended value) to each other token (via attention). There is
no natural transformer implementation of proof enumeration, which requires
sequential search over a potentially exponential proof space.

### The Prolog Connection

Prolog itself (the deterministic ancestor of ProbLog) uses SLD resolution —
a depth-first, left-to-right proof search strategy. This is inherently
sequential and cannot be parallelized in the way a transformer forward pass
is parallelized.

The QBBN deliberately moves away from the Prolog proof-search paradigm
toward the graphical model message-passing paradigm. This is the key
architectural choice that makes the transformer connection possible.

**Slogan:** Prolog thinks sequentially. Transformers think in parallel.
QBBN is the logical system that thinks in parallel.

### Expressiveness

ProbLog is more expressive in one sense: it supports arbitrary Prolog
programs, including recursion and unbounded proof depth. QBBN restricts
to bounded factor graphs.

But this expressiveness comes at inference cost. The QBBN paper's position:
for the kinds of reasoning needed in information retrieval (the target
application), bounded factor graphs with BP are sufficient and tractable.
Unbounded Prolog-style recursion is not needed for answering probabilistic
queries about propositions.

---

## Independent Choice Logic (Poole 1997)

### What It Is

ICL combines a logic program with a set of mutually exclusive,
probabilistically weighted "choices." Each choice selects one of several
alternatives, and the logic program derives conclusions from the selected
choices.

### Inference

Exact inference by enumerating choice combinations and computing
probabilities. Equivalent to ProbLog in expressiveness for many tasks.

### Difference from QBBN

Same core issue as ProbLog: inference is proof-enumeration based, not
message-passing based. ICL makes the "choices" explicit (as independent
probabilistic facts) which is clean but doesn't change the inference paradigm.

The QBBN's AND/OR boolean gates can be seen as a restricted form of ICL
where the choices are binary (true/false) and the logic is restricted to
boolean combinations. The restriction buys tractable BP inference.

---

## BLOG (Milch et al. 2005) — Bayesian Logic

### What It Is

BLOG (Bayesian LOGic) handles open-universe probabilistic inference —
reasoning about an unknown number of objects. You can write programs like:

    #Aircraft ~ Poisson(5).
    observed_blip(r) ~ exists a: Aircraft. position(a) = r.

### Inference

MCMC over the space of possible world structures (number of objects,
their properties, their relationships).

### Difference from QBBN

BLOG targets the open-universe setting — reasoning about how many objects
exist. QBBN targets the closed-universe setting — reasoning about
propositions over known entities.

For information retrieval (the QBBN's target application), the universe
of entities is effectively closed at query time (you know what entities
are in your database). BLOG's generality is not needed and its MCMC
inference is too slow.

---

## Distributional Clauses (Gutmann et al. 2011)

### What It Is

Extends ProbLog with continuous distributions — facts can have real-valued
probabilities drawn from distributions (Gaussian, Beta, etc.) rather than
fixed scalar probabilities.

### Difference from QBBN

The QBBN's beliefs are real-valued probabilities in [0,1], which is
similar in spirit. But the inference mechanism is still BP, not
proof-enumeration. Distributional Clauses inherit ProbLog's proof-based
inference with MCMC for the continuous case.

---

## The Systematic Comparison

| System | Logic | Inference | Parallelizable | Transformer-Implementable |
|--------|-------|-----------|---------------|--------------------------|
| MLN | First-order + weights | MCMC | No | No |
| ProbLog | Prolog + probabilistic facts | Knowledge compilation | No | No |
| ICL | Logic program + choices | Proof enumeration | No | No |
| BLOG | Open-universe logic | MCMC | No | No |
| **QBBN** | **AND/OR boolean gates** | **Belief propagation** | **Yes** | **Yes** |

The QBBN is the only system in this space where the inference algorithm
is naturally parallelizable and naturally implementable as a transformer
forward pass. This is not a coincidence — the QBBN was designed with
these properties in mind (Coppola 2024).

---

## The Deeper Difference: What "Inference" Means

In Prolog-descended systems (ProbLog, ICL, MLN), inference means:

> Find proofs. Weight them. Sum the weights.

This is **combinatorial** — the difficulty is in the search over proof space.

In graphical model systems (QBBN, standard Bayesian networks), inference means:

> Pass messages. Update beliefs. Iterate to convergence.

This is **algebraic** — the difficulty is in the message update equations
and the convergence of iteration.

The transformer is fundamentally an algebraic machine. It does matrix
multiplications, applies nonlinearities, sums weighted values. It is not
a search machine — it cannot efficiently enumerate proofs or explore
branching search trees.

This is why the QBBN is the right logical system for a transformer to
implement. Not because it is more expressive, or more elegant, or more
general — but because its inference algorithm matches the transformer's
computational paradigm.

**The characteristica universalis framing:** Leibniz dreamed of a calculus
of thought where reasoning could be done by calculation rather than
argumentation. Prolog-descended systems are argumentation-based (find
a proof). The QBBN is calculation-based (compute a fixed point). The
transformer implements the calculation. This is the sense in which the
QBBN + transformer realizes Leibniz's dream in a way that ProbLog cannot.

---

## What QBBN Gives Up

Honesty requires noting what QBBN sacrifices for tractability:

**Recursion:** ProbLog supports recursive programs (e.g. transitive closure,
path queries). QBBN requires the factor graph to be constructed at query
time — unbounded recursion is not directly supported.

**Open universe:** BLOG handles unknown numbers of objects. QBBN assumes
a closed set of propositions at query time.

**Arbitrary formula weights:** MLNs can weight any first-order formula.
QBBN restricts to AND/OR boolean combinations with specific factor types.

These are real limitations. The QBBN paper's position is that for the
target application (information retrieval over natural language knowledge
bases), these limitations don't matter in practice — the queries are
bounded, the universe is closed at query time, and AND/OR boolean logic
is sufficient for completeness.

Whether this position is correct is an empirical question about the
structure of natural language knowledge. It is not settled by the
formal proof in this repo.