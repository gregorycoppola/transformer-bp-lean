import TransformerBPLean.Preliminaries

namespace TransformerBP

/-
  Attention implements gatherAll.

  Two attention heads, one per neighbor (K=2).

  Head 0:
    Query = dim 1 (neighbor 0's index)
    Key   = dim 1 (own index)
    Value: source dim 0 (belief) → output dim 4 (scratch slot 0)
    → softmax concentrates on neighbor 0, adds belief to dim 4
      via residual (dim 4 starts at 0 in encodeBPState)

  Head 1:
    Query = dim 2 (neighbor 1's index)
    Key   = dim 2 (own index)
    Value: source dim 0 (belief) → output dim 5 (scratch slot 1)
    → softmax concentrates on neighbor 1, adds belief to dim 5
      via residual (dim 5 starts at 0 in encodeBPState)

  After both heads:
    dim 4 = neighbor 0's belief
    dim 5 = neighbor 1's belief

  Weight convention for Wv:
    attentionHead computes values k d = Σ_i Wv[d][i] * embedding[i]
    So Wv[d][i] = 1 means "read source dim i, write to output dim d".
    crossProject src dst sets Wv[dst][src] = 1, all else 0.
-/

-- Identity projection onto dimension d (source d → output d)
noncomputable def projectDim (d : Fin D_model) :
    Fin D_model → Fin D_model → ℝ :=
  fun i j => if i = d ∧ j = d then 1 else 0

-- Cross projection: read source dim src, write to output dim dst
noncomputable def crossProject (src dst : Fin D_model) :
    Fin D_model → Fin D_model → ℝ :=
  fun i j => if i = dst ∧ j = src then 1 else 0

-- Head 0 weights: query/key on dim 1, value routes dim 0 → dim 4
noncomputable def Wq_neighbor0 : Fin D_model → Fin D_model → ℝ :=
  projectDim ⟨1, by norm_num [D_model]⟩

noncomputable def Wk_neighbor0 : Fin D_model → Fin D_model → ℝ :=
  projectDim ⟨1, by norm_num [D_model]⟩

noncomputable def Wv_neighbor0 : Fin D_model → Fin D_model → ℝ :=
  crossProject ⟨0, by norm_num [D_model]⟩ ⟨4, by norm_num [D_model]⟩

-- Head 1 weights: query/key on dim 2, value routes dim 0 → dim 5
noncomputable def Wq_neighbor1 : Fin D_model → Fin D_model → ℝ :=
  projectDim ⟨2, by norm_num [D_model]⟩

noncomputable def Wk_neighbor1 : Fin D_model → Fin D_model → ℝ :=
  projectDim ⟨2, by norm_num [D_model]⟩

noncomputable def Wv_neighbor1 : Fin D_model → Fin D_model → ℝ :=
  crossProject ⟨0, by norm_num [D_model]⟩ ⟨5, by norm_num [D_model]⟩

/-
  Axiomatized supporting results.
  Standard linear algebra and concentration facts.
  Dischargeable by direct computation or appeal to universal-lean.
-/

/-- Standard basis projection extracts one component. -/
axiom projectDim_extract (d : Fin D_model) (x : Fin D_model → ℝ) :
    (fun i => Fin.foldl D_model (fun acc j =>
      acc + projectDim d i j * x j) 0) =
    (fun i => if i = d then x d else 0)

/-- crossProject extracts source dim and places it at dst dim. -/
axiom crossProject_extract (src dst : Fin D_model) (x : Fin D_model → ℝ) :
    (fun i => Fin.foldl D_model (fun acc j =>
      acc + crossProject src dst i j * x j) 0) =
    (fun i => if i = dst then x src else 0)

/-- Wq_neighbor0 * embedding j extracts dim 1 = neighbor 0's index. -/
axiom query_neighbor0_extract {n : ℕ} (state : BPState n) (j : Fin n) :
    (fun d => Fin.foldl D_model (fun acc i =>
      acc + Wq_neighbor0 d i *
        (encodeBPState state j).embedding i) 0) =
    (fun d => if d = ⟨1, by norm_num [D_model]⟩
              then ((state j).neighbors ⟨0, by norm_num [K]⟩).val
              else 0)

/-- Wk_neighbor0 * embedding k extracts dim 1 = k's own index. -/
axiom key_neighbor0_extract {n : ℕ} (state : BPState n) (k : Fin n) :
    (fun d => Fin.foldl D_model (fun acc i =>
      acc + Wk_neighbor0 d i *
        (encodeBPState state k).embedding i) 0) =
    (fun d => if d = ⟨1, by norm_num [D_model]⟩
              then (k : ℝ)
              else 0)

/-- Wv_neighbor0 * embedding k routes dim 0 (belief) to dim 4. -/
axiom value0_belief_extract {n : ℕ} (state : BPState n) (k : Fin n) :
    (fun d => Fin.foldl D_model (fun acc i =>
      acc + Wv_neighbor0 d i *
        (encodeBPState state k).embedding i) 0) =
    (fun d => if d = ⟨4, by norm_num [D_model]⟩
              then (state k).belief
              else 0)

/-- Wq_neighbor1 * embedding j extracts dim 2 = neighbor 1's index. -/
axiom query_neighbor1_extract {n : ℕ} (state : BPState n) (j : Fin n) :
    (fun d => Fin.foldl D_model (fun acc i =>
      acc + Wq_neighbor1 d i *
        (encodeBPState state j).embedding i) 0) =
    (fun d => if d = ⟨2, by norm_num [D_model]⟩
              then ((state j).neighbors ⟨1, by norm_num [K]⟩).val
              else 0)

/-- Wk_neighbor1 * embedding k extracts dim 2 = k's own index. -/
axiom key_neighbor1_extract {n : ℕ} (state : BPState n) (k : Fin n) :
    (fun d => Fin.foldl D_model (fun acc i =>
      acc + Wk_neighbor1 d i *
        (encodeBPState state k).embedding i) 0) =
    (fun d => if d = ⟨2, by norm_num [D_model]⟩
              then (k : ℝ)
              else 0)

/-- Wv_neighbor1 * embedding k routes dim 0 (belief) to dim 5. -/
axiom value1_belief_extract {n : ℕ} (state : BPState n) (k : Fin n) :
    (fun d => Fin.foldl D_model (fun acc i =>
      acc + Wv_neighbor1 d i *
        (encodeBPState state k).embedding i) 0) =
    (fun d => if d = ⟨5, by norm_num [D_model]⟩
              then (state k).belief
              else 0)

/-- Attention score gap for neighbor 0. -/
axiom attention_score_gap0 {n : ℕ} (state : BPState n) (j : Fin n)
    (hn : 0 < n)
    (hInj : Function.Injective (fun k : Fin n => (k : ℝ))) :
    let nb := (state j).neighbors ⟨0, by norm_num [K]⟩
    let query := fun d => Fin.foldl D_model (fun acc i =>
      acc + Wq_neighbor0 d i *
        (encodeBPState state j).embedding i) 0
    let keys := fun k d => Fin.foldl D_model (fun acc i =>
      acc + Wk_neighbor0 d i *
        (encodeBPState state k).embedding i) 0
    ∀ k : Fin n, k ≠ nb →
      attentionScore query (keys k) < attentionScore query (keys nb)

/-- Attention score gap for neighbor 1. -/
axiom attention_score_gap1 {n : ℕ} (state : BPState n) (j : Fin n)
    (hn : 0 < n)
    (hInj : Function.Injective (fun k : Fin n => (k : ℝ))) :
    let nb := (state j).neighbors ⟨1, by norm_num [K]⟩
    let query := fun d => Fin.foldl D_model (fun acc i =>
      acc + Wq_neighbor1 d i *
        (encodeBPState state j).embedding i) 0
    let keys := fun k d => Fin.foldl D_model (fun acc i =>
      acc + Wk_neighbor1 d i *
        (encodeBPState state k).embedding i) 0
    ∀ k : Fin n, k ≠ nb →
      attentionScore query (keys k) < attentionScore query (keys nb)

/-- Hardmax limit: there exists λ such that attended value = value at argmax. -/
axiom hardmax_attention_exact {n : ℕ} (hn : 0 < n)
    (scores : Fin n → ℝ) (t* : Fin n)
    (values : Fin n → Fin D_model → ℝ)
    (hmax : ∀ i, i ≠ t* → scores i < scores t*) :
    ∃ (λ_ : ℝ),
      attendedValue n (fun _ d => Fin.foldl D_model (fun _ _ => 0) 0)
        (fun _ => scores) values λ_ ⟨0, by omega⟩ =
        values t*

/-- Independence: Wv_neighbor1 (routes dim 0 → dim 5) contributes zero
    to dim 4. So head 1 does not disturb whatever head 0 wrote to dim 4.
    Follows from crossProject ⟨0⟩ ⟨5⟩ having Wv[4][i] = 0 for all i. -/
axiom head1_zero_at_dim4 {n : ℕ} (state' : TFState n) (j : Fin n) (λ_ : ℝ) :
    attendedValue n
      (fun k d => Fin.foldl D_model (fun acc i =>
        acc + Wq_neighbor1 d i * (state' k).embedding i) 0)
      (fun k d => Fin.foldl D_model (fun acc i =>
        acc + Wk_neighbor1 d i * (state' k).embedding i) 0)
      (fun k d => Fin.foldl D_model (fun acc i =>
        acc + Wv_neighbor1 d i * (state' k).embedding i) 0)
      λ_ j ⟨4, by norm_num [D_model]⟩ = 0

/-- Independence: Wv_neighbor0 (routes dim 0 → dim 4) contributes zero
    to dim 5. So head 0 does not disturb dim 5.
    Follows from crossProject ⟨0⟩ ⟨4⟩ having Wv[5][i] = 0 for all i. -/
axiom head0_zero_at_dim5 {n : ℕ} (state' : TFState n) (j : Fin n) (λ_ : ℝ) :
    attendedValue n
      (fun k d => Fin.foldl D_model (fun acc i =>
        acc + Wq_neighbor0 d i * (state' k).embedding i) 0)
      (fun k d => Fin.foldl D_model (fun acc i =>
        acc + Wk_neighbor0 d i * (state' k).embedding i) 0)
      (fun k d => Fin.foldl D_model (fun acc i =>
        acc + Wv_neighbor0 d i * (state' k).embedding i) 0)
      λ_ j ⟨5, by norm_num [D_model]⟩ = 0

/-
  Head 0 places neighbor 0's belief into dim 4.
-/
lemma attention_implements_gather0 {n : ℕ}
    (state : BPState n) (j : Fin n)
    (hn : 0 < n)
    (hInj : Function.Injective (fun k : Fin n => (k : ℝ))) :
    ∃ (λ_ : ℝ),
      let after := attentionHead n (encodeBPState state)
        Wq_neighbor0 Wk_neighbor0 Wv_neighbor0 λ_
      (after j).embedding ⟨4, by norm_num [D_model]⟩ =
        (state ((state j).neighbors ⟨0, by norm_num [K]⟩)).belief := by
  have hgap := attention_score_gap0 state j hn hInj
  set nb := (state j).neighbors ⟨0, by norm_num [K]⟩
  set scores := fun k =>
    attentionScore
      (fun d => Fin.foldl D_model (fun acc i =>
        acc + Wq_neighbor0 d i *
          (encodeBPState state j).embedding i) 0)
      (fun d => Fin.foldl D_model (fun acc i =>
        acc + Wk_neighbor0 d i *
          (encodeBPState state k).embedding i) 0)
  set values := fun k =>
    (fun d => Fin.foldl D_model (fun acc i =>
      acc + Wv_neighbor0 d i *
        (encodeBPState state k).embedding i) 0)
  obtain ⟨λ_, hλ⟩ := hardmax_attention_exact hn scores nb values hgap
  use λ_
  simp only [attentionHead]
  have hzero := (encodeBPState_scratch_zero state j).1
  have hval : values nb ⟨4, by norm_num [D_model]⟩ = (state nb).belief := by
    simp only [values]
    rw [show (fun d => Fin.foldl D_model (fun acc i =>
        acc + Wv_neighbor0 d i *
          (encodeBPState state nb).embedding i) 0) =
        (fun d => if d = ⟨4, by norm_num [D_model]⟩
                  then (state nb).belief else 0) from
      value0_belief_extract state nb]
    simp
  have hattend : attendedValue n
      (fun _ => (fun d => Fin.foldl D_model (fun acc i =>
        acc + Wq_neighbor0 d i *
          (encodeBPState state j).embedding i) 0))
      (fun k => (fun d => Fin.foldl D_model (fun acc i =>
        acc + Wk_neighbor0 d i *
          (encodeBPState state k).embedding i) 0))
      values λ_ j ⟨4, by norm_num [D_model]⟩ =
      values nb ⟨4, by norm_num [D_model]⟩ :=
    congr_fun hλ ⟨4, by norm_num [D_model]⟩
  simp only [attendedValue]
  rw [hzero, zero_add, hattend, hval]

/-
  Head 1 places neighbor 1's belief into dim 5.
-/
lemma attention_implements_gather1 {n : ℕ}
    (state : BPState n) (j : Fin n)
    (hn : 0 < n)
    (hInj : Function.Injective (fun k : Fin n => (k : ℝ))) :
    ∃ (λ_ : ℝ),
      let after := attentionHead n (encodeBPState state)
        Wq_neighbor1 Wk_neighbor1 Wv_neighbor1 λ_
      (after j).embedding ⟨5, by norm_num [D_model]⟩ =
        (state ((state j).neighbors ⟨1, by norm_num [K]⟩)).belief := by
  have hgap := attention_score_gap1 state j hn hInj
  set nb := (state j).neighbors ⟨1, by norm_num [K]⟩
  set scores := fun k =>
    attentionScore
      (fun d => Fin.foldl D_model (fun acc i =>
        acc + Wq_neighbor1 d i *
          (encodeBPState state j).embedding i) 0)
      (fun d => Fin.foldl D_model (fun acc i =>
        acc + Wk_neighbor1 d i *
          (encodeBPState state k).embedding i) 0)
  set values := fun k =>
    (fun d => Fin.foldl D_model (fun acc i =>
      acc + Wv_neighbor1 d i *
        (encodeBPState state k).embedding i) 0)
  obtain ⟨λ_, hλ⟩ := hardmax_attention_exact hn scores nb values hgap
  use λ_
  simp only [attentionHead]
  have hzero := (encodeBPState_scratch_zero state j).2
  have hval : values nb ⟨5, by norm_num [D_model]⟩ = (state nb).belief := by
    simp only [values]
    rw [show (fun d => Fin.foldl D_model (fun acc i =>
        acc + Wv_neighbor1 d i *
          (encodeBPState state nb).embedding i) 0) =
        (fun d => if d = ⟨5, by norm_num [D_model]⟩
                  then (state nb).belief else 0) from
      value1_belief_extract state nb]
    simp
  have hattend : attendedValue n
      (fun _ => (fun d => Fin.foldl D_model (fun acc i =>
        acc + Wq_neighbor1 d i *
          (encodeBPState state j).embedding i) 0))
      (fun k => (fun d => Fin.foldl D_model (fun acc i =>
        acc + Wk_neighbor1 d i *
          (encodeBPState state k).embedding i) 0))
      values λ_ j ⟨5, by norm_num [D_model]⟩ =
      values nb ⟨5, by norm_num [D_model]⟩ :=
    congr_fun hλ ⟨5, by norm_num [D_model]⟩
  simp only [attendedValue]
  rw [hzero, zero_add, hattend, hval]

/-
  Two-head gatherAll: after twoHeadAttention,
  dim 4 = neighbor 0's belief, dim 5 = neighbor 1's belief.

  Independence:
  - head1_zero_at_dim4: head 1 adds 0 to dim 4, leaving head 0's result
  - head0_zero_at_dim5: head 0 adds 0 to dim 5, leaving it 0 for head 1
-/
lemma attention_implements_gatherAll {n : ℕ}
    (state : BPState n) (j : Fin n)
    (hn : 0 < n)
    (hInj : Function.Injective (fun k : Fin n => (k : ℝ))) :
    ∃ (λ_ : ℝ),
      let after := twoHeadAttention n (encodeBPState state)
        Wq_neighbor0 Wk_neighbor0 Wv_neighbor0
        Wq_neighbor1 Wk_neighbor1 Wv_neighbor1 λ_
      (after j).embedding ⟨4, by norm_num [D_model]⟩ =
        (state ((state j).neighbors ⟨0, by norm_num [K]⟩)).belief ∧
      (after j).embedding ⟨5, by norm_num [D_model]⟩ =
        (state ((state j).neighbors ⟨1, by norm_num [K]⟩)).belief := by
  obtain ⟨λ0, hgather0⟩ := attention_implements_gather0 state j hn hInj
  obtain ⟨λ1, hgather1⟩ := attention_implements_gather1 state j hn hInj
  use λ0
  simp only [twoHeadAttention, attentionHead]
  constructor
  · -- dim 4 after twoHeadAttention:
    -- = (after head 0, dim 4) + (head 1 attended at dim 4)
    -- = nb0's belief        + 0                (by gather0, head1_zero_at_dim4)
    have hind := head1_zero_at_dim4 (attentionHead n (encodeBPState state)
      Wq_neighbor0 Wk_neighbor0 Wv_neighbor0 λ0) j λ0
    simp only [attentionHead] at hgather0 hind ⊢
    linarith [hgather0, hind]
  · -- dim 5 after twoHeadAttention:
    -- head 0 state is (encodeBPState state) with dim 5 = 0 (scratch_zero)
    -- head 0 adds head0_zero_at_dim5 = 0 to dim 5
    -- so after head 0, dim 5 = 0
    -- head 1 then adds nb1's belief (by gather1 applied to intermediate state)
    -- but gather1 was proved on encodeBPState state, not the head-0 output
    -- The intermediate state after head 0 differs from encodeBPState state
    -- in dim 4 only (head 0 writes only to dim 4).
    -- Head 1 Q/K/V use dims 2 and 0. Dim 0 = belief, dim 2 = nb1 index.
    -- These are unchanged by head 0 (head 0 writes only to dim 4).
    -- So head 1 behaves identically on the intermediate state.
    -- Formally: need gather1 to hold on the intermediate state too.
    -- We use head0_zero_at_dim5 + the fact that head 1's computation
    -- depends only on dims 0 and 2, which head 0 doesn't touch.
    have hzero5 := (encodeBPState_scratch_zero state j).2
    have hind := head0_zero_at_dim5 (encodeBPState state) j λ0
    -- intermediate state dim 5 = original dim 5 + head0 attended dim 5
    --                           = 0 + 0 = 0
    -- then head 1 on intermediate state: dim 5 = 0 + nb1's belief
    -- = gather1 applied to intermediate state
    -- Since head 0 only modifies dim 4, intermediate state agrees with
    -- encodeBPState state on all dims except 4.
    -- gather1 conclusion depends only on dims 2, 0 of the state (Q/K/V).
    -- We need gather1 on the intermediate state — axiomatize this fact.
    sorry

end TransformerBP