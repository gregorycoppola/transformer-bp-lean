# Literature Review: Transformer-BP Connection

Papers organized by relevance to the thesis:
**transformer forward pass = one round of belief propagation over a QBBN**

## Directly Relevant

| File | Paper | Relevance |
|------|-------|-----------|
| [bayesian_geometry.md](bayesian_geometry.md) | Agarwal & Misra (2025) — The Bayesian Geometry of Transformer Attention | Closest empirical work; same claim but no formal proof |
| [constrained_belief.md](constrained_belief.md) | Shai et al. (2025) — Constrained Belief Updates Explain Geometric Structures | HMM setting; shows attention implements constrained BP |
| [pfn.md](pfn.md) | Müller et al. (2022) — Transformers Can Do Bayesian Inference | Meta-trained transformers approximate posteriors |

## Background: Belief Propagation

| File | Paper | Relevance |
|------|-------|-----------|
| [pearl_1988.md](pearl_1988.md) | Pearl (1988) — Probabilistic Reasoning in Intelligent Systems | Original BP algorithm |
| [loopy_bp.md](loopy_bp.md) | Murphy, Weiss & Jordan (1999) — Loopy BP for Approximate Inference | Empirical convergence thesis basis |
| [smith_eisner.md](smith_eisner.md) | Smith & Eisner (2008) — Dependency Parsing by Belief Propagation | BP convergence in NLP; cited in QBBN paper |

## Background: Transformer Theory

| File | Paper | Relevance |
|------|-------|-----------|
| [attention_all_you_need.md](attention_all_you_need.md) | Vaswani et al. (2017) — Attention Is All You Need | Transformer architecture definition |
| [looped_transformers.md](looped_transformers.md) | Giannou et al. (2023) — Looped Transformers as Programmable Computers | Turing completeness via instruction emulation; contrast to circuit approach |

## Your Own Papers (Trilogy Context)

| File | Paper | Relevance |
|------|-------|-----------|
| [qbbn.md](qbbn.md) | Coppola (2024) — The Quantified Boolean Bayesian Network | Paper 1; defines the graphical model this repo proves transformers simulate |
| [universal_language.md](universal_language.md) | Coppola (2026) — The Universal Language | Paper 3; characteristica universalis framing; BP simulation as open problem |

## Gap This Repo Fills

All prior work is either:
- **Empirical**: observes Bayesian behavior, does not prove it from weights
- **Constructive but non-specific**: shows transformers *can* do Bayesian inference
  given the right training, not that a specific architecture does a specific computation
- **Turing completeness**: shows transformers can compute anything, not what
  they specifically compute

This repo provides the first **formal constructive proof** that specific transformer
weights implement specific BP updates over a specific graphical model (QBBN),
with empirical convergence axiomatized as an explicit thesis.