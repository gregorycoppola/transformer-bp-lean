# Thread 4: Formal Verification of Neural Networks

## Overview

A substantial literature on formally verifying properties of neural networks
exists, primarily focused on **safety and robustness**: proving that a network's
output stays within bounds given bounded inputs, or that small input perturbations
don't change the output class.

Nobody in this literature proves that a network **computes a specific function**.
That is what this repo does, and it places this repo in nearly empty territory.

## Key Papers

### Katz et al. (2017) — "Reluplex: An Efficient SMT Solver for Verification of Deep Neural Networks"

**What it proves:** Safety properties of the form "for all inputs x in region R,
output f(x) satisfies property P." Applied to airborne collision avoidance
neural networks (ACAS Xu).

**Method:** Extends the simplex algorithm to handle ReLU activations.
Reduces neural network verification to an SMT (satisfiability modulo theories)
problem.

**What it does NOT prove:** That the network computes any particular function.
It verifies input-output relationships over regions, not functional identity.

**Relevance to this repo:** Establishes that formal verification of neural
networks is possible and taken seriously. But the *kind* of property verified
is completely different — safety bounds vs. functional correctness.

### Ehlers (2017) — "Formal Verification of Piece-Wise Linear Feed-Forward Neural Networks"

**What it proves:** Properties expressible in linear arithmetic over the
input-output behavior of ReLU networks. Introduces the "Planet" verifier.

**Method:** Encodes the network as a mixed-integer linear program.

**Relevance:** Shows that ReLU networks (like the FFN in our transformer)
are amenable to formal reasoning because they are piecewise linear.
This is directly relevant to the FFN sorry (294) — the difficulty of proving
the FFN computes updateBelief exactly is precisely because updateBelief is
NOT piecewise linear, so the standard verification tools don't apply.

### Anderson et al. (2020) — "Strong Mixed-Integer Programming Formulations for Trained Neural Networks"

**What it proves:** Tighter bounds on neural network outputs than prior MIP
formulations, enabling verification of larger networks.

**Relevance:** Same category as Reluplex — robustness/safety, not functional
correctness. Notable because it handles the same ReLU architecture we use.

### Singh et al. (2019) — "Abstract Interpretation of Deep Neural Networks"

**What it proves:** Certified robustness — that networks are robust to
perturbations within a certified region. Uses abstract interpretation, a
technique from program verification.

**Relevance:** Abstract interpretation is also used in proof assistants like
Lean (in a different sense). The transfer of program verification techniques
to neural network verification is the methodological connection to our work.

### Seshia et al. (2018) — "Formal Specification for Deep Neural Networks"

**What it asks:** What properties of neural networks *should* we formally verify?
Surveys the specification problem — it's hard to say formally what we want
a neural network to do.

**Relevance:** This is exactly the problem our repo solves for the BP case.
We have a clean formal specification: "the transformer forward pass equals
bp_forwardPass." The QBBN provides the specification language.

## The Gap This Repo Fills

The formal verification literature splits into:

**Input-output verification** (Reluplex, Planet, MIP methods):
- "For inputs in region R, output satisfies bound B"
- Does not say what function the network computes
- Tools: SMT solvers, MIP, abstract interpretation

**Architectural analysis** (this repo):
- "These specific weights compute this specific function"
- Functional identity, not just bounded behavior
- Tools: Lean 4 proof assistant

No paper in the formal verification literature proves functional identity —
that a neural network with specific weights computes a specific named function.
This is a new category of result.

## Why Functional Correctness Is Harder

Safety verification asks: does the output stay in a safe region?
This is a reachability question — you can overapproximate and still be useful.

Functional correctness asks: does the output equal exactly this value?
This requires exact equality, not just bounds. Overapproximation is useless.

For ReLU networks this is tractable (piecewise linear = exact case analysis).
For networks computing smooth nonlinear functions (like updateBelief), exact
functional correctness requires either:
- Approximation (losing exactness)
- A different architecture (not standard ReLU)
- Axiomatization (our approach for the FFN sorry)

This is why the FFN sorry (294) is genuinely hard and not just bookkeeping —
it sits at the boundary of what formal verification can currently prove.

## This Repo's Position

This repo is doing something the entire formal verification literature does not:

> Proving in a theorem prover that a neural network with specific weights
> computes a specific named algorithm (belief propagation).

The closest prior work is Akyürek et al. (2022) who construct weights for
gradient descent but do not verify them in a proof assistant. We verify in
Lean 4.

This places `transformer-bp-lean` at the intersection of:
- Mechanistic interpretability (what does this network compute?)
- Formal verification (can we prove it?)
- Probabilistic graphical models (the target algorithm is BP)

No prior work sits at this intersection.