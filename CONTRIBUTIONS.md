# Contributions

## 1. Main Theorem: Transformer Implements Belief Propagation

**`transformer_implements_bp`** (Preliminaries.lean)

> Given a BP state on a factor graph with n nodes, there exist
> transformer weights W such that one transformer forward pass
> on the encoded state decodes to exactly one round of BP.
>
> `∃ W, decodeTFState state (transformerForwardPass n W (encodeBPState state))`
> `     = bp_forwardPass state`

This is the core result. It is proven from first principles given
the axioms listed in Section 4 below. The proof constructs W
explicitly — the weight matrices are given in closed form.

## 2. Iterated Theorem: T Passes = T Rounds of BP

**`transformer_iterated_implements_runBP`** (Preliminaries.lean)

> T transformer forward passes implement T rounds of BP.
>
> `∃ W, (decodeTFState ∘ transformerForwardPass n W ∘ encodeBPState)^[T] state`
> `     = bp_forwardPass^[T] state`

Proved by induction on T using `transformer_implements_bp`.
Base case is trivial. Inductive step applies the single-step theorem.

## 3. Capstone Theorem: Transformer Computes True Posteriors

**`transformer_computes_posterior`** (Preliminaries.lean)

> Assuming ECT and PCT (see Section 3), there exist weights W and
> steps T such that the transformer computes the true posterior
> belief at every node.
>
> `∃ W T, ∀ j,`
> `  (decodeTFState ∘ transformerForwardPass n W ∘ encodeBPState)^[T] state j`
> `  |>.belief = P_true j`

This is the formal statement of the no-hallucination claim from
Coppola (2024): beliefs are determined by message passing from
evidence, not by pattern completion. Conditional on ECT and PCT.

## 4. Attention Construction: Two Heads Implement GatherAll

**`attention_implements_gather0`** (Attention.lean)

> Head 0, with query/key on dim 1 and value routing dim 0 → dim 4,
> places neighbor 0's belief into dim 4 of the residual stream.
>
> `∃ λ_, (attentionHead n state Wq0 Wk0 Wv0 λ_ j).embedding ⟨4,...⟩`
> `      = (state (state j).neighbors ⟨0,...⟩).belief`

Proved via: score gap axiom → hardmax → value extraction → residual.

**`attention_implements_gather1`** (Attention.lean)

> Symmetric result for head 1, placing neighbor 1's belief into dim 5.

**`attention_implements_gatherAll`** (Attention.lean)

> After twoHeadAttention, dim 4 holds neighbor 0's belief and
> dim 5 holds neighbor 1's belief simultaneously.
>
> `∃ λ_, (twoHeadAttention ... λ_ j).embedding ⟨4,...⟩ = nb0.belief`
> `    ∧ (twoHeadAttention ... λ_ j).embedding ⟨5,...⟩ = nb1.belief`

Proved via the two single-head lemmas plus independence axioms
showing the heads write to disjoint dimensions (4 and 5).

## 5. Explicit Weight Construction

The proof of `transformer_implements_bp` constructs weights explicitly:

| Weight | Definition | Purpose |
|--------|-----------|---------|
| `Wq0, Wk0` | `projectDim ⟨1⟩` | Head 0 attends on dim 1 (nb0 index) |
| `Wv0` | `crossProject ⟨0⟩ ⟨4⟩` | Routes belief → scratch slot 0 |
| `Wq1, Wk1` | `projectDim ⟨2⟩` | Head 1 attends on dim 2 (nb1 index) |
| `Wv1` | `crossProject ⟨0⟩ ⟨5⟩` | Routes belief → scratch slot 1 |
| `W1,b1,W2,b2` | FFN Expressiveness Thesis | Computes updateBelief from dims 4,5 |

The embedding layout (D_model = 8) is:

| Dim | Content |
|-----|---------|
| 0 | belief |
| 1 | neighbor 0's token index |
| 2 | neighbor 1's token index |
| 3 | node type (0=variable, 1=factor) |
| 4 | scratch slot 0 (filled by head 0) |
| 5 | scratch slot 1 (filled by head 1) |
| 6,7 | reserved |

## 6. Named Axioms

The proof is complete modulo the following named axioms, each with
an honest characterization of what a full proof would require.

### Empirical Theses (cannot be removed without restricting scope)

| Axiom | Statement | Status |
|-------|-----------|--------|
| FET (`ffn_implements_updateBelief`) | FFN weights exist that compute updateBelief | Exact for sigmoid nets; approx for ReLU |
| ECT (`loopy_bp_converges`) | Loopy BP converges to a fixed point | Empirical; exact on trees |
| PCT (`bp_fixed_point_is_posterior`) | BP fixed point = true posterior | Approx on loopy graphs; exact on trees |

### Standard Mathematical Facts (dischargeable in principle)

| Axiom | Statement | Discharge path |
|-------|-----------|---------------|
| `decode_encode_belief` | Belief survives encode/decode | simp on definitions |
| `encodeBPState_scratch_zero` | Dims 4,5 zero after encoding | simp on definitions |
| `twoHead_gathers_neighbors` | Two heads implement gatherAll | `attention_implements_gatherAll` |
| `projectDim_extract` | Projection matrix extracts one dim | foldl computation |
| `crossProject_extract` | Cross-projection routes src→dst | foldl computation |
| `query/key/value extract` (6) | Weight matrices extract correct dims | foldl computation |
| `attention_score_gap0/1` | Scores maximized at correct neighbor | posEncDot_distinct |
| `hardmax_attention_exact` | Attended value = value at argmax | softmax_concentrates |
| `head1_zero_at_dim4` | Head 1 contributes 0 to dim 4 | crossProject_extract |
| `head0_zero_at_dim5` | Head 0 contributes 0 to dim 5 | crossProject_extract |
| `gather1_on_any_state` | Gather1 transfers to intermediate state | value1_belief_extract |
| `head0_preserves_dims0_and_2` | Head 0 doesn't touch dims 0,2 | crossProject_extract |

## 7. Relationship to the Trilogy

This repo is the third in a series formalizing the QBBN system:

- **Coppola (2024)** — introduces QBBN, belief propagation inference,
  and the no-hallucination claim informally
- **hard-bp-lean** — proves BP is exact on tree-structured factor graphs
- **universal-lean** — proves transformer agents are Turing complete
- **transformer-bp-lean** (this repo) — proves transformer implements BP,
  connecting the Turing completeness result to the Bayesian inference result

Combined with hard-bp-lean: a transformer with these weights, run for
T ≥ diameter(graph) steps on a tree-structured knowledge base, computes
exact marginal posteriors. No empirical theses needed for the tree case.