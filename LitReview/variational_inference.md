# Thread 6: Variational Inference, Free Energy, and BP Fixed Points

## Overview

The question of whether loopy BP converges, and whether its fixed point
equals the true posterior, has a precise theoretical answer in terms of
variational inference and the Bethe free energy. This thread provides
the mathematical foundation for both of our empirical theses (ECT and PCT).

Understanding this thread clarifies exactly what we are axiomatizing and
what a proof of PCT would require.

## Key Papers

### Wainwright & Jordan (2008) — "Graphical Models, Exponential Families, and Variational Inference"

**The central result:** Exact inference in a graphical model is equivalent
to optimizing the exact variational free energy:

    F(q) = E_q[log P(x)] - H(q)

over all distributions q. The true posterior minimizes F.

Loopy BP is equivalent to optimizing the **Bethe free energy** F_Bethe,
which approximates F by assuming pairwise correlations capture all
dependencies (the Bethe approximation).

**Relevance to PCT:** Our Posterior Correctness Thesis axiom says:

    BP fixed point ≈ true posterior

The Wainwright-Jordan result gives this a precise meaning: the BP fixed
point minimizes F_Bethe, which approximates the true variational free energy.
The approximation is exact on trees (where Bethe = exact) and approximate
on loopy graphs (where Bethe ≠ exact).

A formal proof of PCT would require bounding |F_Bethe - F| for QBBN graphs,
which depends on the graph structure (cycle lengths, factor potentials, etc.).

### Yedidia, Freeman & Weiss (2003) — "Understanding Belief Propagation and Its Generalizations"

**The central result:** The fixed points of loopy BP are exactly the
stationary points of the Bethe free energy. This gives loopy BP a
variational interpretation even when the graph has cycles.

**Key insight:** On a tree, F_Bethe = F exactly, so BP fixed points are
true posterior marginals. On a loopy graph, F_Bethe ≠ F, but the Bethe
approximation is often good.

**Relevance:** This is the theoretical basis for treating our PCT thesis
as reasonable. It tells us *why* loopy BP gives good approximations —
not because it's doing something arbitrary, but because it's optimizing
a well-defined approximation to the true variational objective.

**Also relevant to ECT:** Not all stationary points of F_Bethe are
minima — some are saddle points or maxima. This is why convergence is
not guaranteed: BP might oscillate rather than settle at a stationary point.

### Heskes (2003) — "Stable Fixed Points of Loopy Belief Propagation Are Minima of the Bethe Free Energy"

**The central result:** When loopy BP does converge, its fixed point is
a local minimum of F_Bethe (not just a stationary point). This gives
converged BP solutions a stability interpretation.

**Relevance to ECT:** Helps clarify what convergence means — not just
"BP stops changing" but "BP reaches a stable local minimum of a
well-defined energy function." This makes ECT more precise:

```lean
axiom loopy_bp_converges {n : ℕ} (state : BPState n) :
    ∃ (fixed : BPState n),
      bp_forwardPass fixed = fixed ∧
      isLocalMinimumBethe fixed ∧  -- Heskes' condition
      ∃ (T : ℕ), bp_forwardPass^[T] state = fixed