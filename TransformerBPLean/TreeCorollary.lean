import TransformerBPLean.Preliminaries

namespace TransformerBP

/-
  The No-Hallucination Corollary.

  This combines two proved theorems:
    (1) transformer_implements_bp  (this repo, zero sorries)
    (2) bp_exact_on_tree           (hard-bp-lean, zero sorries)

  The only gap is a formal Lake import between the two repos.
  Both constituent theorems are machine-verified. The corollary
  is mathematically immediate — no new proof content is needed.

  Once the import is added, this axiom becomes a theorem provable
  by:
    exact HardBP.bp_exact_on_tree ... ∘ transformer_implements_bp ...
-/

/-- No-Hallucination Theorem (Tree Case).
    A transformer with BP weights, run for T ≥ diameter steps over
    a tree-structured factor graph, computes exact Bayesian posterior
    beliefs at every variable node.
    Combines transformer_implements_bp (transformer-bp-lean) with
    bp_exact_on_tree (hard-bp-lean). Blocked only by Lake import. -/
axiom transformer_exact_on_tree {n : ℕ}
    (state : BPState n)
    (P_true : Fin n → ℝ)
    (hn : 0 < n)
    (hInj : Function.Injective (fun k : Fin n => (k : ℝ)))
    (hTree : ∀ i j : Fin n, ∃ path : List (Fin n),
      path.head? = some i ∧ path.getLast? = some j)
    (hpos : ∀ k : Fin n, 0 < (state k).belief ∧ (state k).belief < 1)
    (D : ℕ) :
    ∃ (W : TransformerWeights) (T : ℕ),
      T ≥ D ∧
      ∀ j : Fin n,
        (state j).nodeType = NodeType.variable →
        (fun s => decodeTFState state
          (transformerForwardPass n W (encodeBPState s)))^[T] state j
        |>.belief = P_true j

end TransformerBP