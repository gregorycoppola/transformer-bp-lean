# Thread 1: Belief Propagation Unrolled into Neural Networks

## Overview

A substantial body of work "unfolds" iterative BP into feedforward neural
networks — one layer per BP iteration, with learned weights replacing fixed
message update rules. This goes in the direction:

    BP algorithm → neural network architecture

This repo goes the **converse direction**:

    transformer architecture → BP algorithm

Documenting this thread establishes that our direction is novel.

## Key Papers

### Hershey, Roux & Weiss (2007) — "Approximating the Bethe Partition Function"

Early work showing that BP message updates can be written as matrix operations,
and that learning the weights of those operations gives a trainable approximation
to loopy BP. The key insight: BP is already "almost" a neural network — it just
has fixed, hand-designed weights.

Relevance: establishes the BP-as-matrix-ops framing that makes our attention
construction natural. Their "learned BP weights" are our explicit Wq, Wk, Wv.

### Gregor & LeCun (2010) — "Learning Fast Approximations of Sparse Coding"
(LISTA — Learned ISTA)

Unrolled ISTA (iterative shrinkage-thresholding) into a feedforward network.
Not BP specifically, but established "algorithm unrolling" as a general technique.
Each layer = one iteration of the algorithm.

Relevance: our proof is the formal version of algorithm unrolling — we don't
just observe that a network approximates BP, we prove it implements BP exactly.

### Hershey et al. (2014) — "Deep Unfolding: Model-Based Inspiration for Algorithm Unfolding"

Systematic treatment of unrolling iterative inference algorithms (including BP)
into deep networks. Each unrolled layer has the same structure as one algorithm
iteration but with learned parameters.

Relevance: "deep unfolding" is the closest prior framework to what we do.
The difference: unfolding learns weights that approximate the algorithm.
We construct weights that provably implement the algorithm exactly.

### Belanger & McCallum (2016) — "Structured Prediction Energy Networks"

Energy-based models where inference is gradient descent on a learned energy.
BP as a special case. The inference network learns to approximate the MAP
solution of the energy function.

## The Converse Direction

All unfolding work goes: take a known algorithm, parameterize it, learn the
parameters. The result approximates the algorithm.

This repo goes the other way: take a transformer (known architecture, specific
weights), and prove it implements a specific algorithm exactly.

This is a strictly stronger statement. Unfolding shows "a network shaped like
BP approximates BP." We show "this transformer IS BP."

## Why the Converse Is Harder

Unfolding is constructive in the easy direction: you start with the algorithm
and build the network to match it. The hard direction (our direction) requires:

1. Starting with the transformer architecture as given
2. Finding weight matrices that make it implement BP
3. Formally proving the correspondence

Step 3 is what no prior work attempts.