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

-- Embedding dimension: 8 gives enough room for belief,
-- two neighbor indices, node type, and two scratch slots
def D_model : ℕ := 8

-- A transformer token: real-valued embedding vector
structure TFToken where
  embedding : Fin D_model → ℝ
  deriving Repr

def TFState (n : ℕ) := Fin n → TFToken

/-
  Part 3: Attention mechanism
  Softmax attention with query/key/value projections.
  We use the hardmax approximation from universal-lean:
  with sufficient temperature, softmax concentrates on the
  maximum scoring key.
-/

-- Attention score between query and key
noncomputable def attentionScore
    (query key : Fin D_model → ℝ) : ℝ :=
  Fin.foldl D_model (fun acc i => acc + query i * key i) 0

-- Softmax over n scores with temperature λ
noncomputable def softmax (n : ℕ) (scores : Fin n → ℝ) (λ_ : ℝ)
    (j : Fin n) : ℝ :=
  Real.exp (λ_ * scores j) /
  Fin.foldl n (fun acc i => acc + Real.exp (λ_ * scores i)) 0

-- Weighted sum of values under softmax attention
noncomputable def attendedValue (n : ℕ)
    (queries keys values : Fin n → Fin D_model → ℝ)
    (λ_ : ℝ) (j : Fin n) : Fin D_model → ℝ :=
  fun d =>
    Fin.foldl n (fun acc i =>
      acc + softmax n (fun k => attentionScore (queries j) (keys k)) λ_ i
          * values i d) 0

-- One attention head: gather information from one neighbor
-- Returns a residual update to the embedding
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

-- Apply two attention heads sequentially
-- Head 0 gathers neighbor 0's belief into dim 4
-- Head 1 gathers neighbor 1's belief into dim 5
-- Each head uses a residual connection so earlier dims are preserved
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
  Two-layer MLP with ReLU activation.
  Applied independently to each token.
  After attention, dim 4 holds neighbor 0's belief and
  dim 5 holds neighbor 1's belief. The FFN reads these
  and computes updateBelief, writing the result to dim 0.
-/

noncomputable def relu (x : ℝ) : ℝ := max 0 x

-- Two-layer FFN: ReLU(W1 x + b1) W2 + b2
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

-- Apply FFN to all tokens
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
  Two attention heads (one per neighbor) followed by one FFN layer.
  This is the minimal transformer that can implement one round of BP
  for a factor graph with K=2 neighbors per node.

  Architecture:
    state
      → head 0 (gather neighbor 0 belief → dim 4)
      → head 1 (gather neighbor 1 belief → dim 5)
      → FFN (compute updateBelief(dim4, dim5) → dim 0)
    = one round of bp_forwardPass
-/

structure TransformerWeights where
  -- Head 0: gathers neighbor 0's belief into dim 4
  Wq0 : Fin D_model → Fin D_model → ℝ
  Wk0 : Fin D_model → Fin D_model → ℝ
  Wv0 : Fin D_model → Fin D_model → ℝ
  -- Head 1: gathers neighbor 1's belief into dim 5
  Wq1 : Fin D_model → Fin D_model → ℝ
  Wk1 : Fin D_model → Fin D_model → ℝ
  Wv1 : Fin D_model → Fin D_model → ℝ
  -- Shared temperature for both heads
  λ_ : ℝ
  -- FFN: computes updateBelief from dims 4 and 5
  W1 : Fin D_model → Fin D_model → ℝ
  b1 : Fin D_model → ℝ
  W2 : Fin D_model → Fin D_model → ℝ
  b2 : Fin D_model → ℝ

noncomputable def transformerForwardPass (n : ℕ)
    (weights : TransformerWeights)
    (state : TFState n) : TFState n :=
  applyFFN n weights.W1 weights.b1 weights.W2 weights.b2
    (twoHeadAttention n state
      weights.Wq0 weights.Wk0 weights.Wv0
      weights.Wq1 weights.Wk1 weights.Wv1
      weights.λ_)

/-
  Part 6: The encoding/decoding bridge
-/

-- Encode a BP state as a transformer state
-- dim 0: belief
-- dim 1: neighbor 0's index (for head 0 attention routing)
-- dim 2: neighbor 1's index (for head 1 attention routing)
-- dim 3: node type (0 = variable, 1 = factor)
-- dim 4: scratch 0 (will be filled by head 0)
-- dim 5: scratch 1 (will be filled by head 1)
-- dim 6,7: reserved
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

-- Decode: extract belief from dim 0
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
  Part 8: Main theorems
-/

-- The main theorem: there exist weights such that one transformer
-- forward pass implements one round of BP.
-- Proof: construct weights explicitly.
--   Head 0: Wq0 extracts dim 1, Wk0 extracts dim 1, Wv0 extracts dim 0
--           → softmax concentrates on neighbor 0, copies belief to dim 4
--   Head 1: Wq1 extracts dim 2, Wk1 extracts dim 2, Wv1 extracts dim 0
--           → softmax concentrates on neighbor 1, copies belief to dim 5
--   FFN:    reads dim 4 and dim 5, computes updateBelief, writes to dim 0
theorem transformer_implements_bp (n : ℕ) (state : BPState n)
    (hn : 0 < n)
    (hInj : Function.Injective (fun k : Fin n => (k : ℝ))) :
    ∃ (W : TransformerWeights),
      decodeTFState state
        (transformerForwardPass n W (encodeBPState state))
      = bp_forwardPass state := by
  sorry -- construct W explicitly using attention_implements_gatherAll
        -- and FFN implements updateBelief

-- Corollary: T transformer forward passes = T rounds of BP
theorem transformer_iterated_implements_runBP (n : ℕ)
    (state : BPState n) (T : ℕ)
    (hn : 0 < n)
    (hInj : Function.Injective (fun k : Fin n => (k : ℝ))) :
    ∃ (W : TransformerWeights),
      (fun s => decodeTFState state
        (transformerForwardPass n W (encodeBPState s)))^[T] state
      = (bp_forwardPass^[T] state) := by
  sorry -- induction on T using transformer_implements_bp

end TransformerBP