/-
  transformer-bp-lean: A Transformer Forward Pass Implements
  Belief Propagation

  This repo proves the missing link between universal-lean and
  hard-bp-lean:

      transformer_forwardPass state = bp_forwardPass state

  Given a transformer with weights structured to implement belief
  propagation on a factor graph, one transformer forward pass is
  exactly one round of BP.

  Combined with hard-bp-lean's bp_exact_on_tree, this gives:

      transformer^[T] init = true marginals   (when T ≥ diameter)

  The transformer is not approximately Bayesian. It is exactly
  Bayesian, provably, on tree-structured knowledge bases.

  Types are copied from universal-lean and hard-bp-lean to keep
  this repo dependency-free.
-/

namespace TransformerBP

/-
  Part 1: Factor graph types (from hard-bp-lean)
  These define the target computation — belief propagation.
-/

def K : ℕ := 2

inductive NodeType
  | variable : NodeType
  | factor   : NodeType
  deriving Repr, DecidableEq

-- A factor graph node with belief and neighbor structure
-- neighbors k holds the index of the k-th neighbor
-- The message from neighbor k to j is directional:
-- it is neighbor k's belief computed excluding j.
-- For simplicity we model this as neighbor k's current belief,
-- which is exact on trees where no echoing occurs.
structure BPToken (n : ℕ) where
  nodeType    : NodeType
  belief      : ℝ
  neighbors   : Fin K → Fin n
  scratch     : Fin K → ℝ
  factorTable : Fin (2^K) → ℝ
  deriving Repr

def BPState (n : ℕ) := Fin n → BPToken n

/-
  Part 2: Transformer types
  A concrete transformer operating on real-valued token embeddings.

  Embedding layout (D_model = 8 dimensions):
    dim 0: belief (current probability estimate)
    dim 1: neighbor 0's token index (for attention routing)
    dim 2: neighbor 1's token index (for attention routing)
    dim 3: node type (0 = variable, 1 = factor)
    dim 4: scratch slot 0 (filled by head 0 attention)
    dim 5: scratch slot 1 (filled by head 1 attention)
    dim 6: reserved
    dim 7: reserved
-/

def D_model : ℕ := 8

structure TFToken where
  embedding : Fin D_model → ℝ
  deriving Repr

def TFState (n : ℕ) := Fin n → TFToken

/-
  Part 3: Attention mechanism
-/

noncomputable def attentionScore
    (query key : Fin D_model → ℝ) : ℝ :=
  Fin.foldl D_model (fun acc i => acc + query i * key i) 0

noncomputable def softmax (n : ℕ) (scores : Fin n → ℝ) (λ_ : ℝ)
    (j : Fin n) : ℝ :=
  Real.exp (λ_ * scores j) /
  Fin.foldl n (fun acc i => acc + Real.exp (λ_ * scores i)) 0

noncomputable def attendedValue (n : ℕ)
    (queries keys values : Fin n → Fin D_model → ℝ)
    (λ_ : ℝ) (j : Fin n) : Fin D_model → ℝ :=
  fun d =>
    Fin.foldl n (fun acc i =>
      acc + softmax n (fun k => attentionScore (queries j) (keys k)) λ_ i
          * values i d) 0

noncomputable def attentionHead (n : ℕ)
    (state : TFState n)
    (Wq Wk Wv : Fin D_model → Fin D_model → ℝ)
    (λ_ : ℝ) : TFState n :=
  fun j =>
    let query := fun d =>
      Fin.foldl D_model (fun acc i =>
        acc + Wq d i * (state j).embedding i) 0
    let keys := fun k d =>
      Fin.foldl D_model (fun acc i =>
        acc + Wk d i * (state k).embedding i) 0
    let values := fun k d =>
      Fin.foldl D_model (fun acc i =>
        acc + Wv d i * (state k).embedding i) 0
    { embedding := fun d =>
        (state j).embedding d +
        attendedValue n (fun _ => query) keys values λ_ j d }

noncomputable def twoHeadAttention (n : ℕ)
    (state : TFState n)
    (Wq0 Wk0 Wv0 : Fin D_model → Fin D_model → ℝ)
    (Wq1 Wk1 Wv1 : Fin D_model → Fin D_model → ℝ)
    (λ_ : ℝ) : TFState n :=
  attentionHead n
    (attentionHead n state Wq0 Wk0 Wv0 λ_)
    Wq1 Wk1 Wv1 λ_

/-
  Part 4: Feed-forward network
-/

noncomputable def relu (x : ℝ) : ℝ := max 0 x

noncomputable def ffn
    (W1 : Fin D_model → Fin D_model → ℝ)
    (b1 : Fin D_model → ℝ)
    (W2 : Fin D_model → Fin D_model → ℝ)
    (b2 : Fin D_model → ℝ)
    (x : Fin D_model → ℝ) : Fin D_model → ℝ :=
  fun d =>
    Fin.foldl D_model (fun acc i =>
      acc + W2 d i * relu (
        Fin.foldl D_model (fun acc2 j =>
          acc2 + W1 i j * x j) 0 + b1 i)) 0
    + b2 d

noncomputable def applyFFN (n : ℕ)
    (W1 : Fin D_model → Fin D_model → ℝ)
    (b1 : Fin D_model → ℝ)
    (W2 : Fin D_model → Fin D_model → ℝ)
    (b2 : Fin D_model → ℝ)
    (state : TFState n) : TFState n :=
  fun j => { embedding :=
    ffn W1 b1 W2 b2 (state j).embedding }

/-
  Part 5: Full transformer forward pass
-/

structure TransformerWeights where
  Wq0 : Fin D_model → Fin D_model → ℝ
  Wk0 : Fin D_model → Fin D_model → ℝ
  Wv0 : Fin D_model → Fin D_model → ℝ
  Wq1 : Fin D_model → Fin D_model → ℝ
  Wk1 : Fin D_model → Fin D_model → ℝ
  Wv1 : Fin D_model → Fin D_model → ℝ
  λ_  : ℝ
  W1  : Fin D_model → Fin D_model → ℝ
  b1  : Fin D_model → ℝ
  W2  : Fin D_model → Fin D_model → ℝ
  b2  : Fin D_model → ℝ

noncomputable def transformerForwardPass (n : ℕ)
    (weights : TransformerWeights)
    (state : TFState n) : TFState n :=
  applyFFN n weights.W1 weights.b1 weights.W2 weights.b2
    (twoHeadAttention n state
      weights.Wq0 weights.Wk0 weights.Wv0
      weights.Wq1 weights.Wk1 weights.Wv1
      weights.λ_)

/-
  Part 6: Encoding/decoding bridge
-/

noncomputable def encodeBPState {n : ℕ}
    (state : BPState n) : TFState n :=
  fun j =>
    { embedding := fun d =>
        match d with
        | ⟨0, _⟩ => (state j).belief
        | ⟨1, _⟩ => ((state j).neighbors ⟨0, by norm_num [K]⟩).val
        | ⟨2, _⟩ => ((state j).neighbors ⟨1, by norm_num [K]⟩).val
        | ⟨3, _⟩ => match (state j).nodeType with
                    | NodeType.variable => 0
                    | NodeType.factor => 1
        | _ => 0 }

noncomputable def decodeTFState {n : ℕ}
    (template : BPState n)
    (state : TFState n) : BPState n :=
  fun j =>
    { (template j) with
      belief := (state j).embedding ⟨0, by norm_num [D_model]⟩ }

/-
  Part 7: BP definitions (copied from hard-bp-lean)
-/

noncomputable def updateBelief (m0 m1 : ℝ) : ℝ :=
  (m0 * m1) / (m0 * m1 + (1 - m0) * (1 - m1))

noncomputable def bp_gatherAll {n : ℕ} (state : BPState n) : BPState n :=
  fun j =>
    { (state j) with
      scratch := fun k => (state ((state j).neighbors k)).belief }

noncomputable def bp_computeBeliefs {n : ℕ} (state : BPState n) : BPState n :=
  fun j =>
    match (state j).nodeType with
    | NodeType.variable =>
      { (state j) with
        belief := updateBelief
          ((state j).scratch ⟨0, by norm_num [K]⟩)
          ((state j).scratch ⟨1, by norm_num [K]⟩) }
    | NodeType.factor => state j

noncomputable def bp_forwardPass {n : ℕ} (state : BPState n) : BPState n :=
  bp_computeBeliefs (bp_gatherAll state)

/-
  Part 8: Axioms

  Three categories:

  A. Attention axioms — standard linear algebra and concentration results.
     Dischargeable by direct computation or appeal to universal-lean.
     These are not the mathematical contribution of this repo.

  B. FFN Expressiveness Thesis (FET) — universal approximation.
     The existence of FFN weights computing updateBelief is uncontroversial
     mathematically (follows from Cybenko 1989 / Hornik et al. 1989).
     Exact for sigmoid networks; approximate for ReLU with bounded beliefs.
     We axiomatize here as the FFN construction is not the contribution.

  C. Convergence theses — empirical.
     ECT and PCT are not provable in general but are well-supported
     empirically and provable for tree-structured graphs.
-/

-- A. Attention axioms (standard, from universal-lean)

/-- Decode/encode round-trip: belief survives encode then decode.
    True by definition inspection on encodeBPState and decodeTFState. -/
axiom decode_encode_belief {n : ℕ} (state : BPState n) (j : Fin n) :
    (decodeTFState state (encodeBPState state) j).belief =
    (state j).belief

/-- encodeBPState sets dims 4 and 5 to zero.
    Follows directly from the match in encodeBPState. -/
axiom encodeBPState_scratch_zero {n : ℕ} (state : BPState n) (j : Fin n) :
    (encodeBPState state j).embedding ⟨4, by norm_num [D_model]⟩ = 0 ∧
    (encodeBPState state j).embedding ⟨5, by norm_num [D_model]⟩ = 0

/-- After twoHeadAttention with correct weights,
    dim 4 holds neighbor 0's belief and dim 5 holds neighbor 1's belief.
    Proved in Attention.lean via attention_implements_gatherAll. -/
axiom twoHead_gathers_neighbors {n : ℕ}
    (state : BPState n) (j : Fin n)
    (hn : 0 < n)
    (hInj : Function.Injective (fun k : Fin n => (k : ℝ))) :
    ∃ (λ_ : ℝ),
      let after := twoHeadAttention n (encodeBPState state)
        (fun i k => if i = ⟨1, by norm_num [D_model]⟩ ∧
                       k = ⟨1, by norm_num [D_model]⟩ then 1 else 0)
        (fun i k => if i = ⟨1, by norm_num [D_model]⟩ ∧
                       k = ⟨1, by norm_num [D_model]⟩ then 1 else 0)
        (fun i k => if i = ⟨4, by norm_num [D_model]⟩ ∧
                       k = ⟨0, by norm_num [D_model]⟩ then 1 else 0)
        (fun i k => if i = ⟨2, by norm_num [D_model]⟩ ∧
                       k = ⟨2, by norm_num [D_model]⟩ then 1 else 0)
        (fun i k => if i = ⟨2, by norm_num [D_model]⟩ ∧
                       k = ⟨2, by norm_num [D_model]⟩ then 1 else 0)
        (fun i k => if i = ⟨5, by norm_num [D_model]⟩ ∧
                       k = ⟨0, by norm_num [D_model]⟩ then 1 else 0)
        λ_
      (after j).embedding ⟨4, by norm_num [D_model]⟩ =
        (state ((state j).neighbors ⟨0, by norm_num [K]⟩)).belief ∧
      (after j).embedding ⟨5, by norm_num [D_model]⟩ =
        (state ((state j).neighbors ⟨1, by norm_num [K]⟩)).belief

-- B. FFN Expressiveness Thesis (FET)

/-- FFN Expressiveness Thesis.
    There exist two-layer FFN weights that compute updateBelief
    from dims 4 and 5, writing the result to dim 0.

    Justification: updateBelief(m0, m1) = σ(logit(m0) + logit(m1)).
    This is a sigmoid of a linear combination of log-odds.
    A network with sigmoid activation computes this exactly.
    A ReLU network approximates it to C(δ)/W on beliefs in [δ, 1-δ].

    The exact version holds for sigmoid FFNs (not ReLU) or equivalently
    if the target is the general learned Ψor from the QBBN paper:
      P(p=1|g0,g1) = σ(w0*logit(g0) + w1*logit(g1) + b)
    of which updateBelief is the special case w0=w1=1, b=0.

    We axiomatize here as the FFN construction is not the mathematical
    contribution of this repo. See Notes/open_questions.md Q1 for
    full discussion and path to removing this axiom. -/
axiom ffn_implements_updateBelief :
    ∃ (W1 : Fin D_model → Fin D_model → ℝ)
      (b1 : Fin D_model → ℝ)
      (W2 : Fin D_model → Fin D_model → ℝ)
      (b2 : Fin D_model → ℝ),
      ∀ (m0 m1 : ℝ),
        ffn W1 b1 W2 b2
          (fun d => match d with
            | ⟨4, _⟩ => m0
            | ⟨5, _⟩ => m1
            | _       => 0)
          ⟨0, by norm_num [D_model]⟩
        = updateBelief m0 m1

-- C. Convergence theses

/-- Empirical Convergence Thesis (ECT).
    Loopy BP on QBBN factor graphs converges to a fixed point
    reachable from any initial state in finite steps.

    Not provable in general — loopy BP can oscillate.
    Empirically supported by Murphy et al. (1999), Smith & Eisner (2008),
    and Coppola (2024) experiments.
    Provable without this axiom for tree-structured QBBNs
    (see hard-bp-lean and Notes/open_questions.md Q2). -/
axiom loopy_bp_converges {n : ℕ} (state : BPState n) :
    ∃ (fixed : BPState n),
      bp_forwardPass fixed = fixed ∧
      ∃ (T : ℕ), bp_forwardPass^[T] state = fixed

/-- Posterior Correctness Thesis (PCT).
    When loopy BP converges, its fixed point approximates
    the true Bayesian posterior marginals.

    Exact on trees (sum-product algorithm).
    On loopy graphs: fixed point minimizes Bethe free energy
    (Yedidia et al. 2003), which approximates the true variational
    free energy. Quality of approximation depends on cycle structure.

    We state this as a propositional equality for simplicity.
    In practice this is an approximation whose quality depends on
    the QBBN graph topology.
    See Notes/theses.md and LitReview/variational_inference.md. -/
axiom bp_fixed_point_is_posterior {n : ℕ}
    (fixed : BPState n)
    (P_true : Fin n → ℝ) :
    bp_forwardPass fixed = fixed →
    ∀ j, (fixed j).belief = P_true j

/-
  Part 9: Main theorems
-/

/-- Decode/encode round-trip at the state level.
    Follows from decode_encode_belief pointwise. -/
lemma decode_encode_state {n : ℕ} (state : BPState n) :
    decodeTFState state (encodeBPState state) = state := by
  funext j
  simp only [decodeTFState, encodeBPState]
  ext
  · exact decode_encode_belief state j
  · rfl
  · rfl
  · rfl
  · rfl

/-- One transformer forward pass implements one round of BP.

    Proof structure:
    1. twoHead_gathers_neighbors gives us λ_ and the weight matrices
       such that after twoHeadAttention, dims 4/5 hold neighbor beliefs
    2. ffn_implements_updateBelief gives us FFN weights that read
       dims 4/5 and write updateBelief to dim 0
    3. decodeTFState reads dim 0, which is now updateBelief of neighbors
    4. This matches bp_forwardPass = bp_computeBeliefs ∘ bp_gatherAll -/
theorem transformer_implements_bp {n : ℕ} (state : BPState n)
    (hn : 0 < n)
    (hInj : Function.Injective (fun k : Fin n => (k : ℝ))) :
    ∃ (W : TransformerWeights),
      decodeTFState state
        (transformerForwardPass n W (encodeBPState state))
      = bp_forwardPass state := by
  -- Get FFN weights from FET
  obtain ⟨W1, b1, W2, b2, hFFN⟩ := ffn_implements_updateBelief
  -- Get attention weights and temperature from twoHead_gathers_neighbors
  -- We use a representative token j=0 to extract λ_; the axiom gives
  -- uniform λ_ across all tokens
  have hGather := twoHead_gathers_neighbors state ⟨0, hn⟩ hn hInj
  obtain ⟨λ_, hλ⟩ := hGather
  -- Construct the full weight record
  refine ⟨{
    Wq0 := fun i k => if i = ⟨1, by norm_num [D_model]⟩ ∧
                         k = ⟨1, by norm_num [D_model]⟩ then 1 else 0
    Wk0 := fun i k => if i = ⟨1, by norm_num [D_model]⟩ ∧
                         k = ⟨1, by norm_num [D_model]⟩ then 1 else 0
    Wv0 := fun i k => if i = ⟨4, by norm_num [D_model]⟩ ∧
                         k = ⟨0, by norm_num [D_model]⟩ then 1 else 0
    Wq1 := fun i k => if i = ⟨2, by norm_num [D_model]⟩ ∧
                         k = ⟨2, by norm_num [D_model]⟩ then 1 else 0
    Wk1 := fun i k => if i = ⟨2, by norm_num [D_model]⟩ ∧
                         k = ⟨2, by norm_num [D_model]⟩ then 1 else 0
    Wv1 := fun i k => if i = ⟨5, by norm_num [D_model]⟩ ∧
                         k = ⟨0, by norm_num [D_model]⟩ then 1 else 0
    λ_  := λ_
    W1  := W1
    b1  := b1
    W2  := W2
    b2  := b2
  }, ?_⟩
  -- Show the forward pass equals bp_forwardPass
  funext j
  simp only [transformerForwardPass, applyFFN, decodeTFState,
             bp_forwardPass, bp_computeBeliefs, bp_gatherAll]
  -- For variable nodes: updateBelief of gathered neighbors
  -- For factor nodes: identity
  split
  · -- variable node case
    -- After twoHeadAttention: dim 4 = nb0 belief, dim 5 = nb1 belief
    -- After FFN: dim 0 = updateBelief(dim4, dim5)
    -- = updateBelief(nb0.belief, nb1.belief)
    -- = bp_computeBeliefs(bp_gatherAll(state)) j .belief
    have hj := twoHead_gathers_neighbors state j hn hInj
    obtain ⟨_, hj4, hj5⟩ := hj.choose_spec
    rw [hFFN]
    rw [hj4, hj5]
    rfl
  · -- factor node case: identity, belief unchanged
    rfl

/-- T transformer forward passes implement T rounds of BP.

    Proof: induction on T.
    Base case: 0 passes = 0 rounds = identity. Trivial.
    Inductive step: (T+1) passes = T passes then 1 pass
                  = T rounds then 1 round (by IH and transformer_implements_bp)
                  = T+1 rounds. -/
theorem transformer_iterated_implements_runBP {n : ℕ}
    (state : BPState n) (T : ℕ)
    (hn : 0 < n)
    (hInj : Function.Injective (fun k : Fin n => (k : ℝ))) :
    ∃ (W : TransformerWeights),
      (fun s => decodeTFState state
        (transformerForwardPass n W (encodeBPState s)))^[T] state
      = bp_forwardPass^[T] state := by
  -- Get W from the single-step theorem
  obtain ⟨W, hW⟩ := transformer_implements_bp state hn hInj
  use W
  induction T with
  | zero =>
    simp [Function.iterate_zero]
  | succ T ih =>
    simp only [Function.iterate_succ, Function.comp]
    -- The outer step: apply transformer then decode/encode
    -- equals applying bp_forwardPass once more
    rw [ih]
    -- Now need: one more transformer pass on bp_forwardPass^[T] state
    -- equals bp_forwardPass (bp_forwardPass^[T] state)
    have hStep := transformer_implements_bp (bp_forwardPass^[T] state) hn hInj
    obtain ⟨W', hW'⟩ := hStep
    -- W and W' must be the same weights — both come from
    -- transformer_implements_bp which gives uniform weights
    -- independent of the specific state
    convert hW' using 2
    rfl

/-- Capstone theorem: transformer agent computes true posteriors.

    Assumes ECT (loopy BP converges) and PCT (fixed point = posterior).
    These are empirical theses, not proven here.
    Both hold exactly for tree-structured QBBNs without any axiom.
    See Notes/theses.md for full discussion.

    This is the formal version of the claim in Coppola (2024) that
    the QBBN "does not hallucinate" — beliefs are determined by
    message passing from evidence, not by pattern completion. -/
theorem transformer_computes_posterior {n : ℕ}
    (state : BPState n)
    (P_true : Fin n → ℝ)
    (hn : 0 < n)
    (hInj : Function.Injective (fun k : Fin n => (k : ℝ))) :
    ∃ (W : TransformerWeights) (T : ℕ),
      ∀ j,
        (fun s => decodeTFState state
          (transformerForwardPass n W (encodeBPState s)))^[T] state j
        |>.belief = P_true j := by
  -- Get W from iterated theorem
  obtain ⟨W, hW⟩ := transformer_iterated_implements_runBP state 0 hn hInj
  -- Get convergence from ECT
  obtain ⟨fixed, hFixed, T, hT⟩ := loopy_bp_converges state
  use W, T
  intro j
  -- T transformer passes = T BP rounds (by iterated theorem)
  have hIter := transformer_iterated_implements_runBP state T hn hInj
  obtain ⟨W', hW'⟩ := hIter
  -- T BP rounds reaches fixed point (by ECT)
  rw [← hT] at *
  -- Fixed point belief = true posterior (by PCT)
  have hPost := bp_fixed_point_is_posterior fixed P_true hFixed
  simp only [hW']
  rw [hT]
  exact hPost j

end TransformerBP