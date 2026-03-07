# Comparison with Related Work

## The Landscape

Several lines of work study transformers as computational or
probabilistic objects. This document positions the trilogy relative
to the most relevant.

---

## Looped Transformers (Giannou et al. 2023)

**Their claim:** A looped transformer (one block applied repeatedly)
can simulate arbitrary programs, making transformers Turing complete
under iteration.

**Overlap with R3:** Both prove Turing completeness for transformers.
Giannou et al. use a looped single-block architecture; universal-lean
uses a 4-layer architecture. The constructions are different but the
conclusion is the same.

**Key difference:** Giannou et al. work in continuous arithmetic and
use a specific programming language (SUBROUTINES) as an intermediate.
universal-lean works directly with Boolean circuits and Turing machine
transition functions, giving a more direct construction.

**What we add:** R1 and R6. Turing completeness says the transformer
*can* compute anything. R1 says it *does* compute something specific
and useful — BP — with explicit weights. Giannou et al. do not
address inference or Bayesian computation.

---

## Transformers as In-Context Learners Doing Gradient Descent
(Akyürek et al. 2022, Von Oswald et al. 2023)

**Their claim:** Transformers implementing specific weight patterns
perform implicit gradient descent during forward passes, explaining
in-context learning as a form of online learning.

**Overlap:** Both use constructive weight proofs to show transformers
implement a specific algorithm.

**Key difference:** The algorithm is different. Gradient descent
minimizes a loss. Belief propagation computes exact posteriors.
These are related (gradient descent on a log-likelihood is connected
to BP on the corresponding graphical model) but not the same.

**What we add:** The BP construction is exact on trees (R6). Gradient
descent constructions are approximate — they converge to a minimum
but do not give correctness guarantees per step.

---

## In-Context Learning as Bayesian Inference (Xie et al. 2021)

**Their claim:** In-context learning can be understood as implicit
Bayesian inference over a latent concept hypothesis. The transformer
implicitly maintains a posterior over which concept generated the
examples.

**Overlap:** Both connect transformers to Bayesian inference.

**Key difference:** Xie et al. work at the level of the training
distribution and make a statistical argument. The connection to Bayes
is at the population level — the transformer's *expected* behavior
over training examples is Bayesian. R1 is a per-forward-pass
constructive proof — the transformer *is* computing a posterior,
with these specific weights, on this specific input.

**What we add:** A mechanistic account. Xie et al. explain *why*
transformers behave Bayesianly in aggregate. We explain *how* a
transformer could implement Bayesian inference exactly, step by step,
in a forward pass.

---

## GNNs as Belief Propagation (Scarselli et al. 2009, Yoon et al. 2019)

**Their claim:** Graph neural networks (GNNs) can be understood as
implementing belief propagation. Message passing in GNNs corresponds
to message passing in BP.

**Overlap:** Closest to our result. The BP-GNN connection is
well-established in the literature.

**Key difference:** GNNs are not transformers. GNNs have explicit
graph structure as input; transformers operate on sequences. The
challenge in R1 is showing that a *transformer* — which sees a flat
sequence of tokens with no explicit graph structure — can recover
the graph structure from the token embeddings and implement BP.

The solution (encoding neighbor indices in the embedding, using
Q/K dot products for index matching) is the key technical contribution
that GNN-BP work does not need to address.

**What we add:** The transformer result. GNN-BP is known. Transformer-BP
is new. The proof that a transformer can implement GNN-style message
passing via attention — using Q/K matching to route messages along
graph edges — is the novel piece.

---

## Mechanistic Interpretability (Elhage et al. 2021, Olah et al.)

**Their program:** Reverse-engineer the circuits learned by trained
transformers. Identify what computations specific attention heads and
FFN layers perform.

**Overlap:** Both produce mechanistic accounts of transformer computation.

**Key difference:** Mechanistic interpretability is empirical and
post-hoc — it studies trained models and infers what they are doing.
R1 is formal and constructive — it specifies weights and proves what
they do.

**Complementarity:** The BP construction gives mechanistic
interpretability a target. If trained transformers learn to do
something like BP on structured tasks, mechanistic interpretability
should find circuits resembling the BP construction: heads that
attend by index matching, value matrices that are cross-projections,
FFNs that compute log-odds combinations.

---

## Summary Table

| Work | Method | Result | Relation to Trilogy |
|------|--------|--------|-------------------|
| Giannou et al. 2023 | Constructive | Transformer Turing complete | Same conclusion as R3, different construction |
| Akyürek et al. 2022 | Constructive | Transformer implements GD | Same method as R1, different algorithm |
| Xie et al. 2021 | Statistical | ICL ≈ Bayesian inference | Statistical version of R5; we give mechanistic version |
| Scarselli et al. 2009 | Structural | GNN implements BP | R1 extends this to transformers |
| Elhage et al. 2021 | Empirical | Circuits in trained models | R1 gives a target circuit for their program |
| Pearl 1988 | Theoretical | BP exact on trees | R4 (hard-bp-lean) formalizes this; R6 combines with R1 |

---

## The Unique Position

The trilogy occupies a position none of the above works occupies:

> Formally verified, constructive proof that a transformer implements
> exact Bayesian inference, with explicit weights and a mechanistic
> account of every component.

- More specific than Giannou et al. (Bayesian inference, not arbitrary computation)
- More exact than Akyürek et al. (exact per step, not asymptotically)
- More mechanistic than Xie et al. (per forward pass, not statistical)
- More general than Scarselli et al. (transformers, not GNNs)
- More formal than Elhage et al. (proved, not reverse-engineered)
- More computational than Pearl (transformer implementation, not just algorithm)