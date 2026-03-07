# Thread 2: Graph Neural Networks as Belief Propagation

## Overview

Graph Neural Networks (GNNs) are widely understood to implement a form of
belief propagation — nodes aggregate messages from neighbors, update their
state, repeat. The Message Passing Neural Network (MPNN) framework makes this
explicit. However the connection is informal: GNNs are *inspired by* BP but
do not formally *implement* BP.

This repo makes the connection formal for the transformer case.

## Key Papers

### Pearl (1988) — Probabilistic Reasoning in Intelligent Systems

The original BP algorithm. Defines the π and λ message passing equations
used in the QBBN paper and implemented in this repo's `bp_forwardPass`.

The factor graph formulation (Kschischang et al. 2001) is the cleaner version:
variable nodes and factor nodes alternate, passing messages along edges.
This is exactly the QBBN bipartite structure (AND nodes / OR nodes).

### Gilmer et al. (2017) — Neural Message Passing for Quantum Chemistry

Introduced the MPNN framework unifying most GNN architectures:

    m_t+1_v = sum_{w in N(v)} M_t(h_t_v, h_t_w, e_vw)
    h_t+1_v = U_t(h_t_v, m_t+1_v)

where h is node state, M is message function, U is update function, e is
edge features. One MPNN step = one round of synchronous message passing.

Relevance: our `bp_forwardPass` is exactly one MPNN step where:
- M is the identity (message = neighbor's belief)
- U is updateBelief
- The graph structure is the QBBN factor graph

Our transformer implements one MPNN step, not just approximately but provably.

### Yedidia, Freeman & Weiss (2003) — "Understanding Belief Propagation and Its Generalizations"

Shows that the fixed points of loopy BP are stationary points of the Bethe
free energy — a variational approximation to the true log partition function.
This is the theoretical basis for why loopy BP gives good approximations even
without convergence guarantees.

Relevance: provides theoretical grounding for our PCT (Posterior Correctness
Thesis) axiom. The Bethe free energy argument is why the BP fixed point is a
reasonable approximation to the true posterior on loopy graphs.

### Xu et al. (2019) — "How Powerful Are Graph Neural Networks?"

Shows that GNNs are at most as powerful as the Weisfeiler-Lehman graph
isomorphism test — they cannot distinguish certain graph structures.
The limitation comes from using sum/mean aggregation which loses structural info.

Relevance: our attention-based neighbor lookup sidesteps this limitation.
Instead of summing over all neighbors, we route to specific neighbors by index.
This is why positional encoding (dims 1,2 carrying neighbor indices) is
essential to our construction — it gives us more than WL-equivalent power.

### Satorras & Welling (2021) — "Neural Enhanced Belief Propagation on Factor Graphs"

Augments BP with neural networks that learn to correct BP's approximation
errors on loopy graphs. The neural correction is trained to push loopy BP
toward the true posterior.

Relevance: this is the learned version of our PCT thesis — they train a
network to make loopy BP exact. Our repo axiomatizes the result they try to
achieve through training (that the fixed point approximates the true posterior).

### Kschischang, Frey & Loeliger (2001) — "Factor Graphs and the Sum-Product Algorithm"

Defines the factor graph formalism and the sum-product (BP) algorithm in the
clean bipartite graph setting used in this repo. Variable nodes and factor nodes
alternate; messages pass along edges.

This is the mathematical foundation for `BPToken`, `BPState`, and
`bp_forwardPass` in `Preliminaries.lean`.

## The Transformer as a GNN

A transformer operating on a sequence of tokens where each token attends to
specific other tokens (by positional index) is essentially a GNN where:

- Tokens = graph nodes
- Attention routing = edge selection
- Attended values = messages
- FFN = node update function

The difference from standard GNNs:
- GNNs aggregate over all neighbors (sum/mean)
- Our transformer routes to *specific* neighbors by index (attention argmax)

This makes our transformer strictly more expressive than a standard GNN for
this task — it implements exact BP rather than an approximation.

## The Gap This Thread Reveals

GNN literature says: "GNNs are like BP."
Unfolding literature says: "We can make a network that approximates BP."
This repo says: "This specific transformer provably IS one round of BP."

The word "provably" is the entire contribution relative to this thread.
The formal proof in Lean is what separates our claim from the informal
connections drawn in the GNN and unfolding literature.