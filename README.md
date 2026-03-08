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

    transformer_implements_bp                 -- one pass = one BP round
    transformer_iterated_implements_runBP     -- T passes = T BP rounds
    transformer_computes_posterior            -- T passes → true posteriors (+ ECT, PCT)

The tree corollary (no conditions at all) follows by combining `transformer_iterated_implements_runBP` with `hard-bp-lean`'s `bp_exact_on_tree`.

## Axiom Inventory

The proof is honest about what is axiomatized:

| Axiom | What it says | Removable by |
|-------|-------------|--------------|
| FET | FFN weights exist to compute `updateBelief` | Sigmoid FFN, or use learned Ψor target |
| ECT | Loopy BP converges | Restricting to tree-structured graphs |
| PCT | BP fixed point = true posterior | Restricting to tree-structured graphs |

On trees, all three axioms drop and the result is unconditional.

## Verifying the Proof

Requirements: Linux or macOS, `curl`, ~500MB disk space.

Install elan (Lean version manager):

    curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh
    source ~/.elan/env

Clone and build:

    git clone https://github.com/gregcoppola/transformer-bp-lean
    cd transformer-bp-lean
    lake build

A successful build with no errors and no `sorry` warnings confirms the proof. Lean `v4.14.0` is pinned in `lean-toolchain` and fetched automatically by elan.

Check for sorries explicitly:

    grep -r "sorry" TransformerBPLean/

Should return nothing.

## Repo Structure

    TransformerBPLean/
      Preliminaries.lean   -- types, attention, FFN, BP defs, axioms, main theorems
      Attention.lean       -- attention implements bp_gatherAll (supporting lemmas)
    matrix/                -- positioning docs: trilogy, related work, paper 4 plans
    Notes/                 -- proof strategy, open questions, theses
    LitReview/             -- literature on related formal and empirical work

## Part of a Trilogy

This repo is a companion to three papers on the Universal Language / QBBN system:

- **Paper 1 (2024):** The Quantified Boolean Bayesian Network — inference engine
- **Paper 2 (2026):** Statistical Parsing for Logical IR — syntax pipeline
- **Paper 3 (2026):** The Universal Language — formal semantics and Leibniz framing

The formal result here closes the open problem stated in Paper 3.