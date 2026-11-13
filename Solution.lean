module

public import MatMul9x10x11

public section

/-!
# Proof of the statements in `Challenge.lean`

The theorems below have exactly the statements of their counterparts in `Challenge.lean`
(Comparator checks this). The witnesses are `u`, `v`, `w` of `MatMul9x10x11.Bridge`: the 640 terms
of the scheme in `MatMul9x10x11.Data`, divided by their common denominators. `rat_identity` and
`bilinear` are proved there from the kernel checks of `MatMul9x10x11.Chunks` and the soundness
theorem `tensor_of_checks` of `MatMul9x10x11.Sound`.
-/

namespace MatMul9x10x11

theorem exists_tensor_decomposition :
    ∃ (u : Fin 640 → Matrix (Fin 9) (Fin 10) ℚ) (v : Fin 640 → Matrix (Fin 10) (Fin 11) ℚ)
      (w : Fin 640 → Matrix (Fin 9) (Fin 11) ℚ),
      ∀ a b c d e f, ∑ i, u i a b * v i c d * w i e f = if b = c ∧ a = e ∧ d = f then 1 else 0 :=
  ⟨u, v, w, rat_identity⟩

theorem exists_bilinear_algorithm :
    ∃ (u : Fin 640 → Matrix (Fin 9) (Fin 10) ℚ) (v : Fin 640 → Matrix (Fin 10) (Fin 11) ℚ)
      (w : Fin 640 → Matrix (Fin 9) (Fin 11) ℚ),
      ∀ (K : Type*) [Field K] [CharZero K] (A : Matrix (Fin 9) (Fin 10) K)
        (B : Matrix (Fin 10) (Fin 11) K),
        A * B = ∑ i, ((∑ a, ∑ b, (u i a b : K) * A a b) * (∑ c, ∑ d, (v i c d : K) * B c d)) •
          (w i).map (fun x : ℚ => (x : K)) :=
  ⟨u, v, w, fun K _ _ A B => bilinear K A B⟩

end MatMul9x10x11
