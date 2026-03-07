# Fix Wv Definition and Close Gather Lemmas

**Commit:** (pending)
**Branch:** rc1:fix-prelims
**Date:** 2026-03-07

## What Changed

Rewrote `TransformerBPLean/Attention.lean` to fix the `Wv` definition
bug and close the `attention_implements_gather0` and
`attention_implements_gather1` lemmas.

### Specific Changes

**Added `crossProject` definition:**