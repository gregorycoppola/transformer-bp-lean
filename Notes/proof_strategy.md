# Proof Strategy

## Current Sorry Count: 5

Located by `fork search sorry`:

    TransformerBPLean/Attention.lean:228   -- Wv routing bug
    TransformerBPLean/Attention.lean:244   -- symmetric to gather0
    TransformerBPLean/Attention.lean:263   -- gatherAll composition
    TransformerBPLean/Preliminaries.lean:294 -- transformer_implements_bp
    TransformerBPLean/Preliminaries.lean:306 -- iterated claim

## Classification

### Bookkeeping (no mathematical content)

**244** — attention_implements_gather1
Symmetric to attention_implements_gather0. Once gather0 is closed,
this is the same proof with indices 0 and 1 swapped. Should close
with minor modification of gather0 proof.

**263** — attention_implements_gatherAll
Conjunction of gather0 and gather1. Proof is:

    constructor
    · exact attention_implements_gather0 ...
    · exact attention_implements_gather1 ...

Plus independence argument: head 0 writes to dim 4, head 1 writes to
dim 5, they don't interfere. Follows from Wv routing to different dims.

### Definition Bug (fix the definition, proof follows)

**228** — Wv_neighbor0 routing
Current definition:

    Wv_neighbor0 = projectDim ⟨0, ...⟩

This projects source dim 0 to output dim 0. But we need source dim 0
mapped to output dim 4 (the scratch slot for neighbor 0).

Fix: define a cross-projection:

    noncomputable def crossProject (src out : Fin D_model) :
        Fin D_model → Fin D_model → ℝ :=
      fun i j => if i = out ∧ j = src then 1 else 0

Then:

    Wv_neighbor0 = crossProject ⟨0, ...⟩ ⟨4, ...⟩
    Wv_neighbor1 = crossProject ⟨0, ...⟩ ⟨5, ...⟩

Once the definition is fixed, the proof that attended value at dim 4
equals neighbor's belief follows from value_belief_extract plus
the cross-projection computation.

### Mathematical Weight (real content)

**294** — transformer_implements_bp
Two sub-problems bundled:

Sub-problem A (attention half):
Follows from attention_implements_gatherAll once 228/244/263 are closed.
This half is essentially done.

Sub-problem B (FFN half):
Need to show FFN computes updateBelief from dims 4 and 5.

    updateBelief(m0, m1) = (m0*m1) / (m0*m1 + (1-m0)(1-m1))
                         = σ(logit(m0) + logit(m1))

A two-layer ReLU FFN cannot represent this exactly. Options:
  (a) Axiomatize as FFN Expressiveness Thesis (FET) — cleanest
  (b) Prove approximate version with explicit error bound C(δ)/W
  (c) Change updateBelief target to learned Ψor (sigmoid of linear)
      which FFN computes exactly

Option (c) is mathematically cleanest: the learned Ψor in the QBBN
paper is already a sigmoid of a dot product, which a one-layer network
computes exactly. updateBelief is just one instantiation with equal weights.

**306** — transformer_iterated_implements_runBP
Two issues:

Issue A (decode/encode round-trip):
The statement iterates (decodeTFState ∘ transformerForwardPass ∘ encodeBPState).
This requires decodeTFState ∘ encodeBPState = id on beliefs.
This is true by definition inspection but needs to be stated as a lemma:

    lemma decode_encode_roundtrip {n : ℕ} (state : BPState n) (j : Fin n) :
        (decodeTFState state (encodeBPState state) j).belief =
        (state j).belief := by
      simp [decodeTFState, encodeBPState]

Issue B (dirty scratch dims):
After one pass, dims 4 and 5 contain neighbor beliefs from that pass.
On the next pass, the residual adds to whatever is already in dims 4/5.
The statement handles this by re-encoding between passes (encodeBPState
resets dims 4/5 to 0). This is correct but means the loop is:

    encode → transformer → decode → encode → transformer → decode → ...

not raw transformer iteration. The proof structure is:

    induction T with
    | zero => simp
    | succ T ih =>
        simp [Function.iterate_succ]
        rw [← ih]
        exact transformer_implements_bp ...

This is routine once 294 is closed.

## Attack Order

1. Fix Wv definition (228) — definition change, not proof
2. Close gather1 (244) — copy gather0 proof, swap indices
3. Close gatherAll (263) — constructor + independence
4. Prove decode_encode_roundtrip — simp lemma
5. Decide on FFN strategy for 294 (axiom vs approximate vs Ψor target)
6. Close 306 by induction using 294

Steps 1-4 can be done in one session.
Step 5 is the key design decision.
Step 6 is routine after step 5.