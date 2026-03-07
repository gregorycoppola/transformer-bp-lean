# Thread 5: Transformers Implementing Specific Algorithms

## Overview

A growing body of theoretical work asks: can we identify which specific
algorithm a transformer implements in its forward pass? This is the
mechanistic interpretability question approached mathematically rather
than empirically.

The general pattern: construct explicit weight matrices that implement
a known algorithm, verify (usually informally) that the construction works,
use this to argue that trained transformers might be learning the same algorithm.

This repo is the only work in this thread that formally verifies the
construction in a proof assistant.

## Key Papers

### Akyürek et al. (2022) — "What Learning Algorithm Is In-Context Learning?"

Already covered in Thread 3 from the ICL angle. From the algorithm
implementation angle: they give explicit weight matrices for one step
of gradient descent on a linear model. The construction is:

    Q = [I, 0; 0, 0],  K = [I, 0; 0, 0],  V = [0, 0; I, 0]

with appropriate scaling. This implements the gradient descent update
in a single attention layer.

**Relevance:** Direct methodological precedent. Same approach as this repo —
exhibit weights, claim they implement algorithm X. Difference: no Lean proof,
and gradient descent on linear models is much simpler than BP on factor graphs.

### Bai et al. (2023) — "Transformers as Statisticians: Provable In-Context Learning with In-Context Algorithm Selection"

**Claim:** Transformers can implement a broad class of standard statistical
learning algorithms in-context, including lasso, ridge regression, and
nearest neighbors. Gives construction-based proofs (explicit weights) for
each algorithm.

**Relevance:** Extends the Akyürek et al. result to a wider class of algorithms.
Shows the construction technique generalizes. Still no theorem prover verification.

The algorithms they cover (regression, classification) are all linear or
kernel methods. BP on a graphical model is a different class — iterative,
nonlinear, graph-structured. Our construction is not covered by their framework.

### Giannou et al. (2023) — "Looped Transformers as Programmable Computers"

Already covered in the index as background for universal-lean. From the
algorithm implementation angle: they construct weights that implement one
step of a SUBLEQ register machine. The looped transformer can then execute
any program.

**Relevance:** This is the most general "transformer implements algorithm X"
result — since SUBLEQ is Turing complete, any algorithm can in principle
be implemented. But the construction is via instruction-set emulation, which
is indirect and non-natural.

Our construction is direct: the transformer weights directly implement BP
message passing, not a general computer that could be programmed to do BP.
Direct construction is more transparent and more formally tractable.

### Feng et al. (2023) — "Towards Revealing the Mystery of Chain of Thought"

**Claim:** Chain-of-thought prompting allows transformers to implement
dynamic programming algorithms that a single forward pass cannot.
Constructs explicit weight matrices for several DP algorithms.

**Relevance:** Chain-of-thought is the discrete analog of our agent loop.
Where we iterate transformer passes (each pass = one BP round), CoT
iterates reasoning steps (each step = one DP transition). The formal
structure is the same: fixed-depth transformer + iteration = unbounded computation.

### Weiss et al. (2021) — "Thinking Like Transformers"

**Claim:** Introduces RASP, a programming language that captures what
transformers can compute. Any RASP program can be compiled to transformer
weights.

**Relevance:** Provides a high-level language for describing transformer
computations. Our BP implementation could in principle be expressed in RASP.
The compilation from RASP to weights is the constructive step we do manually
in Attention.lean.

## The Pattern Across This Thread

Every paper in this thread:
1. Identifies an algorithm A
2. Constructs weight matrices W
3. Claims (informally) that W implements A
4. Uses this to argue something about trained transformers

Step 3 is always informal — pen-and-paper argument at best.

This repo is the first to make step 3 formal: we prove in Lean 4 that
W implements A. The algorithm (BP) and the graphical model (QBBN) are
more complex than anything in this thread, which makes the formal proof
both harder and more valuable.

## The Missing Piece Across All of Thread 5

Every construction in this thread answers: "can a transformer implement X?"
None answers: "is this what trained transformers actually compute?"

The bridge between constructed weights and learned weights is the open
problem. Thread 3 (ICL as Bayes) suggests gradient descent finds something
like our construction. Thread 5 constructs the target but doesn't show
gradient descent reaches it.

Closing this gap — showing that gradient descent on QBBN inference tasks
converges to weights that implement BP — would complete the picture.
It is the natural next paper after this repo.