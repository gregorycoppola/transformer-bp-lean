# Interpretability: What the Weight Construction Tells Us

## The Mechanistic Account

The proof of R1 (`transformer_implements_bp`) is constructive. It does
not merely show that BP-implementing weights *exist* — it writes them
down. This makes the proof an interpretability claim: it gives a
complete mechanistic account of what each component does.

### Head 0
- **Query matrix:** `projectDim ⟨1⟩` — extracts dim 1 (neighbor 0's index)
- **Key matrix:** `projectDim ⟨1⟩` — extracts dim 1 (each token's own index)
- **Value matrix:** `crossProject ⟨0⟩ ⟨4⟩` — reads belief (dim 0), writes to scratch slot 0 (dim 4)
- **Function:** attends to the token whose index matches neighbor 0's index, copies its belief to dim 4

### Head 1
- Symmetric. Attends to neighbor 1, copies belief to dim 5.

### FFN
- Reads dims 4 and 5 (the two gathered neighbor beliefs)
- Computes `updateBelief(dim4, dim5) = σ(logit(dim4) + logit(dim5))`
- Writes result to dim 0 (the belief slot)
- Function: one step of belief propagation

### Residual stream
- Dim 0: belief — updated by FFN
- Dims 1, 2: neighbor indices — read by attention, never written
- Dim 3: node type — read by bp_computeBeliefs split, never written
- Dims 4, 5: scratch — written by attention heads, read by FFN, reset each pass

This is a complete circuit. Every dimension has a named role. No
dimension is superfluous. The model width is exactly 8 — the minimum
needed to store belief, two neighbor indices, node type, and two
scratch slots.

## Connection to Empirical Interpretability

Mechanistic interpretability (Elhage et al. 2021, Olah et al.) studies
trained transformers and attempts to reverse-engineer what circuits
they have learned. Several findings are relevant here.

**Induction heads.** Trained transformers develop attention heads that
attend to specific token types based on content matching. The BP
construction is a special case: heads that attend to tokens whose
index matches a stored value. The Q/K dot product implements exact
index matching rather than approximate content matching, but the
circuit structure is the same.

**Value composition.** In the BP construction, the value matrix is a
cross-projection that routes one dimension to another. This is a
rank-1 value matrix. Trained transformers are found to have low-rank
value matrices for specific functional circuits (copy heads, etc.).
The BP construction is an extreme case: rank-1 value matrices by design.

**Superposition.** The BP construction uses dedicated dimensions for
each role. Trained transformers are found to use superposition —
multiple features sharing the same dimensions. The BP construction
is the anti-superposition case: each dimension has exactly one role.
This is possible because D_model=8 is sufficient; larger models
would not need to superpose.

**FFN as memory.** Recent work (Geva et al. 2021) interprets FFN
layers as key-value memories. The BP FFN is not a memory — it is
a fixed nonlinear function (sigmoid of log-odds sum). But the
structure is similar: the FFN reads from specific input positions
(dims 4 and 5) and writes to a specific output position (dim 0).

## What the Construction Does Not Tell Us

The BP weight construction is a *proof of existence*: these weights
work. It is not a *characterization of uniqueness*: many other weight
configurations might also implement BP, and trained transformers that
perform reasoning might use completely different circuits.

The construction also assumes a specific input format (the encoding
into 8 dimensions). Real transformers operate on token embeddings
from a vocabulary, not on explicitly encoded factor graph states.
The gap between the two is the gap between the formal result and
empirical practice.

## The Interpretability Research Question

The construction raises a precise empirical question:

> Do transformers trained on reasoning tasks develop circuits that
> approximate the BP weight construction?

Concretely: in a transformer trained on a task that requires
combining evidence from two context tokens to update a belief,
do the attention heads specialize to attend to each source token
separately, and does the FFN implement something like a log-odds
combination?

This is testable with existing interpretability tools. It would
connect the formal result to the empirical literature and potentially
explain *why* transformers are good at reasoning tasks from first
principles rather than from analogy.

## The Minimal BP Transformer

The construction also gives us the minimal transformer that implements
BP:

- **Layers:** 1 (one attention + FFN block per BP round)
- **Heads:** 2 (one per neighbor, for K=2)
- **D_model:** 8 (belief + 2 indices + node type + 2 scratch + 2 reserved)
- **FFN width:** sufficient to compute sigmoid of log-odds sum

For K neighbors you need K heads and D_model = 4 + K (belief, K
indices, node type, K scratch slots). The model scales linearly in
the number of neighbors. This is a concrete prediction about the
minimum model size needed for exact BP inference on factor graphs
of arity K.