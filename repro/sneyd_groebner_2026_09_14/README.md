# Standalone Sneyd Gröbner reproducer

`mwe.jl` embeds the complete rational polynomial input and calls
`Groebner.groebner(F)` with the production defaults. The file can be copied
and shared by itself. Its only external dependencies are Nemo and Groebner;
it does not load ODEParameterEstimation, SIAN, StructuralIdentifiability,
GaussianProcesses, or PEtab.

From the repository root, install the two dependencies into this separate
environment, then run:

```sh
julia --startup-file=no --project=repro/sneyd_groebner_2026_09_14 -e 'using Pkg; Pkg.instantiate()'
julia --startup-file=no --threads=1 --project=repro/sneyd_groebner_2026_09_14 repro/sneyd_groebner_2026_09_14/mwe.jl
```

The supplied project pins the versions used in the original investigation:
Nemo 0.56.1 and Groebner 0.10.9, tested on Julia 1.13. It is separate from
the package/global environments. No time limit is imposed by the script;
Ctrl-C prints elapsed Gröbner time and propagates the interruption.

For a quick input check without computing a basis, append `--check` to the
second command. The script verifies a SHA-256 of the canonical polynomial
strings, including every rational coefficient, and checks the input sizes:

- Field ℚ, degree-reverse-lexicographic variable ordering preserved.
- 74 polynomials, including denominator saturation zQ − 1.
- 73 variables, 2,706 terms, maximum total degree 6.
- The nine representative parameter assignments have already been applied.

## Input provenance

This is the retained **inspection sample, seed 20260914**, from
`../fixed_multiplicity_2026_09_14/evidence/input/fixed_polynomials.txt`, with
variable ordering from its companion `fixed.toml`. The timed-out production
run used the same construction, fixes, and polynomial sizes with a different
synthetic sample. Its exact coefficients were not captured. This script
preserves the inspection coefficients exactly; it is not a byte-for-byte
replay of the earlier production input.

The integer coefficient literals use `big"..."` so rational arithmetic
cannot overflow before values enter Nemo. `source.json` records the source
dump, metadata, canonical polynomial, and script hashes.

## Validation

The input-only check passed on Julia 1.13.0. A separate run with a 120s
external process limit was interrupted after 117.6s inside
`Groebner.groebner`, still in the initial modular F4 calculation
(`_groebner_guess_lucky_prime`), with no returned basis. This reproduces the
expensive phase without loading the estimation pipeline. The script itself
retains no time limit. `validation.json` and `validation.log.gz` preserve the
command, timings, and interruption stack.

See the [original investigation](../../docs/2026-09-14_fixed_multiplicity.md)
for the model, substitutions, and prior timeout evidence.
