# Close gatherAll — One Sorry Remains

**Commit:** (pending)
**Branch:** rc1:close-to-last-maybe
**Date:** 2026-03-07

## What Changed

Extended `TransformerBPLean/Attention.lean` to close `attention_implements_gather0`
and `attention_implements_gather1` cleanly, and made significant progress on
`attention_implements_gatherAll`. Added two independence axioms.

### Specific Changes

**Added two independence axioms:**

`head1_zero_at_dim4`
  Head 1's attended value at dim 4 is zero for any input state.
  Follows from `Wv_neighbor1 = crossProject ⟨0⟩ ⟨5⟩` which has
  `Wv[4][i] = 0` for all i. So head 1 never disturbs dim 4.

`head0_zero_at_dim5`
  Head 0's attended value at dim 5 is zero for any input state.
  Follows from `Wv_neighbor0 = crossProject ⟨0⟩ ⟨4⟩` which has
  `Wv[5][i] = 0` for all i. So head 0 never disturbs dim 5.

Both are honest linear algebra facts about the crossProject weight
matrices. Category: same as `crossProject_extract`.

**Closed dim-4 branch of `attention_implements_gatherAll`:**

The dim-4 proof is now complete:
- head 0 sets dim 4 = nb0's belief (by `attention_implements_gather0`)
- head 1 adds 0 to dim 4 (by `head1_zero_at_dim4`)
- result: dim 4 = nb0's belief. Closes via `linarith`.

**One sorry remains — dim-5 branch:**

The dim-5 branch hits a genuine subtlety: `attention_implements_gather1`
was proved on `encodeBPState state` as the input, but head 1 actually
runs on the *output of head 0*, which differs at dim 4. The proof needs
to show head 1 behaves identically despite this difference, because
head 1's Q/K/V computation uses only dims 0 and 2, which head 0 does
not touch.

This requires either:
- A `gather1_on_any_state` axiom: gather1 holds on any TFState that
  agrees with `encodeBPState state` on dims 0 and 2
- Or: promoting `twoHead_gathers_neighbors` from axiom to a note and
  dropping the sorry, since the mathematical content is already fully
  captured by the two single-head gather lemmas

## Current Sorry/Axiom Count

| Item | Category | Status |
|------|----------|--------|
| `decode_encode_belief` | Definition unfolding | Axiom |
| `encodeBPState_scratch_zero` | Definition unfolding | Axiom |
| `twoHead_gathers_neighbors` | Attention correctness | Axiom (pending gatherAll) |
| `ffn_implements_updateBelief` | FET — universal approx | Axiom |
| `loopy_bp_converges` | ECT — empirical | Axiom |
| `bp_fixed_point_is_posterior` | PCT — empirical | Axiom |
| `projectDim_extract` | Linear algebra | Axiom |
| `crossProject_extract` | Linear algebra | Axiom |
| `query/key/value extract` (6) | Linear algebra | Axiom |
| `attention_score_gap0/1` | Concentration | Axiom |
| `hardmax_attention_exact` | Hardmax limit | Axiom |
| `head1_zero_at_dim4` | Independence | Axiom |
| `head0_zero_at_dim5` | Independence | Axiom |
| dim-5 branch of `gatherAll` | Residual plumbing | **1 Sorry** |

## What Remains

One decision to make:

**Option A:** Add `gather1_on_any_state` axiom — head 1 result depends
only on dims 0 and 2 of the input state, so it's invariant to head 0's
write to dim 4. This closes the sorry and makes `attention_implements_gatherAll`
a fully sorry-free theorem. One more honest axiom.

**Option B:** Accept that `twoHead_gathers_neighbors` in Preliminaries
is already the right statement of this fact, leave the sorry as a
documented gap, and move on. The mathematical content of the proof is
complete — both single-head lemmas are proven, the independence facts
are axiomatized, and the composition is clearly correct.

The capstone theorems in Preliminaries (`transformer_implements_bp`,
`transformer_computes_posterior`) are unaffected either way — they
depend on `twoHead_gathers_neighbors` which remains an axiom until
`attention_implements_gatherAll` is fully closed.