# Looped Transformers as Programmable Computers

**Authors:** Giannou et al.
**Date:** 2023
**Venue:** ICML 2023

## Claim

A single transformer layer, applied repeatedly in a loop with a scratchpad,
can simulate any program on a register machine (SUBLEQ instruction set).
Therefore transformer agents are Turing complete.

## Method

Constructs explicit weight matrices for a single transformer layer that can
execute one step of a SUBLEQ (subtract and branch if less than or equal) program.
The agent loop provides the iteration.

## Relationship to universal-lean

The `universal-lean` repo (Coppola 2026) takes a different approach to the
same Turing completeness claim: instead of instruction-set emulation (SUBLEQ),
it uses Boolean circuit simulation. This gives a simpler, more transparent
construction (4 layers, each with a clear purpose) and connects more naturally
to the QBBN factor graph structure.

## Relationship to This Repo

Looped transformers establishes the *computational* universality baseline.
This repo is asking a *semantic* question on top of that: not just "can a
transformer loop compute anything" but "what does this specific transformer
loop compute, and is it Bayesian inference?"

The two results are complementary:
- Looped transformers: transformer agents are Turing complete (computational)
- This repo: transformer agents implement BP over QBBNs (semantic/inferential)