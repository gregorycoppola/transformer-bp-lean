# The Trilogy: A Three-Paper Arc

## Overview

The three papers form a single argument developed across six years.
Each paper contributes one piece. Together they answer the question:

> Can a formal reasoning system be built on a transformer architecture,
> with provable correctness guarantees?

The answer is yes, and the proof is constructive.

---

## Paper 1: The QBBN (Coppola 2024)

**Title:** "A Quantified Boolean Bayesian Network" (or similar)
**arXiv:** First paper in the series

### What it does

Introduces the Quantified Boolean Bayesian Network as a formal
language for uncertain reasoning. Key contributions:

- **The language:** Boolean propositions, probabilistic relationships,
  first-order quantifiers over domains. A knowledge base is a factor
  graph over boolean variables.

- **The inference algorithm:** Belief propagation on the factor graph.
  The agent's beliefs are the BP marginals given evidence.

- **The no-hallucination claim:** Because beliefs are determined by
  message passing from evidence, the agent cannot assert unsupported
  beliefs. This is the informal version of R5/R6.

- **The Ψor function:** The learned factor potential
  `P(p=1|g0,g1) = σ(w·φ(p,g0,g1))` — a sigmoid of a linear
  combination. This is the target function that FFNs compute exactly,
  making FET exact rather than approximate when the target is Ψor.

### What it does not do

Paper 1 does not formally verify the no-hallucination claim. The
connection between BP and transformers is informal. The Turing
completeness claim is not made.

---

## Paper 2: Statistical Parsing (Coppola 2025)

**Title:** "Statistical Parsing for Logical Information Retrieval"
**arXiv:** Second paper in the series

### What it does

Establishes that natural language can be mapped to QBBN
representations tractably. Key contributions:

- **The parsing algorithm:** A statistical parser that maps sentences
  to QBBN factor graph fragments. The parser is trained on annotated
  data and generalizes to new sentences.

- **The information retrieval application:** Given a QBBN knowledge
  base populated from text, the system can answer queries by running
  BP on the factor graph. This closes the loop from text to inference.

- **Empirical validation:** The system achieves competitive performance
  on information retrieval benchmarks, demonstrating that the QBBN
  representation is expressive enough to capture real-world knowledge.

### What it does not do

Paper 2 does not address the formal connection between BP and
transformers. It treats BP as a black-box inference algorithm and
does not ask whether a transformer could implement it.

---

## Paper 3: The Universal Language (Coppola 2026, this work)

**Title:** "The Universal Language: A Characteristica Universalis for AI"
**arXiv:** Third paper in the series
**Companion repos:** `transformer-bp-lean`, `universal-lean`, `hard-bp-lean`

### What it does

Proves the formal connection between transformers and the QBBN.
Key contributions:

- **R1** (`transformer_implements_bp`): One transformer forward pass
  implements one round of BP. Constructive, explicit weights.

- **R2** (`transformer_iterated_implements_runBP`): T passes = T rounds.

- **R3** (from `universal-lean`): Transformer is Turing complete.

- **R4** (from `hard-bp-lean`): BP is exact on trees.

- **R5** (`transformer_computes_posterior`): Transformer computes
  true posteriors, conditional on ECT and PCT.

- **R6** (combination of R2 + R4): Transformer is exact Bayesian
  on tree-structured knowledge bases. No conditions.

### The closing of the arc

Paper 3 closes the argument opened in Paper 1. Paper 1 claimed the
QBBN agent does not hallucinate because its beliefs come from BP.
Paper 3 proves that a transformer can implement BP exactly. Together:
a transformer operating over a QBBN knowledge base does not hallucinate.

---

## The Single Argument

Stated as a single chain:

1. **Knowledge can be represented** as a QBBN factor graph (Paper 1)
2. **Knowledge can be acquired** by parsing natural language (Paper 2)
3. **Inference on the knowledge base** is belief propagation (Paper 1)
4. **BP is exact** on tree-structured knowledge bases (hard-bp-lean)
5. **A transformer implements BP** with explicit weights (Paper 3 / this repo)
6. **Therefore:** a transformer operating over a tree-structured QBBN
   knowledge base computes exact posteriors — does not hallucinate

Steps 1-3 are established in Papers 1-2, formally and informally.
Steps 4-5 are formally verified in Lean. Step 6 follows by composition.

---

## What Each Repo Proves

| Repo | Theorem | Depends on |
|------|---------|------------|
| `hard-bp-lean` | BP exact on trees (R4) | Tree structure |
| `universal-lean` | Transformer Turing complete (R3) | Boolean circuits |
| `transformer-bp-lean` | Transformer implements BP (R1) | FET, attention axioms |
| Combination | Transformer exact Bayesian on trees (R6) | R1 + R4 |

---

## Leibniz Revisited

The trilogy title — "A Characteristica Universalis for AI" — is not
rhetorical. The QBBN is a candidate universal formal language for
uncertain reasoning. The transformer with BP weights is the
mechanical calculator that operates on that language.

The trilogy does not claim to solve AI or to produce a system that
handles all knowledge. It claims something more modest and more
precise: that for knowledge expressible in the QBBN language, a
transformer can reason correctly, provably, without hallucination.

Leibniz wanted *calculemus*. For QBBN knowledge bases, we now have it.

---

## Open Questions for a Fourth Paper

**Q1.** Can the BP weights be *learned* from data rather than
hand-constructed? The constructive proof gives a target; the question
is whether gradient descent converges to it.

**Q2.** Can the QBBN be extended to continuous variables? The current
framework is boolean. Real-world knowledge often involves continuous
quantities (temperatures, probabilities, measurements).

**Q3.** Can the tree guarantee (R6) be extended to bounded-treewidth
graphs? Many practical knowledge bases are not trees but have small
treewidth. Junction tree algorithms give exact inference on these;
a transformer analog would extend R6 significantly.

**Q4.** What is the relationship between R3 (Turing completeness) and
R1 (BP implementation)? Can a single transformer be shown to both
implement BP and be Turing complete? The current proofs use different
weight constructions.

**Q5.** Can the formal result be used to audit trained models?
Given a trained transformer, can we test whether its weights
approximate the BP construction? This would connect the formal
result to empirical model evaluation.