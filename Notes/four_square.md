# The Four Square: Computation × Memory

## The Two Axes

**Axis 1: Computation model**
- Deterministic / logical (Boolean gates, exact inference)
- Probabilistic / statistical (beliefs, distributions, BP)

**Axis 2: Memory model**
- With tape (unbounded external memory, agent loop)
- Without tape (bounded, single forward pass)

## The Matrix

                    DETERMINISTIC           PROBABILISTIC
                    (logical)               (statistical)

    WITH TAPE       Turing machine          QBBN agent
                    universal-lean          this repo (top claim)
                    Boolean circuits        iterated BP over QBBN
                    exact, unbounded        convergent inference
                    computation             no hallucination

    WITHOUT TAPE    Bounded theorem         Single forward pass BP
                    prover                  this repo (base theorem)
                    attention as            one round of message
                    pattern matching        passing
                    fixed proof depth       one belief update

## What Lives In Each Cell

### Top Left: Turing Complete + Deterministic

The universal-lean result (Coppola 2026).
A transformer agent with a tape simulates any Boolean circuit,
hence any Turing machine. Computation is exact, deterministic,
unbounded in time and space.

Prior work: Giannou et al. (SUBLEQ emulation), universal-lean
(circuit simulation — cleaner construction).

The key insight: the agent loop provides unbounded iteration,
the transformer provides one circuit layer per pass.

### Top Right: Turing Complete + Probabilistic (NEW)

This repo's capstone claim.
A transformer agent with a tape runs iterated BP over a QBBN.
Each pass is one round of probabilistic inference.
The tape allows the graph to grow (existential quantification).
Converges to Bayesian posterior (given ECT + PCT theses).

This cell is EMPTY in prior literature.
Everything probabilistic is bounded (bottom right).
Everything with a tape is deterministic (top left).
This repo is the first entry in the top right.

### Bottom Left: Bounded + Deterministic

A single transformer forward pass doing bounded logical inference.
Prolog-like but parallelized — no sequential search, just parallel
pattern matching to fixed depth.

What attention does when viewed as selecting which propositions
match a query. The induction head circuit (Olsson et al.) is an
example: match current token to previous occurrence in bounded context.

No convergence guarantee. No unbounded reasoning. Just whatever
logical relationships fit in the fixed depth.

### Bottom Right: Bounded + Probabilistic

A single transformer forward pass = one round of BP.
The core theorem of this repo.

Fixed graph, fixed depth, one message-passing iteration.
This is the building block for the top right cell.
Provable (with axioms) in Lean 4.

Prior work: Agarwal & Misra (empirical), Shai et al. (constrained
belief updating). Both observe this behavior in trained transformers.
This repo proves it constructively for the QBBN.

## The Four Transitions

### Bottom Right → Top Right (this repo's main contribution)

Add the agent loop. One round of BP becomes iterated BP.
The transformer becomes a convergent inference engine.
This is the step from transformer_implements_bp (base theorem)
to transformer_iterated_implements_runBP (convergence claim).
Requires ECT (convergence) and PCT (correctness of fixed point).

### Bottom Left → Top Left (universal-lean)

Add the tape to bounded logical inference.
One depth of proof search becomes unbounded theorem proving.
The agent loop provides the recursion that bounded depth cannot.

### Bottom Left → Bottom Right (QBBN paper, Paper 1)

Add probabilities to bounded logical inference.
Exact Boolean gates become probabilistic beliefs.
AND/OR gates become Ψand/Ψor factors.
Deterministic proof becomes probabilistic inference.

### Top Left → Top Right (the grand synthesis)

Add probabilities to Turing complete computation.
The most general transition — a probabilistic Turing machine.
The QBBN agent is a specific structured instance:
the structure (factor graph + BP) is what makes computation
both tractable and non-hallucinating.

## Where The Literature Sits

                    DETERMINISTIC           PROBABILISTIC

    WITH TAPE       Giannou et al.          THIS REPO (new)
                    universal-lean
                    Weiss et al. (RASP)

    WITHOUT TAPE    Akyürek et al.          Agarwal & Misra (empirical)
                    Feng et al. (CoT+DP)    Shai et al. (empirical)
                    Bai et al.              Müller et al. (meta-trained)

The top right cell is the contribution.
All prior probabilistic work is bounded (no tape).
All prior taped work is deterministic (no beliefs).

## The Hallucination Connection

The four square explains why LLMs hallucinate and the QBBN agent does not.

An LLM doing chain-of-thought sits in the top left cell — it has a tape
(the context window used as scratchpad) and does deterministic token
prediction. But token prediction is not probabilistic inference over
a structured model — it's pattern matching without a generative model
that enforces P(p) + P(¬p) = 1.

The QBBN agent sits in the top right cell — it has a tape and does
probabilistic inference over a structured graphical model. Every belief
satisfies the normalization constraint by construction. Hallucination
(asserting p without evidence) is impossible because beliefs are
determined by message passing from evidence, not by pattern completion.

The LLM is an approximation to the QBBN agent that lacks the
structured generative model. It gets the "tape + iteration" part right
but not the "probabilistic inference over propositions" part.