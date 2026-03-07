# Attention.lean — Overview

This file proves that a two-head attention mechanism implements
`bp_gatherAll`: after both heads run, dim 4 holds neighbor 0's
belief and dim 5 holds neighbor 1's belief.

## Definitions

### `projectDim d`
A diagonal projection matrix that extracts dimension `d` in place.
`Wq[d][i] = 1` iff `i = d`, else 0. Used for query/key matrices
so that the dot-product score reduces to a single coordinate comparison.

### `crossProject src dst`
An off-diagonal projection that reads source dim `src` and writes
to output dim `dst`. `Wv[dst][src] = 1`, all else 0. Used for value
matrices so that the attended belief (at dim 0) lands in a scratch
slot (dim 4 or 5) rather than overwriting dim 0.

### Weight matrices

| Name | Definition | Role |
|------|-----------|------|
| `Wq_neighbor0` | `projectDim ⟨1⟩` | Head 0 query: extracts neighbor 0's index from dim 1 |
| `Wk_neighbor0` | `projectDim ⟨1⟩` | Head 0 key: extracts own index from dim 1 |
| `Wv_neighbor0` | `crossProject ⟨0⟩ ⟨4⟩` | Head 0 value: routes belief (dim 0) → scratch slot 0 (dim 4) |
| `Wq_neighbor1` | `projectDim ⟨2⟩` | Head 1 query: extracts neighbor 1's index from dim 2 |
| `Wk_neighbor1` | `projectDim ⟨2⟩` | Head 1 key: extracts own index from dim 2 |
| `Wv_neighbor1` | `crossProject ⟨0⟩ ⟨5⟩` | Head 1 value: routes belief (dim 0) → scratch slot 1 (dim 5) |

## Axioms

### Linear algebra (dischargeable by foldl computation)

| Axiom | Statement |
|-------|-----------|
| `projectDim_extract` | `(projectDim d) * x = x[d]` at dim d, 0 elsewhere |
| `crossProject_extract` | `(crossProject src dst) * x = x[src]` at dim dst, 0 elsewhere |
| `query_neighbor0_extract` | `Wq0 * enc(j)` = nb0 index at dim 1, 0 elsewhere |
| `key_neighbor0_extract` | `Wk0 * enc(k)` = k's index at dim 1, 0 elsewhere |
| `value0_belief_extract` | `Wv0 * enc(k)` = k's belief at dim 4, 0 elsewhere |
| `query_neighbor1_extract` | `Wq1 * enc(j)` = nb1 index at dim 2, 0 elsewhere |
| `key_neighbor1_extract` | `Wk1 * enc(k)` = k's index at dim 2, 0 elsewhere |
| `value1_belief_extract` | `Wv1 * enc(k)` = k's belief at dim 5, 0 elsewhere |

### Concentration (dischargeable via posEncDot_distinct from universal-lean)

| Axiom | Statement |
|-------|-----------|
| `attention_score_gap0` | Head 0 scores are uniquely maximized at neighbor 0's token |
| `attention_score_gap1` | Head 1 scores are uniquely maximized at neighbor 1's token |
| `hardmax_attention_exact` | At sufficiently high temperature, attended value = value at argmax |

### Independence (dischargeable via crossProject_extract)

| Axiom | Statement |
|-------|-----------|
| `head1_zero_at_dim4` | Head 1's attended value at dim 4 = 0 for any input (Wv1 never writes to dim 4) |
| `head0_zero_at_dim5` | Head 0's attended value at dim 5 = 0 for any input (Wv0 never writes to dim 5) |
| `head0_preserves_dims0_and_2` | Head 0 leaves dims 0 and 2 unchanged (Wv0 only writes to dim 4) |
| `gather1_on_any_state` | Head 1's gather result holds on any state agreeing with encodeBPState on dims 0 and 2 |

## Lemmas

### `attention_implements_gather0`
**Statement:** There exists a temperature λ such that after head 0,
dim 4 of token j equals neighbor 0's belief.

**Proof chain:**
1. `attention_score_gap0` → scores uniquely maximized at nb0
2. `hardmax_attention_exact` → attended value = values at nb0
3. `value0_belief_extract` → values at nb0, dim 4 = nb0's belief
4. `encodeBPState_scratch_zero` → dim 4 starts at 0
5. Residual: 0 + belief = belief

### `attention_implements_gather1`
**Statement:** Symmetric to gather0 for head 1 and dim 5.

**Proof:** Same chain with indices 1/2/5 in place of 0/1/4.

### `attention_implements_gatherAll`
**Statement:** After twoHeadAttention, dim 4 = nb0's belief AND
dim 5 = nb1's belief simultaneously.

**Proof:**
- **Dim 4:** head 0 sets it; `head1_zero_at_dim4` shows head 1 adds 0. `linarith` closes.
- **Dim 5:** `head0_preserves_dims0_and_2` shows intermediate state
  agrees with encodeBPState on dims 0 and 2; `gather1_on_any_state`
  transfers the gather1 result to the intermediate state;
  `head0_zero_at_dim5` + `encodeBPState_scratch_zero` show intermediate
  dim 5 = 0; residual gives nb1's belief. `linarith` closes.