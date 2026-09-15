# Sneyd subsystem selection and the actual HC solve

This study follows the [polynomial zero-detection correction](2026-09-15_polynomial_zero_detection.md).
It changes **research harnesses only**, using the existing option
`construction_compute_mixed_volume=false`. Production equations, dependency
versions and default solver settings are unchanged.

## Selection without mixed-volume scoring

The ordinary dense single-condition run reaches the first generic-start HC
call when selection MV is disabled. The preceding SI template is exactly the
same ordered 72-polynomial template as before. Selection takes **109.542 seconds**
including compilation, chooses observed derivative cap **K = 10**, and hands HC
**72 equations, 72 unknowns and 11 data parameters**. The selected polynomials
also equal the saved SI template exactly, in order.

Package loading, import and simulation take 157.92 seconds; the intentional
capture occurs 343.44 seconds after entering estimation. These are instrumented
cold-run timings, not a controlled benchmark. The data are byte-identical to the
previous run, the model records match, and the only estimation-option difference
is `construction_compute_mixed_volume=true → false`. The same nine interpolators
are configured; capture stops during the first one, before any roots are solved.

The capture hook is a more-specific method loaded only by the research driver
in a fresh Julia process. It converts the actual selected equations using
ODEPE's normal HC converter, saves ordered exact coefficients/exponents and the
ordinary generic complex data vector, then raises an interrupt. The driver
records `captured_generic_system` as an intentional diagnostic stop. It does
not replace the installed package's production source.

## What makes this a large polynomial system

| Quantity | Count |
|---|---:|
| Free kinetic parameters (`l4,l6,l_2,l_4,l_6`) | 5 |
| Anchor states | 6 |
| Auxiliary state derivatives | 61 |
| ODE-derived polynomial equations | 61 |
| Observation equations, orders 0–10 | 11 |
| Monomials across the selected family | 2,362 |
| Largest equation | 272 monomials |
| Maximum degree in unknowns | 6 |

The degree histogram is 10 equations of degree 2, 10 of degree 3, 31 of degree
4, 10 of degree 5 and 11 of degree 6. State derivatives extend through order
11 for A and O, order 10 for R, S and I₂, and order 9 for I₁. The 61 dynamic
equations are **linear in all state/jet variables jointly when the five kinetic
parameters are fixed**. The underlying fixed-condition model is

```text
x′ = A(θ)x
w  = 4 O + 9 A_state
y  = w⁴ / 2500
```

Thus 72 is the size of an expanded jet representation, not the number of
independent physical quantities being estimated. Eliminating those auxiliaries
naively can increase coefficient degrees and support; a smaller variable count
alone is not a guarantee of an easier solve. The existing coefficient-counter
experiment exploits more structure than simple variable deletion.

## An exact denominator-domain complication

The selected HC family contains no denominator saturation equation. Set the
kinetic coordinates `l6 = l_6 = 0`: **42 of its 72 equations vanish identically**.
These parameter values are excluded from the rational ODE.

There are actual positive-dimensional solution families at these excluded
values, not just a rank loss with inconsistent remaining equations. Set all
A, R, I₁ and I₂ jets to zero as well. Every dynamic equation vanishes. The
observation equations reduce to the derivatives of `(4O)⁴/2500`: for nonzero
y₀ choose one nonzero O₀ from the quartic, then solve O₁,…,O₁₀ successively.
Each successive pivot coefficient is a nonzero multiple of O₀³. S jets and
O₁₁ remain free. `inspect_selected.py` verifies all these polynomial identities.

This extraneous locus predates the current trial. It is a reason to distinguish
the isolated roots in the original rational domain from the entire cleared
affine variety. It does not by itself quantify how much mixed-cell time or
tracking failure it causes. The exact M counter retains the denominator domain;
its **M = 544** must not be substituted for a polyhedral start-path count.

## Diagnostic scope and reproduction

The polyhedral attempt **fails after 946.77 seconds (15.78 minutes)**, before its
1,800-second watchdog expires. HC throws
`OverflowError: Cannot compute a start system.` from
`PolyhedralStartSolutionsIterator`. No final mixed volume, start-path count or
tracked estimation root is returned. The last displayed partial volume is
538,860; this is **not a completed MV, an established lower bound, or M**.

The exception is a generic HC wrapper: the installed implementation throws it
when `fine_mixed_cells` returns `nothing` or an empty cell list. The backend can
return `nothing` after exhausting ten lifting attempts, or after catching an
`InexactError` or `SingularException`. The retained exception does not distinguish
those cases. Thus this is an actual start-system construction failure, not a
timeout and not proof that the final MV exceeds an integer range. Internal
lifting retries can also reset the displayed partial volume. This was one
ordinary HC setup call; its own backend can make multiple lifting attempts.

The completed monodromy outcomes are:

| Attempt | Outcome | Measured operation time |
|---|---|---:|
| Automatic start search | No start after 100 Newton attempts; no loops | 148.80 s |
| Supplied exact reference, unscaled | `invalid_startvalue`; zero roots, no loops | 240.62 s |
| Same reference, normalized | `invalid_startvalue`; zero roots, no loops | 339.68 s |

Automatic start search itself takes 147.85 seconds, of which 147.49 seconds
are reported as compilation. The two monodromy calls take 201.67 and 299.95
seconds; the full operation times also include start evaluation and validation.
Their retained workers do not record a separate monodromy compilation total,
but sampled stacks show substantial LLVM compilation. The final reusable worker
records that total and skips unnecessary certification work on an empty list.

`complete` in a worker/supervisor record means the diagnostic returned normally;
the two supplied-start calls still have the solver return code
`invalid_startvalue`. HC's monodromy start check tries tracking at the same
parameter vector before accepting a supplied root. The aggregate return code
does not retain the underlying tracker rejection reason. The exact polynomial
identity checks prove that the rational reference is a root; they do not imply
that the Float64 tracker can validate it. No loop-performance or completeness
conclusion follows from these attempts.

The polyhedral arm builds one ordinary affine polyhedral start system at the
captured generic data vector, with a 1,800-second operation budget. Unlike the
torus-only MV used in selection, HC's default affine start construction can
augment supports with the origin to include zero-coordinate roots. Its internal
regeneration progress values are not a completed MV or a solution count.
If setup finishes, the driver streams the same HC paths serially with
`ResultIterator`, avoiding an up-front allocation of every start vector.

The first monodromy arm allows 100 random Newton start-pair attempts, without
supplied truth or a root-count target. A second arm supplies one exact synthetic
jet from the independent kinetic reference `(2,3,5,7,11)` and state reference
`(2,3,5,7,11,13)`. All 72 polynomials vanish exactly there. A third arm uses the
same reference and polynomial support after exact invertible column, data and
row scaling. This scaling is a research comparison, not the production
column-scaling policy. Each monodromy arm has a 600-second operation budget.

The unscaled reference's Float64 absolute residual is about 12.97 and its
Jacobian condition estimate is 4.91 × 10²⁷ despite its exact rational residual
being zero. After normalization those measurements are 6.38 × 10⁻¹⁶ and
2.03 × 10¹⁴. These are coordinate-dependent numerical diagnostics; the smaller
condition estimate still indicates a difficult local problem.

All solver arms use Julia 1.13, HC 2.22.4, one Julia thread, `compile=:all` and
seed 20260915. The operation watchdog uses a monotonic clock and includes
compilation/start search, with a 20-second interrupt grace period. Monodromy
retains its usual heuristic duplicate checking, ten loops without progress,
and no target count or symmetry quotient. Root certification, where possible,
is recorded separately from completeness. See the
[HC monodromy documentation](https://www.juliahomotopycontinuation.org/HomotopyContinuation.jl/stable/monodromy/)
for that distinction.

## Consequence for the next step

Skipping selection MV removes the immediate selection bottleneck, but does not
make this representation ready for estimation. The longer polyhedral attempt
fails internally, and the tested monodromy settings cannot validate a starting
root. These experiments do not establish that Sneyd is intrinsically too large
or that monodromy could never work; they do establish that neither route is a
working shortcut with the current expanded system and settings.

The next model-specific investigation should use the linear state matrix and
fourth-power observation structure, preserve the original denominator domain,
and compare a compact formulation against these exact saved equations before
attempting noisy data. The existing characteristic-coefficient counter provides
a starting point, but turning it into an estimator is additional work. Simply
raising limits again, changing the default solver to monodromy, or treating
M = 544 as an HC stopping target is not justified by these results.

Scripts and exact input/output artifacts are in
[`repro/sneyd_hc_2026_09_15`](../repro/sneyd_hc_2026_09_15/README.md).
Small harness checks solve x² − p = 0 by both routes: two polyhedral endpoints,
two monodromy roots and two certified distinct roots. Exact coefficient
roundtrips, template identity, known-start identities and normalization
identities are checked independently. No production test gate is rerun for
these research-only changes; the preceding production commit's full gate
passed 2,281 tests.
