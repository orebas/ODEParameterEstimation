`crauste_revised` exposed a real contract mismatch between the SI template layer and ODEPE's current numeric derivative backend.

What happens:
- the normal setup/advisory layer asks for only modest observable derivative depths
  - for `crauste_revised`: `Dict(1 => 6, 2 => 5, 3 => 6, 4 => 0)`
- the SI template returned by `SI.jl` asks for observable derivatives up to order `22`
- ODEPE then tries to instantiate those template variables numerically at a shooting point via `nth_deriv(...)`
- `nth_deriv(...)` currently uses `TaylorDiff.derivative(f, t, Val(n))`
- TaylorDiff's generated code multiplies by `factorial(P)`, which overflows for `Int` at `P = 21`

So the immediate crash is:
- implementation-level: `factorial(Int)` overflow inside TaylorDiff

But the deeper issue is:
- ODEPE's interpolation-based numeric derivative path is not intended to support SI templates that require derivatives beyond about `20`, and in practice derivatives above roughly `5-8` are already suspect numerically for interpolated data

Current package policy:
- treat `n > 20` as an explicit unsupported derivative-order request for the current TaylorDiff-backed numeric derivative path
- fail early with `UnsupportedDerivativeOrderError`
- do not present this as a mysterious SI or Symbolics bug

Implications:
- `crauste_revised` is best classified as a high-order SI-template derivative limitation
- this is distinct from:
  - unsupported raw nonlinear model classes like raw `sqrt(...)` or `sin(state)`
  - SI-template non-squareness
  - advisory/nullspace failures

Potential future directions, not implemented here:
- different numeric derivative backend for very high orders
- avoid numeric instantiation of such high-order derivative symbols entirely
- upstream/template-level controls that reduce derivative order demand
- optional heuristic refusal when SI asks for derivative orders well beyond the numerically trustworthy regime
