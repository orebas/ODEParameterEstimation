# Counting Sneyd M separately

See the [implementation and result record](../../docs/2026-09-15_external_multiplicity.md)
for the exact scope, the linear-state reduction, and count limitations.

Use the existing optional PEtab environment. These commands do not resolve
dependencies. All output paths must be fresh.

```sh
python3 repro/separate_m_2026_09_15/build_counter.py /tmp/sneyd-counter

timeout --signal=INT --kill-after=30s 600s \
  julia --startup-file=no --compiled-modules=existing --threads=1 \
  repro/separate_m_2026_09_15/count_hc.jl \
  /tmp/sneyd-counter/counter.json /tmp/sneyd-monodromy 300

python3 repro/separate_m_2026_09_15/refine_counter.py \
  /tmp/sneyd-counter/counter.json /tmp/sneyd-monodromy/result.json \
  /tmp/sneyd-refined.json

timeout --signal=INT --kill-after=30s 300s \
  julia --startup-file=no --compiled-modules=existing --threads=1 \
  repro/coefficient_lifting_2026_09_14/count.jl \
  /tmp/sneyd-counter/counter_fixed.json /tmp/sneyd-counter/count.json

timeout --signal=INT --kill-after=30s 600s \
  julia --startup-file=no --compiled-modules=existing --threads=1 \
  repro/separate_m_2026_09_15/check_fibre.jl \
  /tmp/sneyd-counter/counter.json /tmp/sneyd-counter/counter_fixed.json \
  /tmp/sneyd-fibre-check.json
```

The first count is numerical root discovery with a heuristic stop. Its
Float64 reconstruction filter initially accepted 106 of 109 roots; the
separate 100-digit refinement validates all 109. The exact counter finds
quotient length 136. Preserve those stages separately when interpreting
the preliminary `provisional_M` fields.

The fibre checker reduces the observability and Jacobian determinants in
the finite quotient. It uses a prime with good basis coefficient denominators,
unchanged leading monomials, and unchanged quotient dimension. A determinant
that is a unit after this specialization is a unit over QQ. The underlying
QQ basis is computed by Groebner's default probabilistic algorithm.

The estimator can run independently of the side count:

```sh
python3 repro/petab/dense_single/supervise.py sneyd /tmp/sneyd-M-unknown \
  --seconds 1200 --multiplicity skip

python3 repro/petab/dense_single/supervise.py sneyd /tmp/sneyd-M-supplied \
  --seconds 600 --multiplicity 544
```

`skip` leaves M unknown. A positive integer supplies M and skips computation;
`auto` retains the default. The number 544 is specific to this fixed-condition,
representative-fixed, free-initial-state side experiment. It is not a count
for the original prepared, multi-condition PEtab problem.

Validation:

```sh
julia --startup-file=no test/current.jl test_si_multiplicity_fixing.jl
julia --startup-file=no test/current.jl
```
