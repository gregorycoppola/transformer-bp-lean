# Connection to the Paper Trilogy

## The Three Papers

**Paper 1 — Coppola (2024): The Quantified Boolean Bayesian Network**
Introduces the QBBN as a unified model of logical and probabilistic reasoning.
Defines the factor graph structure (AND/OR boolean gates), the BP inference
algorithm, and the π/λ message passing equations. Claims no hallucination
because beliefs are determined by message passing from evidence.

**Paper 2 — Coppola (2026a): Statistical Parsing for Logical Information Retrieval**
Shows how to parse natural language into QBBN logical forms. The pipeline
is: surface form → dependency parse → semantic roles → QBBN propositions.
Provides the bridge from language to the graphical model.

**Paper 3 — Coppola (2026b): The Universal Language: A Characteristica Universalis for AI**
Proves that a transformer agent is Turing complete via Boolean circuit
simulation (the universal-lean result). Frames the transformer as realizing
Leibniz's characteristica universalis — a calculus of thought where
reasoning is computation.

## Where This Repo Fits

This repo proves the connection between Paper 1 and Paper 3 that Paper 3
identifies as an open problem:

    Paper 3 open problem: "Can a transformer agent simulate one step
    of belief propagation over a QBBN factor graph?"

    This repo: Yes. Here are the weights. Here is the Lean proof.

The proof chain across the trilogy is:

    Language → QBBN propositions    (Paper 2: parsing)
    QBBN propositions → factor graph (Paper 1: graph construction)
    Factor graph → transformer weights (this repo: construction)
    Transformer weights → BP         (this repo: proof)
    BP → posterior beliefs           (ECT + PCT theses)

The trilogy + this repo together give:

    Natural language query
        → parse to QBBN logical form
        → construct factor graph
        → encode as token sequence
        → run transformer agent (implements iterated BP)
        → decode posterior beliefs
        → answer without hallucination

## The Characteristica Universalis Connection

Leibniz dreamed of a calculus of thought where reasoning could be done
by calculation rather than argumentation. The trilogy realizes this in
two complementary senses:

**Computational sense (Paper 3 + universal-lean):**
The transformer agent can compute any computable function.
Reasoning is literally computation — Boolean circuits, Turing machines.

**Inferential sense (this repo):**
The transformer agent computes Bayesian posterior inference over
propositions. Reasoning is probabilistic calculation — message passing,
belief updating, convergence to the posterior.

The first sense is about what the transformer CAN compute (universality).
The second sense is about what the transformer DOES compute (semantics).
Both are necessary for the full characteristica picture.

## The Hallucination Explanation

The trilogy gives a precise explanation of why LLMs hallucinate and
why the QBBN agent does not.

An LLM doing chain-of-thought:
- Has a tape (context window)
- Does bounded pattern matching (attention over tokens)
- Has no structured generative model over propositions
- Can assert p without evidence — pattern completion fills the gap

A QBBN agent:
- Has a tape (growing factor graph)
- Does iterated BP (attention implements message passing)
- Has a structured generative model (QBBN factor graph)
- Cannot assert p without evidence — belief is determined by messages

The LLM is an unstructured approximation to the QBBN agent.
It gets the architecture right (transformer with iteration) but
not the semantics (BP over a logical generative model).

The formal proof in this repo makes the distinction precise:
we exhibit the exact weights that make a transformer into a
QBBN inference engine, and prove the correspondence in Lean.

## The Missing Link Before This Repo

Before this repo, the trilogy had a gap:

Paper 1 claims: BP computes correct posteriors over QBBN graphs
Paper 3 claims: transformers can compute anything

Neither paper shows: transformers compute BP over QBBN graphs

This is the gap this repo fills. It is the connection that turns
"transformers are universal" into "transformers are Bayesian reasoners
over a specific logical structure."

## What Comes Next

The natural extensions suggested by this repo:

**Fourth paper (empirical):**
Train a transformer on QBBN inference tasks. Apply mechanistic
interpretability (ACDC, activation patching) to find the learned circuit.
Compare to the constructed circuit in Attention.lean.
If they match: gradient descent finds our construction.
If they don't: characterize the gap.

**Fifth paper (existential quantification):**
Extend the construction to handle existential quantification via
Noisy OR aggregation heads. Show that the agent loop populates
unsatisfied existentials through retrieval, and BP handles the
inference. This closes the gap between the QBBN's closed-universe
assumption and open-domain natural language reasoning.

**Sixth paper (learning):**
Show that the QBBN weights (Ψor parameters) can be learned from
unlabeled text via expectation maximization, with the transformer
running the E-step (BP inference) and gradient descent running the
M-step (weight update). This is the learning algorithm that Paper 1
identifies as future work.