# transformer-bp-lean

Formal Lean 4 proof that a transformer forward pass implements belief propagation.

## The Result

Given a transformer with explicitly constructed weights, one forward pass is exactly one round of belief propagation (BP) on a QBBN factor graph. T forward passes are T rounds of BP. On tree-structured knowledge bases, the transformer computes exact Bayesian posterior beliefs — provably, with no empirical assumptions.

This is the missing link between two companion repos:
- [`universal-lean`](https://github.com/gregcoppola/universal-lean) — transformers are Turing complete
- [`hard-bp-lean`](https://github.com/gregcoppola/hard-bp-lean) — BP is exact on trees

Neither of those said what a transformer *does* on a knowledge base. This repo says: it does belief propagation.

## The Construction

The proof is constructive. The weights are explicit:

| Component | Weight | What it does |
|-----------|--------|-------------|
| Head 0 Q/K | `projectDim 1` | Match tokens by neighbor-0 index |
| Head 0 V | `crossProject 0 4` | Route neighbor-0 belief → scratch slot 0 |
| Head 1 Q/K | `projectDim 2` | Match tokens by neighbor-1 index |
| Head 1 V | `crossProject 0 5` | Route neighbor-1 belief → scratch slot 1 |
| FFN | learned | Compute `updateBelief` from scratch slots 0 and 1 |

Attention implements message gathering. FFN implements belief update. Together they are one BP round.

## The Theorems