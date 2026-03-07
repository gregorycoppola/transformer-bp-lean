# Loopy Belief Propagation for Approximate Inference: An Empirical Study

**Authors:** Kevin Murphy, Yair Weiss, Michael I. Jordan
**Date:** 1999 (UAI 1999)
**Venue:** Proceedings of UAI 1999

## Claim

Loopy belief propagation (BP applied to graphs with cycles, ignoring the cycles)
converges empirically in a wide range of settings and gives good approximate
marginals, despite having no theoretical convergence guarantee in general.

## Key Results

- On error-correcting codes (turbo codes), loopy BP gives near-optimal decoding
- On Ising models and QMR-DT medical diagnosis network, loopy BP converges
  and gives reasonable approximations
- The fixed points of loopy BP, when they exist, satisfy a variational criterion
  (they are stationary points of the Bethe free energy)

## Relevance to This Repo

This is the primary citation basis for our **Empirical Convergence Thesis (ECT)**:

```lean
axiom loopy_bp_converges {n : ℕ} (state : BPState n) :
    ∃ (fixed : BPState n),
      bp_forwardPass fixed = fixed ∧
      ∃ (T : ℕ), bp_forwardPass^[T] state = fixed