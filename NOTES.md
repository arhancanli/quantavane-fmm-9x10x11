# Notes: what is proved and how it was checked (13 November 2026)

## What is proved

Proved in Lean 4 (v4.35.0, Mathlib v4.35.0) with no `sorry`, no `native_decide` and only the axioms
`propext`, `Classical.choice` and `Quot.sound`. The statements of record are in `Challenge.lean`;
`comparator.json` names the two compared theorems.

- `MatMul9x10x11.exists_tensor_decomposition`: 642 triples `(u i, v i, w i)` of rational matrices of
  sizes 9 × 10, 10 × 11, 9 × 11 with `∑ i, u i a b * v i c d * w i e f = if b = c ∧ a = e ∧ d = f then 1
  else 0` for all indices, i.e. `R(⟨9, 10, 11⟩) ≤ 642` over ℚ.
- `MatMul9x10x11.exists_bilinear_algorithm`: such triples with
  `A * B = ∑ i, ((∑ a, ∑ b, u i a b * A a b) * (∑ c, ∑ d, v i c d * B c d)) • w i` for every field `K`
  of characteristic zero (any universe) and all `A : Matrix (Fin 9) (Fin 10) K`,
  `B : Matrix (Fin 10) (Fin 11) K`, the coefficients cast from ℚ.

The kernel checks (`decide +kernel`): `chunk_0` … `chunk_89` (one per entry `x` of the first factor:
the packed slice `∑ᵢ uᵢ[x] (∑_y vᵢ[y] X^y)(∑_z wᵢ[z] X^(110 z))`, `X = 2⁵⁶`, equals the packed
slice of `D` times the tensor, `D = dU dV dW = 2,385,510,400`), `range_ok`, `bound_ok`
(`∑ᵢ ‖uᵢ‖₁ ‖vᵢ‖₁ ‖wᵢ‖₁ + D = 8,130,146,432,450,560 < 2⁵⁶`) and `terms_length`.
`MatMul9x10x11/Sound.lean` proves for every input that these checks give the integer identity
(`tensor_of_checks`); the scheme is untrusted data. `scripts/make_data.py` checked the scheme
file's SHA-256 (`c2760ddbb5085e75e82311262c208449d30d6f9386a7aafabdbcaf14c61fcccc`) and all 980,100
coefficient equations in exact integer arithmetic before writing the data; the Lean proof does not
rely on either.

## Line counts

| File | Lines |
|---|---|
| `Challenge.lean` | 65 (3,247 bytes) |
| `Solution.lean` | 34 |
| `MatMul9x10x11.lean` | 7 |
| `MatMul9x10x11/Check.lean` | 80 |
| `MatMul9x10x11/Data.lean` | 1,960 (generated; 43,857 nonzero coefficients) |
| `MatMul9x10x11/Chunks.lean` | 381 (generated) |
| `MatMul9x10x11/Sound.lean` | 377 |
| `MatMul9x10x11/Bridge.lean` | 112 |
| `scripts/CheckAxioms.lean` | 14 |

Every `.lean` file starts with `module`; `Challenge.lean` imports only Mathlib
(`Mathlib.Data.Matrix.Mul`, `Mathlib.Data.Rat.Cast.CharZero`).

## Checks run (Mac, Apple silicon, Lean v4.35.0, machine load about 50 to 60)

All on a fresh clone of commit `989e2ffcaeade8792e151628ec670b8e8c54adc5` (the commit before this
file was added; no Lean file changed since), with the Lake packages of the pinned Mathlib checkout
and the project's own modules built from scratch.

1. `lake build`: every module built; `MatMul9x10x11.Data` 14 s, `MatMul9x10x11.Chunks` (the 90
   kernel checks) 53 s (peak 2.6 GB in a separate build of the same modules). `Challenge` warns twice (declarations use
   `sorry`, as intended).
2. `lake env lean scripts/CheckAxioms.lean`: both theorems
   `depend on axioms: [propext, Classical.choice, Quot.sound]`.
3. `lake comparator` needs bubblewrap (Linux namespaces) and does not run on macOS; the
   `--inadvisably-no-sandbox` mode was not used. Palomar's preflight workflow runs it on Linux after a
   push. In its place, steps 4 and 6 were run by hand.
4. Statement comparison: every constant reachable from the types of the compared theorems
   (following definition values, not proofs) was printed with `pp.all` and hashes in the Challenge and
   in the Solution environment. The two outputs (2 roots, 632 constants) are identical.
5. Red controls (each must fail, and does): one coefficient of term 0 increased by one in the first,
   the second and the third factor (slice 0 fails each time); a zero coefficient of the second factor
   of term 0 made 1 (slice 0 fails); the last term dropped, i.e. rank 641 claimed (some slice fails);
   the bound check with 52-bit slots; the range check for the format 9 × 10 × 10. The unchanged
   slice 0, checked in the same file, passes. `scripts/make_data.py` also fails on a changed scheme
   file (SHA-256) and would fail on a wrong coefficient (its own exact check).
6. Kernel replays: `leanexport` wrote both modules with the compared theorems as targets; the
   Solution export (32.5 MB) was replayed through every kernel bundled with the toolchain:

   ```
   leanchecker            rc 0    76 s   1.9 GB
   nanoda                 rc 0    12 s   1.9 GB
   con-ron                stopped, no verdict (see below)
   leanchecker-paranoid   rc 0    93 s   1.9 GB
   lean4lean              rc 0    97 s   1.9 GB   checked 7323 declarations
   con-leche              rc 0    38 s   7.9 GB   accepted 7326 declarations (--verified)
   ```

   con-ron did not finish within the limits of this machine: with its default parallel jobs it was
   stopped after 7 minutes when it passed 7.8 GB of memory (its arena keeps every intermediate
   number; peak 9.2 GB), and with `--jobs=1` it was stopped after 33 minutes without a verdict
   (1.6 GB). Neither run reported an error. The large-integer arithmetic of the 90 slice checks is
   what takes the time; the other five kernels finish in under two minutes each.

   NanoDa with unpermitted axioms as a hard error: Solution export exit 0; Challenge export exit 1
   (`export file declares unpermitted axiom "sorryAx"`), as it should. `Lean.ofReduceBool` does not
   occur in the Solution export. SHA-256 of the exports: `solution.ndjson`
   `426b3d55c813aac9bf3e3158c2302e53fe17e2a4c9f125bd708bbe0af36c01c4`, `challenge.ndjson`
   `a1c6004eb369f775f7954d3e913811cea786980afc37b71e0b785856f88db6fe`.

## What remains

- Palomar's mechanical preflight (the workflow above, on GitHub's Linux runners) has not run: it needs
  the repository to be public on GitHub. Its advisory con-ron replay may need more memory than the
  runner has (see above); the Lean kernel and NanoDa replays, which it requires, use under 2 GB.
- No review outside Quantavane's agents.
- Not formalized: tensor rank as a definition, positive characteristic, recursive use on blocks,
  lower bounds.
