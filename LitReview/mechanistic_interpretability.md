# Thread 9: Mechanistic Interpretability

## Overview

Mechanistic interpretability is the empirical program of reverse-engineering
trained neural networks to find the algorithms implemented in their weights.
The core method: analyze attention patterns, weight matrices, and activations
to identify "circuits" — subgraphs of the network that implement specific
functions.

This repo is the **constructive complement** to mechanistic interpretability.

Mechanistic interpretability:  trained weights → discover algorithm
This repo:                      algorithm (BP) → construct weights → prove correctness

The two directions should converge on the same answer if the conjecture is
true that gradient descent on inference tasks learns to implement BP.

## Key Papers

### Elhage et al. (2021) — "A Mathematical Framework for Transformer Circuits"
(Anthropic)

**The foundational paper of mechanistic interpretability.**

Introduces the vocabulary:
- **Residual stream**: the sequence of token embeddings, viewed as a
  communication channel that layers read from and write to
- **Attention head as information movement**: each head moves information
  from source tokens to destination tokens
- **QK circuit**: determines which tokens attend to which (routing)
- **OV circuit**: determines what information is copied (content)
- **Virtual weights**: composition of weight matrices across layers

Key result: in one and two layer transformers, specific circuits can be
identified that implement specific functions (e.g. bigram statistics,
skip-trigrams).

**Relevance:** The QK/OV decomposition maps directly onto our construction:
- QK circuit = our Wq/Wk matrices (attention_score_gap axioms)
- OV circuit = our Wv matrix (value_belief_extract axiom)

Our proof that attention implements bp_gatherAll is a formal version of
what mechanistic interpretability does empirically for trained transformers.
We exhibit the QK and OV circuits explicitly and prove their correctness.

**Critical difference:** Elhage et al. analyze *trained* transformers and
*discover* circuits. We *construct* circuits and *prove* they implement BP.

### Olsson et al. (2022) — "In-Context Learning and Induction Heads"
(Anthropic)

**The central discovery:** A specific two-head circuit ("induction heads")
is responsible for in-context learning in transformer language models.
The circuit implements a simple algorithm: find previous occurrences of
the current token and predict what came next.

The circuit works by:
1. Head 1 (previous token head): copies token identity one position back
2. Head 2 (induction head): attends to positions where the previous token
   matches current token, copies what followed

**Relevance:** This is the closest empirical precedent to our construction.
The induction head circuit is doing something structurally similar to our
neighbor-lookup attention: using one head to establish a relationship
(token identity → position) and another head to retrieve information
(position → value).

Our construction:
- Head 0: finds neighbor 0 by matching neighbor index to token position
- Head 1: finds neighbor 1 by matching neighbor index to token position

The induction head circuit:
- Head 1: matches current token to previous occurrence
- Head 2: retrieves what followed that occurrence

Both are two-head lookup circuits. The difference: induction heads do
sequence completion, we do factor graph neighbor lookup.

**Key insight from this paper:** Simple two-head circuits suffice for
non-trivial computations. This supports the plausibility of our K=2
neighbor construction — two heads is enough for one round of BP.

### Nanda et al. (2023) — "Progress Measures for Grokking via Mechanistic Interpretability"

**The central discovery:** "Grokking" (delayed generalization) in modular
arithmetic tasks corresponds to a phase transition where the network
transitions from memorization to implementing a clean Fourier-based
algorithm in its weights.

The algorithm discovered: the network implements the formula

    cos(w(a+b)) using trig identities via specific attention and FFN circuits

**Relevance:** Two lessons for this repo:

1. **FFN as function computation**: Nanda et al. show the FFN implements
   a specific mathematical function (trig identities) in modular arithmetic.
   This supports the plausibility of our FFN sorry (294) — that an FFN
   can implement a specific mathematical function (updateBelief). The
   difference is that trig identities are piecewise-linear-approximable
   while updateBelief is a rational function, which is harder.

2. **Phase transitions in learning**: The network doesn't gradually learn
   the algorithm — it snaps into it. This suggests that if a transformer
   learns to implement BP on QBBN inference tasks, we might see a similar
   phase transition in training, which would be empirically detectable.

### Wang et al. (2022) — "Interpretability in the Wild: A Circuit for Indirect Object Identification in GPT-2"

**The central discovery:** A specific 26-head circuit in GPT-2 implements
indirect object identification (IOI) — the task of identifying "Mary" as
the indirect object in "John gave Mary the book."

The circuit involves multiple head types: duplicate token heads, S-inhibition
heads, name mover heads. Each has a specific role in the algorithm.

**Relevance:** IOI is a relational reasoning task — identifying which entity
plays which role in a proposition. This is structurally similar to QBBN
inference, which involves identifying which propositions are related by
which implication links.

The IOI circuit does something close to what our attention heads do:
- Name mover heads copy entity representations to the output position
- Our attention heads copy belief values to scratch positions

The difference: IOI circuit is reverse-engineered from a trained model.
Our construction is forward-engineered from the BP algorithm.

### Elhage et al. (2022) — "Toy Models of Superposition"
(Anthropic)

**The central discovery:** Neural networks represent more features than
they have dimensions by using superposition — multiple features share
dimensions via near-orthogonal directions.

**Relevance:** This is a potential concern for our construction. We use
8 dimensions (D_model = 8) with specific dimensions assigned to specific
quantities (dim 0 = belief, dim 1 = neighbor 0 index, etc.). This works
because we assume no superposition — each dimension has a single clean
meaning.

Trained transformers likely use superposition, which is why mechanistic
interpretability is hard. Our constructed transformer deliberately avoids
superposition by design. This is a feature of construction-based proofs:
we can choose clean representations that trained networks might not learn.

### Conmy et al. (2023) — "Towards Automated Circuit Discovery for Mechanistic Interpretability"

**The central method:** ACDC (Automated Circuit DisCovery) — an algorithm
that automatically identifies which attention heads and MLP neurons are
responsible for specific behaviors, by iteratively ablating components.

**Relevance:** This is the automation of what Elhage, Wang et al. do
manually. In principle, ACDC could be applied to a transformer trained
on QBBN inference tasks to automatically discover whether it has learned
a BP circuit similar to ours.

This would be a natural empirical complement to our formal proof:
1. Formally prove: these weights implement BP (this repo)
2. Train a transformer on QBBN inference tasks
3. Apply ACDC to discover what circuit it learned
4. Compare discovered circuit to our constructed circuit

If they match, it would be strong evidence that gradient descent finds
our construction — closing the gap between Thread 5 (constructive) and
Thread 9 (empirical).

## The Constructive vs. Reverse-Engineering Distinction

Every paper in mechanistic interpretability:
1. Takes a trained transformer with unknown weights
2. Analyzes the weights to discover what circuit is implemented
3. Gives an informal description of the circuit's algorithm
4. Validates by ablation or activation patching

This repo:
1. Takes a known algorithm (BP)
2. Constructs explicit weights that implement it
3. Proves formally (Lean 4) that the construction is correct
4. Does not depend on any trained model

The two approaches are **dual**:
- Interpretability: weights → algorithm (discovery)
- This repo: algorithm → weights (construction + proof)

They should converge: if our construction is correct and gradient descent
finds it, then applying interpretability tools to a trained QBBN-inference
transformer should recover our constructed circuits.

## The Missing Piece

Mechanistic interpretability has found circuits for:
- Sequence completion (induction heads)
- Indirect object identification
- Modular arithmetic
- Greater-than comparisons
- Docstring completion

Nobody has looked for a BP circuit in a transformer trained on a graphical
model inference task. This is the natural empirical experiment suggested
by this repo.

**The conjecture:** A transformer trained on QBBN inference tasks will
develop attention circuits that match our Wq_neighbor0/Wk_neighbor0/Wv_neighbor0
construction, and FFN circuits that implement updateBelief or a close
approximation. Verifying this empirically would be the fourth paper in
the trilogy — or the first paper of a second trilogy.