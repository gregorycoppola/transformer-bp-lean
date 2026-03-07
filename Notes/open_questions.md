# Open Mathematical Questions

## Q1: Can the FFN compute updateBelief exactly?

updateBelief(m0, m1) = σ(logit(m0) + logit(m1))

A two-layer ReLU MLP cannot represent logit(m) exactly — logit is smooth
and unbounded near 0 and 1, while ReLU networks are piecewise linear.

Three options:

**Exact with different activation:**
If we replace ReLU with sigmoid activation, a one-layer network computes
σ(w0*m0 + w1*m1 + b) exactly. This is not a standard transformer FFN
but is a valid neural network. The proof would go through exactly.

**Exact with Ψor target:**
The QBBN's learned Ψor is P(p=1|g1,g2) = σ(w·φ(p,g1,g2)) — a sigmoid
of a linear combination. This is what an FFN layer computes exactly.
updateBelief is the special case with equal weights. Proving the FFN
computes the general Ψor (not just updateBelief) would be cleaner and
more general.

**Approximate with ReLU:**
|ffn_relu(m0,m1) - updateBelief(m0,m1)| ≤ C(δ)/W
for beliefs in [δ, 1-δ] and network width W.
Provable by universal approximation theory. Requires bounding
the logit derivative on [δ, 1-δ] to get the constant C(δ).

Current position: axiomatize as FFN Expressiveness Thesis (FET)
and note that option 2 (Ψor target) gives an exact proof with
a minor change to the target function.

## Q2: Do beliefs stay bounded away from 0 and 1?

updateBelief(δ, δ) ≈ δ² for small δ

So if both inputs are small, the output is smaller. Beliefs can
collapse toward 0 under iteration. The FFN approximation error
grows as beliefs approach the boundary.

Four options for handling this:

**Prior boundedness:**
Assume initial beliefs in [δ, 1-δ]. Does not propagate through
iteration without additional argument.

**Evidence anchoring:**
If some nodes are observed (belief clamped to 0 or 1), the
surrounding nodes' beliefs are pulled toward certainty but the
unobserved nodes stay uncertain. Requires graph-structural argument.

**Regularization:**
Add Laplace smoothing: updateBelief_reg(m0,m1,α) = (1-α)*updateBelief(m0,m1) + α*0.5
This explicitly keeps beliefs in [α/2, 1-α/2]. Changes the semantics
slightly but is standard practice.

**Tree restriction:**
On trees, BP is exact and beliefs stay bounded if priors are bounded.
The hard-bp-lean repo targets this case. Avoids the issue entirely.

Current position: this is the deepest open gap. The loopy case
requires either regularization or a graph-structural argument.
Tree case is clean and should be proven first.

## Q3: Does error accumulate or dissipate over T iterations?

If each forward pass has error ε, what is the error after T passes?

The answer depends on the spectral radius ρ of the BP update operator:

    total_error ≤ ε * (1 + ρ + ρ² + ... + ρ^(T-1))
               = ε/(1-ρ)  if ρ < 1  (bounded regardless of T)
               = T*ε      if ρ = 1  (linear growth)
               = ε*(ρ^T)  if ρ > 1  (exponential growth)

For QBBN graphs ρ depends on the factor potentials and graph structure.
Near beliefs of 0.5, ρ < 1 (contractive). Near the boundary, ρ may exceed 1.

The Bethe free energy analysis (Yedidia et al. 2003) implies that when
loopy BP converges (ECT holds), the fixed point is a local minimum of
F_Bethe, which implies local contractivity (ρ < 1 in a neighborhood
of the fixed point). So if ECT holds, ρ < 1 near the fixed point
and total error is bounded by ε/(1-ρ).

This is not yet formalized. It would require connecting the variational
analysis (Thread 6 in LitReview) to the error accumulation argument.

## Q4: Is the decode/encode round-trip the right architecture?

The current statement of 306 iterates:

    (decodeTFState ∘ transformerForwardPass ∘ encodeBPState)^[T]

This is not raw transformer iteration — it re-encodes between every pass.
Is this the right architecture?

Two interpretations:

**Interpretation A (current):** The transformer is a function called
repeatedly on fresh BPState input. The loop is external. The transformer
doesn't "know" it's being iterated.

**Interpretation B (agent loop):** The transformer runs on its own output,
reading and writing to a persistent token sequence. Dims 4/5 accumulate
across passes and need to be reset by the FFN before the next pass.

Interpretation B is closer to how a deployed agent works but requires
the FFN to zero out dims 4/5 after writing the new belief to dim 0.
This adds a constraint on the FFN that is not currently stated.

Interpretation A is cleaner for the proof but less realistic.

Current position: Interpretation A is correct for the formal proof.
Interpretation B is the right framing for the paper — the agent loop
provides the external encode/decode, which in practice means the
transformer writes clean output that gets re-encoded for the next pass.

## Q5: Can attention handle K > 2 neighbors?

Current construction: K=2 neighbors, two attention heads.
One head per neighbor.

For K neighbors you'd need K heads, each attending to one neighbor.
This scales linearly in K, which is fine for small K (typical factor
graphs have K ≤ 5 or so).

For existential quantification you'd need one head that attends to
ALL groundings of a predicate and aggregates (Noisy OR). This is
different from single-neighbor lookup — it's a sum over a subset.

Can attention compute a weighted sum over a subset?
Yes — mask out the non-relevant tokens and let softmax normalize
over the relevant ones. The attended value is then the average
belief over all groundings, which is related to but not exactly
the Noisy OR.

Noisy OR requires:

    P(∃x, P(x)) = 1 - ∏_x (1 - P(x))

This is NOT a weighted sum. It's a product of complements.
Attention computes weighted sums, not products of complements.

So existential quantification via Noisy OR requires a different
mechanism than standard attention. Options:
  (a) Log-space attention: attend to log(1-belief) and sum
      → exponentiate to get product of complements
  (b) Separate Noisy OR layer after attention
  (c) Approximate Noisy OR as a sigmoid of a sum (works for small beliefs)

This is an open design question for extending the current K=2 construction.

## Q6: What is the relationship between this repo and hard-bp-lean?

hard-bp-lean proves: BP is exact on trees (bp_exact_on_tree)
This repo proves: transformer implements BP (transformer_implements_bp)

Combined: transformer is exact on trees

This combination should be stated as a corollary in this repo:

    corollary transformer_exact_on_tree {n : ℕ} (state : BPState n)
        (hTree : isTree (factorGraph state))
        (hDiam : T ≥ diameter (factorGraph state)) :
        ∃ W, decodeTFState state
          (transformerForwardPass n W)^[T] (encodeBPState state)
          = true_marginals state := by
      apply bp_exact_on_tree
      exact transformer_iterated_implements_runBP ...

This is the cleanest possible statement of the main result —
no empirical theses needed, just a tree-structure assumption.