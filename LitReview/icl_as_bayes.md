# Thread 3: In-Context Learning as Bayesian Inference

## Overview

A cluster of papers from 2022-2023 argue that transformers doing few-shot
in-context learning (ICL) are implicitly performing Bayesian inference over
a prior on tasks. The forward pass *is* the inference — no weight updates,
just posterior updating as tokens are read.

This thread asks the same question we ask — what algorithm does the forward
pass implement — but in the learning setting rather than the graphical model
setting.

## Key Papers

### Xie et al. (2022) — "An Explanation of In-Context Learning as Implicit Bayesian Inference"

**The central claim:** GPT-style transformers doing ICL are implicitly computing:

    P(output | prompt) = sum_theta P(output | theta) P(theta | prompt)

where theta is a latent "concept" variable. The prompt acts as evidence that
updates a prior over concepts, and the output is sampled from the resulting
posterior predictive.

They show this formally for a hidden Markov model generative process and
argue the same mechanism operates in large LLMs.

**Relevance:** This is the closest prior work to our philosophical claim.
They argue the transformer forward pass implements posterior inference.
The difference: they argue it for *learned* transformers doing ICL, and
the "posterior" is over task concepts, not over propositions in a knowledge base.
We argue it for *constructed* transformer weights doing BP, and the posterior
is over QBBN variable assignments.

**Critical difference:** Their argument is informal for large LLMs and formal
only for the simplified HMM setting. Our argument is formal (Lean proof)
for the QBBN setting.

### Akyürek et al. (2022) — "What Learning Algorithm Is In-Context Learning? Investigations with Linear Models"

**The central claim:** Transformers implement gradient descent in their forward
pass when doing ICL on linear regression tasks. Specific weight matrices are
constructed that implement one step of gradient descent.

**Relevance:** This is the most direct methodological precedent for our work.
They construct explicit weight matrices and show they implement a specific
algorithm (gradient descent). We do the same for BP.

The difference: gradient descent on linear regression is a much simpler
algorithm than BP on a factor graph. Their construction fits in a single
attention layer. Ours requires two attention heads plus an FFN.

Also: they do not formally verify their construction in a theorem prover.
We do (in Lean 4).

### Von Oswald et al. (2023) — "Transformers Learn In-Context by Gradient Descent"

**The central claim:** Gradient descent on a linear model and transformer
attention are performing the same computation — they show weight construction
and empirical verification that trained transformers converge to the same
solution as gradient descent.

**Relevance:** Extends Akyürek et al. from "transformers can implement GD"
to "transformers trained on ICL tasks learn to implement GD." Shows the
construction is not just theoretically possible but is what gradient descent
actually finds.

The analogous claim for our work would be: transformers trained on QBBN
inference tasks learn to implement BP. This is not proven here but is the
natural conjecture suggested by Agarwal & Misra (2025) and Shai et al. (2025).

### Garg et al. (2022) — "What Can Transformers Learn In-Context? A Case Study of Simple Function Classes"

Empirical study of what algorithms transformers implement for various function
classes (linear functions, sparse linear functions, decision trees, neural nets).
Finds that transformers match or exceed Bayesian optimal predictors on simple
classes.

**Relevance:** Establishes empirically that transformers are not just
approximately Bayesian but can match the Bayesian optimal. Our formal proof
gives a constructive explanation of why this is possible.

## The Key Distinction from This Repo

The ICL-as-Bayes literature studies:
- **Learned** transformers (trained on data)
- **Statistical** Bayesian inference (posterior over task/concept)
- **Informal** arguments (or formal only for toy settings)

This repo studies:
- **Constructed** transformers (explicit weight matrices)
- **Graphical model** Bayesian inference (BP over QBBN factor graph)
- **Formal** proof (Lean 4 verification)

The ICL literature asks: "does gradient descent find weights that implement
Bayesian inference?" We ask: "do these specific weights implement BP?" and
prove the answer formally.

## Implication for the Trilogy

If the ICL-as-Bayes claim is correct for large LLMs, and our formal proof
shows that specific weights implement BP over a QBBN, then the conjecture is:

> Large LLMs trained on natural language are implicitly learning to perform
> BP over a QBBN-like structure induced by the training data.

This is not proven anywhere. It is the natural synthesis of Thread 3 and
this repo, and is arguably the most important open question in the trilogy.