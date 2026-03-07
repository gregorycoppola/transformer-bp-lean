# Preliminaries.lean — Overview

This file defines all types, the transformer forward pass, the BP
forward pass, and proves the main theorems connecting them.

## Part 1: Factor Graph Types

### `K`
Number of neighbors per node. Fixed at 2. Determines the arity of
the BP update and the number of attention heads needed.

### `NodeType`
Inductive type: `variable` or `factor`. Variable nodes hold beliefs
and run the BP update. Factor nodes are identity — they pass messages
unchanged. The transformer handles both via a split in `bp_computeBeliefs`.

### `BPToken n`
A single node in the factor graph with fields:
- `nodeType`: variable or factor
- `belief`: current marginal probability estimate ∈ [0,1]
- `neighbors`: the K=2 neighbor indices (as `Fin n`)
- `scratch`: temporary storage for gathered neighbor beliefs
- `factorTable`: the factor's potential function (2^K entries)

### `BPState n`
A factor graph state: `Fin n → BPToken n`. Assigns a token to each
of the n nodes.

## Part 2: Transformer Types

### `D_model`
Embedding dimension, fixed at 8. Layout:

| Dim | Content |
|-----|---------|
| 0 | belief |
| 1 | neighbor 0's token index |
| 2 | neighbor 1's token index |
| 3 | node type (0=variable, 1=factor) |
| 4 | scratch slot 0 (written by head 0) |
| 5 | scratch slot 1 (written by head 1) |
| 6, 7 | reserved |

### `TFToken`
A single transformer token: one embedding vector of dimension D_model.

### `TFState n`
A transformer state: `Fin n → TFToken`.

## Part 3: Attention Mechanism

### `attentionScore query key`
Dot product of query and key vectors. Used to measure similarity
between a query token and each key token.

### `softmax n scores λ_ j`
Temperature-scaled softmax over n scores. Higher λ_ concentrates
weight on the maximum score (hardmax limit as λ_ → ∞).

### `attendedValue n queries keys values λ_ j`
The standard attention output: weighted sum of value vectors,
weighted by softmax of query-key dot products. Returns a D_model
vector for token j.

### `attentionHead n state Wq Wk Wv λ_`
One attention head with residual connection. Projects embeddings
through Wq/Wk/Wv, computes attended values, adds to original
embedding via residual. Returns a new TFState.

### `twoHeadAttention n state Wq0 Wk0 Wv0 Wq1 Wk1 Wv1 λ_`
Sequential application of two attention heads at the same
temperature. Head 0 runs first, head 1 runs on head 0's output.

## Part 4: Feed-Forward Network

### `relu x`
ReLU activation: `max 0 x`.

### `ffn W1 b1 W2 b2 x`
Two-layer FFN: `W2 * relu(W1 * x + b1) + b2`. Standard transformer
FFN block without residual (residual is handled at the forward pass level).

### `applyFFN n W1 b1 W2 b2 state`
Applies the FFN independently to each token in the state.
Replaces the embedding entirely (no residual here — the residual
for the FFN is absorbed into the weight construction).

## Part 5: Full Transformer Forward Pass

### `TransformerWeights`
Record bundling all weight matrices: Wq0/Wk0/Wv0, Wq1/Wk1/Wv1,
temperature λ_, and FFN weights W1/b1/W2/b2.

### `transformerForwardPass n weights state`
One full transformer forward pass: twoHeadAttention then applyFFN.
This is the function whose iterated application is proven to implement
iterated BP.

## Part 6: Encoding/Decoding Bridge

### `encodeBPState state`
Converts a BPState to a TFState by packing fields into the embedding:
belief → dim 0, nb0 index → dim 1, nb1 index → dim 2, node type → dim 3,
dims 4/5 initialized to 0 (clean scratch slots).

### `decodeTFState template state`
Converts a TFState back to a BPState by reading dim 0 as the new
belief, keeping all other fields from the template BPState unchanged.

## Part 7: BP Definitions

### `updateBelief m0 m1`
The BP belief update for a variable node with two neighbors:
`(m0 * m1) / (m0*m1 + (1-m0)*(1-m1))`. Equivalent to
`σ(logit(m0) + logit(m1))` — sigmoid of sum of log-odds.

### `bp_gatherAll state`
Copies each node's neighbor beliefs into its scratch slots.
`scratch[k] := belief of neighbor k`.

### `bp_computeBeliefs state`
Applies updateBelief to each variable node's scratch slots.
Factor nodes are unchanged.

### `bp_forwardPass state`
One full round of BP: `bp_computeBeliefs ∘ bp_gatherAll`.
The target function that the transformer is proven to implement.

## Part 8: Axioms

### A. Attention axioms

| Axiom | Content |
|-------|---------|
| `decode_encode_belief` | Belief round-trips through encode/decode |
| `encodeBPState_scratch_zero` | Dims 4 and 5 are 0 after encoding |
| `twoHead_gathers_neighbors` | Two heads implement gatherAll (proved in Attention.lean) |

### B. FFN Expressiveness Thesis (FET)

`ffn_implements_updateBelief`: There exist FFN weights computing
`updateBelief` from dims 4 and 5, writing to dim 0. Exact for
sigmoid networks; approximate for ReLU on bounded beliefs.

### C. Convergence Theses

| Axiom | Name | Content |
|-------|------|---------|
| `loopy_bp_converges` | ECT | Loopy BP reaches a fixed point in finite steps |
| `bp_fixed_point_is_posterior` | PCT | The fixed point equals the true posterior |

Both hold exactly for tree-structured graphs without these axioms.

## Part 9: Main Theorems

### `decode_encode_state`
State-level round-trip: `decodeTFState state (encodeBPState state) = state`.
Follows pointwise from `decode_encode_belief`.

### `transformer_implements_bp`
**The core result.** One transformer forward pass implements one
round of BP. Proved by combining `twoHead_gathers_neighbors` (attention
gathers neighbor beliefs into dims 4/5) with `ffn_implements_updateBelief`
(FFN computes updateBelief from dims 4/5 into dim 0). The weights are
constructed explicitly in the proof.

### `transformer_iterated_implements_runBP`
T transformer passes implement T rounds of BP. Proved by induction
on T using `transformer_implements_bp`.

### `transformer_computes_posterior`
Given ECT and PCT, there exist weights W and steps T such that the
transformer computes true posterior beliefs at every node. The formal
statement of the no-hallucination claim: beliefs come from evidence
via message passing, not from pattern completion.