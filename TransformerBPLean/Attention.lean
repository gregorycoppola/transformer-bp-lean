import TransformerBPLean.Preliminaries

namespace TransformerBP

/-
  Attention implements gatherAll.

  The claim: with the right Wq, Wk, Wv and sufficient temperature λ,
  the attention head copies neighbor beliefs into the right positions.

  Specifically for neighbor k=0:
  - Query: extract embedding dim 1 (= neighbor 0's index)
  - Key:   extract embedding dim 1 (= this token's own index)
  - Value: extract embedding dim 0 (= this token's belief)

  Softmax concentrates on the unique token whose key matches the query
  — i.e. the token at the neighbor's position — and the attended value
  is that token's belief.

  This is exactly what bp_gatherAll does:
      scratch k = (state (neighbors k)).belief
-/

/-
  Weight construction for neighbor-0 attention.
  Query projects out dimension 1 (neighbor 0 index).
  Key projects out dimension 1 (own position index).
  Value projects out dimension 0 (own belief).
-/

-- Identity projection onto dimension d
noncomputable def projectDim (d : Fin D_model) :
    Fin D_model → Fin D_model → ℝ :=
  fun i j => if i = d ∧ j = d then 1 else 0

-- Wq for neighbor-0: query = embedding[1] (neighbor 0's position)
noncomputable def Wq_neighbor0 : Fin D_model → Fin D_model → ℝ :=
  projectDim ⟨1, by norm_num [D_model]⟩

-- Wk for neighbor-0: key = embedding[1] (own position)
noncomputable def Wk_neighbor0 : Fin D_model → Fin D_model → ℝ :=
  projectDim ⟨1, by norm_num [D_model]⟩

-- Wv for neighbor-0: value = embedding[0] (own belief)
noncomputable def Wv_neighbor0 : Fin D_model → Fin D_model → ℝ :=
  projectDim ⟨0, by norm_num [D_model]⟩

-- Wq for neighbor-1: query = embedding[2] (neighbor 1's position)
noncomputable def Wq_neighbor1 : Fin D_model → Fin D_model → ℝ :=
  projectDim ⟨2, by norm_num [D_model]⟩

-- Wk for neighbor-1: key = embedding[2] (own position index 2)
noncomputable def Wk_neighbor1 : Fin D_model → Fin D_model → ℝ :=
  projectDim ⟨2, by norm_num [D_model]⟩

-- Wv for neighbor-1: same as neighbor-0, extract belief
noncomputable def Wv_neighbor1 : Fin D_model → Fin D_model → ℝ :=
  projectDim ⟨0, by norm_num [D_model]⟩

/-
  Key lemma: projectDim extracts exactly one dimension.
-/

lemma projectDim_apply (d : Fin D_model) (x : Fin D_model → ℝ) :
    Fin.foldl D_model (fun acc i =>
      acc + projectDim d ⟨0, by norm_num [D_model]⟩ i * x i) 0 = 0 := by
  simp [projectDim, Fin.foldl]

lemma projectDim_extract (d : Fin D_model) (x : Fin D_model → ℝ) :
    Fin.foldl D_model (fun acc j =>
      acc + projectDim d d j * x j) 0 = x d := by
  simp [projectDim]
  induction D_model with
  | zero => exact absurd d.isLt (Nat.not_lt_zero _)
  | succ m ih => sorry -- foldl picks out exactly x d

/-
  Lemma: query for neighbor 0 equals the neighbor 0 index.
  i.e. Wq_neighbor0 * embedding = embedding[1]
-/
lemma query_neighbor0 {n : ℕ} (state : BPState n) (j : Fin n) :
    (fun d => Fin.foldl D_model (fun acc i =>
      acc + Wq_neighbor0 d i *
        (encodeBPState state j).embedding i) 0) =
    (fun d => if d = ⟨1, by norm_num [D_model]⟩
              then ((state j).neighbors ⟨0, by norm_num [K]⟩).val
              else 0) := by
  funext d
  simp [Wq_neighbor0, projectDim, encodeBPState]
  sorry -- computation: only dim 1 survives projection

/-
  Lemma: key for token k equals token k's position index.
  i.e. Wk_neighbor0 * embedding[k] = embedding[k][1] = k's position
-/
lemma key_neighbor0 {n : ℕ} (state : BPState n) (k : Fin n) :
    (fun d => Fin.foldl D_model (fun acc i =>
      acc + Wk_neighbor0 d i *
        (encodeBPState state k).embedding i) 0) =
    (fun d => if d = ⟨1, by norm_num [D_model]⟩
              then (k : ℝ)
              else 0) := by
  funext d
  simp [Wk_neighbor0, projectDim, encodeBPState]
  sorry -- computation: dim 1 of encoding is the token's own index

/-
  Lemma: attention score between query and key concentrates
  on the token whose position matches the neighbor index.
  i.e. score(j, neighbor0(j)) > score(j, k) for all k ≠ neighbor0(j)
-/
lemma attention_concentrates_neighbor0 {n : ℕ}
    (state : BPState n) (j : Fin n)
    (hInj : Function.Injective (fun k : Fin n => k.val)) :
    let nb := (state j).neighbors ⟨0, by norm_num [K]⟩
    let query := fun d => Fin.foldl D_model (fun acc i =>
      acc + Wq_neighbor0 d i *
        (encodeBPState state j).embedding i) 0
    let keys := fun k d => Fin.foldl D_model (fun acc i =>
      acc + Wk_neighbor0 d i *
        (encodeBPState state k).embedding i) 0
    ∀ k : Fin n, k ≠ nb →
      attentionScore query (keys k) < attentionScore query (keys nb) := by
  sorry -- score = nb.val^2 for k=nb, < nb.val^2 for k≠nb

/-
  Lemma: value of token k under Wv_neighbor0 is k's belief.
-/
lemma value_is_belief {n : ℕ} (state : BPState n) (k : Fin n) :
    (fun d => Fin.foldl D_model (fun acc i =>
      acc + Wv_neighbor0 d i *
        (encodeBPState state k).embedding i) 0) =
    (fun d => if d = ⟨0, by norm_num [D_model]⟩
              then (state k).belief
              else 0) := by
  funext d
  simp [Wv_neighbor0, projectDim, encodeBPState]
  sorry -- computation: dim 0 of encoding is the token's belief

/-
  Main attention lemma: with high temperature, the attention head
  with Wq_neighbor0, Wk_neighbor0, Wv_neighbor0 places the belief
  of neighbor 0 into embedding dimension 0 of token j.

  This is the exact content of bp_gatherAll for neighbor 0.
-/
lemma attention_implements_gather0 {n : ℕ}
    (state : BPState n) (j : Fin n)
    (hn : 0 < n)
    (hInj : Function.Injective (fun k : Fin n => k.val)) :
    ∃ (λ_ : ℝ),
      let after := attentionHead n (encodeBPState state)
        Wq_neighbor0 Wk_neighbor0 Wv_neighbor0 λ_
      (after j).embedding ⟨0, by norm_num [D_model]⟩ =
        (state j).embedding ⟨0, by norm_num [D_model]⟩ +
        (state ((state j).neighbors ⟨0, by norm_num [K]⟩)).belief := by
  sorry -- follows from attention_concentrates_neighbor0 + softmax_concentrates

/-
  The full gatherAll lemma: there exist weights such that after
  the attention head, token j's embedding holds its original belief
  plus the beliefs of both neighbors in the residual stream.

  This requires two attention heads (one per neighbor) or a single
  head that gathers both. With K=2 we use two separate heads.
  For simplicity we state the result for a single head gathering
  neighbor 0, and note neighbor 1 is symmetric.
-/
lemma attention_implements_gatherAll {n : ℕ}
    (state : BPState n) (j : Fin n)
    (hn : 0 < n)
    (hInj : Function.Injective (fun k : Fin n => k.val)) :
    ∃ (Wq Wk Wv : Fin D_model → Fin D_model → ℝ) (λ_ : ℝ),
      let after := attentionHead n (encodeBPState state) Wq Wk Wv λ_
      -- dim 0: original belief (residual connection preserves it)
      (after j).embedding ⟨0, by norm_num [D_model]⟩ =
        (state j).belief +
        (state ((state j).neighbors ⟨0, by norm_num [K]⟩)).belief ∧
      -- dim 4: neighbor 1's belief (separate attention head channel)
      (after j).embedding ⟨4, by norm_num [D_model]⟩ =
        (state ((state j).neighbors ⟨1, by norm_num [K]⟩)).belief := by
  sorry -- two-head construction: head 0 for neighbor 0, head 1 for neighbor 1

end TransformerBP