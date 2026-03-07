# Existential Quantification in the QBBN

## Overview

Existential quantification is one of the most common patterns in natural
language inference. The canonical example:

    taken(jack) ← ∃x, girlfriend(jack, x)

"Jack is taken if there exists a girl who is his girlfriend."

This pattern appears constantly in everyday reasoning:
- "Someone ate the cake" — ∃x, ate(x, cake)
- "Jack has a job" — ∃x, worksAt(jack, x)
- "The package was delivered" — ∃x, deliveredTo(package, x)

The question for the QBBN + transformer framework is: how is existential
quantification handled, and does it require new inference machinery beyond
BP?

**The answer:** No. Existential quantification is already handled by the
QBBN's OR nodes and graph construction mechanism. The transformer implementing
BP does not need to be extended.

---

## The Prolog Approach: Search

In Prolog, existential quantification is handled by proof search:

    taken(jack) :- girlfriend(jack, X).

Prolog searches for a binding of X that satisfies `girlfriend(jack, X)`.
This is sequential depth-first search — Prolog tries one candidate at a
time, backtracks on failure, succeeds when a witness is found.

**Cost:** O(N) in the number of entities in the worst case, but potentially
exponential for nested existentials. Sequential and not parallelizable.

**What it returns:** A specific witness X (or failure).

---

## The QBBN Approach: OR Over Known Groundings

The QBBN handles the same pattern differently. The implication link is:

    Ψ[jack, x]: girlfriend(jack, x) → taken(jack)

At query time for `taken(jack)`, the graph construction step:

1. Calls CONTEXT(taken(jack))
2. Finds all groundings of x in the knowledge base where
   girlfriend(jack, x) is stored — say {jill, mary, sue}
3. Creates proposition group nodes:
   {girlfriend(jack, jill)}, {girlfriend(jack, mary)}, {girlfriend(jack, sue)}
4. Connects them to taken(jack) via a Ψor factor

The Ψor factor then computes:

    P(taken(jack)) = 1 - P(¬gf(jack,jill)) * P(¬gf(jack,mary)) * P(¬gf(jack,sue))

under the Noisy OR independence assumption, or the full learned linear
exponential model otherwise.

**Cost:** O(N) database lookup at graph construction time, then O(N) BP
message passing. Fully parallelizable.

**What it returns:** P(taken(jack) = 1) — a probability, not a witness.

---

## The Key Architectural Separation

The QBBN separates two steps that Prolog conflates:

**Step 1: Knowledge retrieval** (graph construction)
> Which groundings of x exist in the knowledge base?

This is a database lookup: query `girlfriend(jack, *)` and retrieve all
matching entities. Happens before inference. Deterministic. Fast.

**Step 2: Probabilistic inference** (BP on the proposition graph)
> Given those groundings and their beliefs, what is P(taken(jack))?

This is BP over the finite graph constructed in Step 1.
This is what the transformer implements.

Prolog interleaves these steps — it searches for witnesses during
inference, unifying variables on the fly. This interleaving is what
makes Prolog sequential and non-parallelizable.

The QBBN's separation is what makes the transformer connection possible.
The transformer only ever sees a finite, already-grounded graph.
Existential quantification is resolved before the transformer runs.

---

## The Full Pipeline

    natural language query
          ↓
    parse to logical form: taken(jack)
          ↓
    KB lookup: find all x where girlfriend(jack, x) stored
          ↓
    construct proposition graph (finite, grounded)
          ↓
    encode as token sequence (encodeBPState)
          ↓
    transformer forward passes (implements BP)
          ↓
    decode beliefs (decodeTFState)
          ↓
    P(taken(jack) = 1)

The transformer handles only the middle step. Existential quantification
is handled by the KB lookup step, not by the transformer.

---

## Comparison to Related Systems

### vs. Prolog / ProbLog

Prolog: search for witnesses during inference (sequential, interleaved)
QBBN: retrieve witnesses before inference (parallel, separated)

ProbLog inherits Prolog's proof-search approach — it enumerates proofs
(witness bindings) and weights them. The QBBN enumerates groundings at
graph construction time and runs BP over the resulting graph. Faster
and more naturally parallelizable.

### vs. Markov Logic Networks

MLNs ground out all possible instantiations of all formulas — for N
entities and a formula with k variables, that's O(N^k) ground atoms.
Inference then runs over this (potentially enormous) ground network.

The QBBN is lazy: it only grounds the propositions relevant to the
specific query, via CONTEXT(p) and backwards substitution. For a query
about taken(jack), only the groundings of girlfriend(jack, *) matter —
not all possible instantiations of all formulas.

This lazy grounding is what makes the QBBN tractable for large knowledge
bases where MLN grounding would be prohibitive.

### vs. BLOG (Open Universe)

BLOG handles the case where you don't know how many entities exist.
The QBBN assumes a closed knowledge base at query time.

For natural language information retrieval, this is the right assumption:
the knowledge base contains all known entities, and the query is answered
relative to that knowledge base. Unknown entities are simply absent.

Open-universe reasoning (reasoning about entities not in the KB) is a
genuine limitation of the QBBN. It is not addressed by the transformer
connection — the transformer can only attend over tokens it has been
given, and cannot invent new entities.

---

## Nested Existentials

More complex patterns involve nested existentials:

    happy(jack) ← ∃x, girlfriend(jack, x) ∧ ∃y, job(jack, y)

"Jack is happy if he has both a girlfriend and a job."

In the QBBN this becomes:
1. KB lookup for girlfriend(jack, *) → groundings G
2. KB lookup for job(jack, *) → groundings J
3. Construct Ψor node over G, Ψor node over J
4. Construct Ψand node combining the two Ψor nodes
5. Connect to happy(jack)

The AND/OR structure handles nested existentials naturally — the
conjunction of two existentials is just an AND gate over two OR gates.
This is the bipartite AND/OR structure of the QBBN factor graph
doing exactly what it was designed to do.

BP runs over this graph in the usual way. No new machinery needed.

---

## The Genuinely Hard Case: Open-Domain Existentials

What the QBBN + transformer cannot handle without extension:

    ∃x (not in KB), P(x)

Reasoning about entities not present in the knowledge base. Examples:
- "There must be someone who committed the crime" (unknown suspect)
- "Some drug could cure this disease" (undiscovered drug)

This requires generating candidate entities, not just retrieving them.
It looks more like retrieval-augmented generation — the model must
propose candidates, ground them, run inference, aggregate results.

This is a genuine open problem for the QBBN framework. It is not
addressed by this repo and is left for future work.

---

## Implication for the Transformer Proof

The existential quantification analysis confirms that the transformer
proof in this repo is complete for the closed-universe case:

- All existentials are resolved at graph construction time
- The transformer sees only a finite grounded graph
- BP over that graph handles all the probabilistic inference
- The formal proof in Lean covers this exactly

The open-universe case requires extending the pipeline with a retrieval
step before the transformer runs. That extension is outside the scope
of this repo but is the natural next problem.

---

## Summary

| Aspect | Prolog | ProbLog | MLN | QBBN |
|--------|--------|---------|-----|------|
| Existential handling | Sequential search | Proof enumeration | Full grounding | Lazy KB lookup |
| Parallelizable | No | No | Partially | Yes |
| Transformer-implementable | No | No | No | Yes |
| Open universe | Unbounded | Unbounded | Unbounded | No (closed KB) |
| Returns witness | Yes | Yes (most probable) | MAP solution | No (probability) |

The QBBN's approach to existential quantification — lazy grounding
followed by BP — is what makes the transformer connection in this repo
possible. The separation of retrieval from inference is the architectural
choice that enables parallelism, which is what the transformer requires.