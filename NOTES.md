# Notes: what is proved and how it was checked (13 November 2026)

## What is proved

Proved in Lean 4 (v4.35.0, Mathlib v4.35.0) with no `sorry`, no `native_decide` and only the axioms
`propext`, `Classical.choice` and `Quot.sound`. The statements of record are in `Challenge.lean`;
`comparator.json` names the two compared theorems.

- `MatMul9x10x11.exists_tensor_decomposition`: 640 triples `(u i, v i, w i)` of rational matrices of
  sizes 9 × 10, 10 × 11, 9 × 11 with `∑ i, u i a b * v i c d * w i e f = if b = c ∧ a = e ∧ d = f then 1
  else 0` for all indices, i.e. `R(⟨9, 10, 11⟩) ≤ 640` over ℚ.
- `MatMul9x10x11.exists_bilinear_algorithm`: such triples with
  `A * B = ∑ i, ((∑ a, ∑ b, u i a b * A a b) * (∑ c, ∑ d, v i c d * B c d)) • w i` for every field `K`
  of characteristic zero (any universe) and all `A : Matrix (Fin 9) (Fin 10) K`,
  `B : Matrix (Fin 10) (Fin 11) K`, the coefficients cast from ℚ.

The kernel checks (`decide +kernel`): `chunk_0` … `chunk_89` (one per entry `x` of the first factor:
the packed slice `∑ᵢ uᵢ[x] (∑_y vᵢ[y] X^y)(∑_z wᵢ[z] X^(110 z))`, `X = 2⁵⁶`, equals the packed
slice of `D` times the tensor, `D = dU dV dW = 2048 · 224 · 16 = 7,340,032`), `range_ok`, `bound_ok`
(`∑ᵢ ‖uᵢ‖₁ ‖vᵢ‖₁ ‖wᵢ‖₁ + D = 25,958,047,940,608 < 2⁵⁶`) and `terms_length`.
`MatMul9x10x11/Sound.lean` proves for every input that these checks give the integer identity
(`tensor_of_checks`); the scheme is untrusted data. `scripts/make_data.py` checked the scheme
file's SHA-256 (`e7e39dc2ee679146af372ca5352895cc93434eb45482d4e4f9127b0685f64051`) and all 980,100
coefficient equations in exact integer arithmetic before writing the data; the Lean proof does not
rely on either.

## Line counts

| File | Lines |
|---|---|
| `Challenge.lean` | 65 (3,247 bytes) |
| `Solution.lean` | 34 |
| `MatMul9x10x11.lean` | 7 |
| `MatMul9x10x11/Check.lean` | 80 |
| `MatMul9x10x11/Data.lean` | 1,953 (generated; 43,787 nonzero coefficients) |
| `MatMul9x10x11/Chunks.lean` | 381 (generated) |
| `MatMul9x10x11/Sound.lean` | 377 |
| `MatMul9x10x11/Bridge.lean` | 112 |
| `scripts/CheckAxioms.lean` | 14 |

Every `.lean` file starts with `module`; `Challenge.lean` imports only Mathlib
(`Mathlib.Data.Matrix.Mul`, `Mathlib.Data.Rat.Cast.CharZero`).

## Checks run (Mac, Apple silicon, Lean v4.35.0, machine load about 50 to 57)

All on a fresh clone of commit `3951236f7a816b57867b756a276133394339d558` (the commit before this
file was updated; no Lean file changed since), with the Lake packages of the pinned Mathlib checkout
and the project's own modules built from scratch (13 November 2026, 06:51 to 07:08 UTC). The first
version of this package (commit `989e2ffc`, 12 November 2026) proved rank at most 642 and was checked
the same way; it was replaced by the 640 scheme before anything was published.

1. `lake build`: every module built; `MatMul9x10x11.Data` 19 s, `MatMul9x10x11.Chunks` (the 90
   kernel checks) 60 s. `Challenge` warns twice (declarations use `sorry`, as intended).
2. `lake env lean scripts/CheckAxioms.lean`: both theorems
   `depend on axioms: [propext, Classical.choice, Quot.sound]`.
3. `lake comparator` needs bubblewrap (Linux namespaces) and does not run on macOS; the
   `--inadvisably-no-sandbox` mode was not used. Palomar's preflight workflow runs it on Linux after a
   push. In its place, steps 4 and 6 were run by hand.
4. Statement comparison: every constant reachable from the types of the compared theorems
   (following definition values, not proofs) was printed with `pp.all` and hashes in the Challenge and
   in the Solution environment. The two outputs (2 roots, 632 constants) are identical. (In the first
   pass of the script this step and step 5 wrote to an output folder that did not exist yet, so they
   did not run; both were run again on the same clone at 07:08 UTC, and the script now creates the
   folder first.)
5. Red controls (each must fail, and does): one coefficient of term 0 increased by one in the first,
   the second and the third factor (slice 0 fails each time); a zero coefficient of the second factor
   of term 0 made 1 (slice 0 fails); the last term dropped, i.e. rank 639 claimed (some slice fails);
   the bound check with 44-bit slots (the coefficients need 45 bits); the range check for the format
   9 × 10 × 10. The unchanged slice 0, checked in the same file, passes. `scripts/make_data.py` also
   fails on a changed scheme file (SHA-256) and would fail on a wrong coefficient (its own exact check).
6. Kernel replays: `leanexport` wrote both modules with the compared theorems as targets; the
   Solution export (32.5 MB) was replayed through every kernel bundled with the toolchain:

   ```
   leanchecker            rc 0    68 s   2.0 GB
   nanoda                 rc 0    11 s   2.2 GB
   con-ron                stopped after 7 min, no verdict (see below)
   leanchecker-paranoid   rc 0    80 s   2.0 GB
   lean4lean              rc 0   111 s   1.2 GB   checked 7323 declarations
   con-leche              rc 0    54 s   4.1 GB   accepted 7326 declarations (--verified)
   ```

   con-ron was given 7 minutes, as on 12 November for the 642 version, where it passed 7.8 GB of
   memory with its default parallel jobs and gave no verdict after 33 minutes with `--jobs=1`; this
   time it reached 7.9 GB resident in the 7 minutes. Neither run reported an error. The large-integer
   arithmetic of the 90 slice checks is what takes the time; the other five kernels finish in under
   two minutes each.

   NanoDa with unpermitted axioms as a hard error: Solution export exit 0; Challenge export exit 1
   (`export file declares unpermitted axiom "sorryAx"`), as it should. `Lean.ofReduceBool` does not
   occur in the Solution export. SHA-256 of the exports: `solution.ndjson`
   `a9504d95777bdbc5577628d6e0200d667974eb84584f0db0faba71384fc2f612`, `challenge.ndjson`
   `7ead99b9f22f43f2481de6d6f56ab5ae5ef7ef33c414a488b6a56c6c25a2a328`.

## What remains

- Palomar's mechanical preflight (the workflow above, on GitHub's Linux runners) has not run: it needs
  the repository to be public on GitHub. Its advisory con-ron replay may need more memory than the
  runner has (see above); the Lean kernel and NanoDa replays, which it requires, use under 2 GB.
- No review outside Quantavane's agents.
- Not formalized: tensor rank as a definition, positive characteristic, recursive use on blocks,
  lower bounds.
