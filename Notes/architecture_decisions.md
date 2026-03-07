# Architecture Decisions

Documenting why specific choices were made in Preliminaries.lean
and Attention.lean, so they can be revisited or justified in the paper.

## Why D_model = 8?

Minimum to fit:
- dim 0: belief (1 slot)
- dim 1: neighbor 0 index (1 slot)
- dim 2: neighbor 1 index (1 slot)
- dim 3: node type (1 slot)
- dim 4: scratch 0 — neighbor 0's belief after attention (1 slot)
- dim 5: scratch 1 — neighbor 1's belief after attention (1 slot)
- dim 6,7: reserved

Total: 6 slots used, 2 reserved. D_model = 8 is the minimum power
of 2 that fits. Could be 6 but 8 is cleaner.

Note: real transformers use D_model in the hundreds or thousands.
D_model = 8 is a proof-of-concept minimum. The construction scales
trivially to larger D_model by padding with zeros.

## Why K = 2?

K = 2 neighbors is the minimum for non-trivial BP. With K = 1 the
update is just copying the neighbor's belief. With K = 2 the update
combines two messages — the first case where updateBelief is interesting.

The QBBN paper's bipartite AND/OR structure means each variable node
has exactly 2 parents in the simple case (the AND node collects both
parent beliefs). K = 2 matches this structure.

For K > 2: need K attention heads, one per neighbor. The construction
scales linearly in K. No new ideas needed, just more heads.

For existential quantification (K = N, aggregate over all groundings):
requires a qualitatively different head that sums rather than selects.
See open_questions.md Q5.

## Why Two Separate Attention Heads (Not One)?

One head with two queries would need to produce two separate outputs —
one for dim 4 and one for dim 5. Standard attention produces one
attended value per head. So two neighbors require two heads.

Alternative: one head with a concatenated query/key that selects
both neighbors simultaneously. This would require the value matrix
to write to both dims 4 and 5 in one pass. More complex Wv routing,
harder to prove.

Two separate heads is cleaner: each head has a single job, the
correctness argument is simpler, the weight matrices are more explicit.

## Why Hardmax (Not Softmax)?

The proof uses hardmax_attention_exact — the idealized limit where
softmax with infinite temperature becomes an argmax. This simplifies
the proof significantly: no need to bound softmax approximation error
in the main theorem.

The cost: hardmax is not what real transformers use. Real transformers
use finite-temperature softmax. The gap is handled by the axioms
attention_score_gap0/1 plus softmax_concentrates_on_max — together
they say that with sufficient temperature, softmax approximates hardmax
well enough that the proof goes through.

For the approximate version (finite temperature): see open_questions.md Q3
on error accumulation. The attention error ε_attn ≈ (n-1)*exp(-2λ) goes
to 0 exponentially fast in λ, so this is essentially free to make small.

## Why Synchronous BP (Not Asynchronous)?

bp_forwardPass updates ALL nodes simultaneously in one pass.
This is synchronous (Jacobi-style) BP, not asynchronous (Gauss-Seidel) BP.

Reason: the transformer forward pass is inherently parallel — all tokens
are updated simultaneously. There is no natural way to implement
sequential (asynchronous) updates in a single forward pass.

Consequence: the convergence behavior is different from asynchronous BP.
Synchronous BP can oscillate in cases where asynchronous BP converges.
This is one reason ECT (convergence thesis) is needed — synchronous BP
has worse convergence guarantees than asynchronous.

## Why encodeBPState Zeroes Dims 4 and 5?

Dims 4 and 5 are scratch slots filled by attention. They start at 0
so that the residual connection adds the attended value cleanly:

    new_embedding[4] = old_embedding[4] + attended_value[4]
                     = 0 + neighbor_belief
                     = neighbor_belief

If dims 4/5 were nonzero at the start, the residual would add to
a nonzero base, corrupting the result.

This is also why the decode/encode round-trip is needed between passes:
re-encoding resets dims 4/5 to 0 for the next pass. If you ran the
raw transformer on its own output without re-encoding, dims 4/5 would
accumulate across passes and the second pass would be incorrect.

## Why belief in dim 0?

Dim 0 is the "output" dimension — the one that decodeTFState reads.
Putting belief in dim 0 makes the decode function trivial:

    (decodeTFState template state j).belief =
        (state j).embedding ⟨0, ...⟩

If belief were in a different dim, decode would need to know which
dim to read, complicating the interface.

After one forward pass, the FFN writes the updated belief back to dim 0,
which is then read by decode. The round-trip is: encode writes dim 0,
attention fills dims 4/5, FFN reads dims 4/5 and writes dim 0, decode
reads dim 0.

## Why Not Use Mathlib?

The repo is intentionally Mathlib-free. Reasons:

**Portability:** Mathlib is large and changes frequently. A Mathlib-free
repo builds faster and has fewer dependency issues.

**Transparency:** Every definition is explicit. Nothing is hidden inside
a Mathlib abstraction. This makes the proof more readable and auditable.

**Sufficiency:** The proof doesn't need advanced mathematics from Mathlib.
The axioms abstract away the parts that would need Mathlib (softmax
concentration, matrix algebra). The core proof is combinatorial.

Cost: some things that Mathlib would give for free (e.g. real analysis
for softmax bounds) have to be axiomatized instead. This is acceptable
given that those axioms are either standard results (softmax_concentrates)
or dischargeable by computation (projectDim_extract).

Future: if the approximate version (finite ε) is pursued, Mathlib's
analysis library would be needed for the approximation theory arguments.
At that point a Mathlib dependency becomes justified.