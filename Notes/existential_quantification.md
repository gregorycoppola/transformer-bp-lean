# Existential Quantification and the K=2 Construction

## The Question

Does the K=2 two-head construction limit the expressiveness of the QBBN?
Specifically: how does the transformer handle rules with universally quantified
variables that don't appear in the conclusion, e.g.:

    ∀x, y, friends(x, y) → friend_haver(x)

Here y appears in the premise but not the conclusion. This is the "unsafe"
case in Datalog terms (see complexity classes paper, Section 3.2).

## The Answer

The K=2 construction is not the bottleneck. The architecture handles this
through **iteration**, not through wider attention.

### How it works

1. Each node in the factor graph holds a belief b ∈ [0,1]
2. On each BP pass, each node gathers from its K=2 neighbors and updates
3. Over T passes, beliefs propagate from all groundings of y up through
   the factor graph to friend_haver(x)
4. The variable y is effectively **marginalized out** during BP —
   its contribution accumulates at friend_haver(x) over multiple passes

### The separation of concerns

- **Attention heads** (K=2): handle local gather — one pass, two neighbors
- **Agent loop** (T passes): handles the aggregation over groundings of y

These are different levels of the architecture doing different jobs.
The heads implement the forward fragment (one BP round = one →-Elimination).
The loop implements the query fragment (iteration over groundings = ∃-search).

### Connection to complexity classes paper

The three fragments map cleanly onto the architecture:

| Fragment | Mechanism | Paper |
|----------|-----------|-------|
| Forward | One BP pass, K=2 heads | This paper (formal) |
| Query | Agent loop, T passes | This paper (iteration) |
| Planning | ∨-Elimination, reasoning by cases | Future work |

The forward fragment is what the K=2 Lean proof covers formally.
The query fragment is handled by the same architecture through iteration —
no new attention heads needed, no wider construction required.

### Why this is a stronger result than it looks

The same fixed K=2 architecture handles arbitrary-arity rules through
iteration alone. The depth scales with domain size, not predicate arity.
A rule with N groundings of y requires O(diameter) passes regardless
of N — the graph structure absorbs the quantifier, not the attention width.

## Implication for the no-hallucination theorem

The no-hallucination guarantee (transformer_exact_on_tree) applies to
the forward fragment directly. For the query fragment — rules with
unbound universally quantified variables — the guarantee extends to
the iterated case, conditional on:

1. The factor graph correctly encodes the grounding structure
2. T ≥ diameter(G) passes are run
3. The tree assumption holds (or ECT/PCT hold for loopy case)

No new formal machinery is needed. The existing theorems cover this.

## Open question

Does the iterated case need a separate formal statement in Lean?
The current transformer_iterated_implements_runBP covers T passes
of BP. The connection to existential quantification via the complexity
classes paper is currently informal. A clean statement would be:

    If a QBBN knowledge base encodes a set of Horn clauses including
    unsafe rules (existentially quantified premises), then
    transformer_iterated_implements_runBP computes the correct
    marginal posteriors at all conclusion nodes after T ≥ diameter passes.

This follows from the existing theorems but is not explicitly stated.