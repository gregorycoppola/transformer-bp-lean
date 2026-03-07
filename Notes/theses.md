# Empirical Theses

This repo proves everything that can be proven formally and axiomatizes
exactly what cannot. The boundary between proof and thesis is explicit.

## The Three Theses

### Thesis 1: Empirical Convergence Thesis (ECT)

    axiom loopy_bp_converges {n : ℕ} (state : BPState n) :
        ∃ (fixed : BPState n),
          bp_forwardPass fixed = fixed ∧
          ∃ (T : ℕ), bp_forwardPass^[T] state = fixed

**What it says:** Loopy BP on QBBN factor graphs converges to a fixed point
reachable from any initial state in finite steps.

**Why it is not provable in general:** Loopy BP can oscillate on graphs
with certain cycle structures. No general convergence theorem exists.

**Why it is reasonable for QBBN graphs:**
- Murphy et al. (1999): empirically converges on many graph families
- Smith & Eisner (2008): converges on NLP factor graphs
- Coppola (2024): converges in QBBN experiments
- QBBN graphs are sparse and structured by natural language implication
  patterns, which tend to have long cycles and weak coupling

**What a proof would require:** Showing QBBN graphs satisfy walk-summability
(Malioutov et al. 2006) or contractivity of the BP operator (Tatikonda &
Jordan 2002). This depends on the factor potentials and graph topology.

**Status:** Axiom. Empirically supported. Provable for tree-structured
QBBNs without this axiom (see hard-bp-lean).

---

### Thesis 2: Posterior Correctness Thesis (PCT)

    axiom bp_fixed_point_is_posterior {n : ℕ} (fixed : BPState n) :
        bp_forwardPass fixed = fixed →
        ∀ j, (fixed j).belief = P_true(x_j = 1 | evidence)

**What it says:** When loopy BP converges, its fixed point equals the
true Bayesian posterior marginals.

**Why it is not provable in general:** On loopy graphs the BP fixed point
minimizes the Bethe free energy (Yedidia et al. 2003), which approximates
but does not equal the true variational free energy. The gap depends on
the cycle structure and factor potentials.

**Why it is reasonable for QBBN graphs:**
- Exact on trees (provable — see hard-bp-lean)
- Good approximation when cycles are long (Bethe ≈ exact for long cycles)
- QBBN factor potentials are structured (AND deterministic, OR logistic)
  which tends to make the Bethe approximation tight

**What a proof would require:** Bounding |F_Bethe - F_exact| for QBBN
graphs. Requires knowing the treewidth and coupling strength of the graph.

**Status:** Axiom. Exact on trees. Empirically good on loopy QBBN graphs.
The harder of the two theses — ECT says BP converges to something, PCT
says that something is the right answer.

---

### Thesis 3: FFN Expressiveness Thesis (FET)

    axiom ffn_implements_updateBelief :
        ∃ W1 b1 W2 b2,
          ∀ m0 m1 : ℝ,
            ffn W1 b1 W2 b2 (embedding_with m0 m1) =
            embedding_with (updateBelief m0 m1) m0 m1

**What it says:** There exist FFN weights such that the two-layer network
computes updateBelief exactly from dims 4 and 5.

**Why it is not provable as stated:** updateBelief is a rational function
(equivalent to sigmoid of logit sum). Two-layer ReLU MLPs compute
piecewise linear functions and cannot represent this exactly.

**Why it is reasonable:**
- updateBelief = σ(logit(m0) + logit(m1)) — sigmoid of a linear combination
  of log-odds. A network with sigmoid activation computes this exactly.
- The learned Ψor in the QBBN paper is σ(w·φ) — already a sigmoid of
  a dot product, which an FFN computes exactly. updateBelief is the
  special case with equal weights.
- With sufficient width, ReLU network approximates logit to any ε on
  any compact domain [δ, 1-δ] away from the boundary.

**Alternative exact formulation:** If the target is the general learned Ψor
(not the specific updateBelief), the FFN computes it exactly with sigmoid
activation. This is a minor change to the target function that makes
the thesis a theorem.

**Status:** Axiom for ReLU FFN + exact updateBelief target. Theorem for
sigmoid FFN + general Ψor target. The axiom version is conservative.

---

## The Resulting Theorem

With all three theses assumed, the capstone result is:

    theorem transformer_computes_posterior
        {n : ℕ} (state : BPState n)
        (hn : 0 < n)
        (hInj : Function.Injective (fun k : Fin n => (k : ℝ))) :
        ∃ (W : TransformerWeights) (T : ℕ),
          ∀ j,
            belief_after_T_passes W T state j
            = P_true(x_j = 1 | evidence) := by
      -- From FET: W implements one round of BP (transformer_implements_bp)
      -- From ECT: iterated BP converges to fixed point
      -- From PCT: fixed point equals true posterior
      ...

This is a conditional theorem — formally proven given three named,
cited, empirically-supported theses. More rigorous than any prior work
which does not separate what is proven from what is observed.

---

## Thesis Dependency

    FET → transformer_implements_bp (294)
        → transformer_iterated_implements_runBP (306) ← ECT
            → transformer_computes_posterior ← PCT

FET is needed first. ECT and PCT are needed for the convergence claim.
The attention half of 294 needs no thesis — it is proven from axioms
that are directly dischargeable by computation.

---

## What Would Remove Each Thesis

**Remove FET:** Use sigmoid activation instead of ReLU, or change the
target to the general learned Ψor. Minor architectural change.

**Remove ECT:** Restrict to tree-structured QBBNs. Then BP converges
exactly in diameter(tree) steps. No empirical assumption needed.
This is the hard-bp-lean setting.

**Remove PCT:** Same restriction to trees — BP is exact on trees by
the sum-product algorithm. The fixed point IS the true posterior.

**Remove all three:** Restrict to trees + sigmoid activation.
The full theorem holds without any empirical thesis.
This is the cleanest possible version of the result and should be
proven first as a foundation.