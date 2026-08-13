# UQ coverage smoke (Stream B item 2, 2026-08-13): N=20 two_exp replicates of
# the full UQ chain (noisy draw → NLS-polish estimate → GP jets → Σ_d →
# estimate-conditioned S → Σ_x → physicalized report) with loose tripwire
# bands, so calibration breakage turns the full gate red.
#
# Bands are BREAKAGE tripwires, not calibration assertions — set from the
# 2026-08-13 baseline (100% coverage, mean z ≈ 0, sd z ≈ 0.46 on every
# coordinate; see repro/uq_coverage_harness_2026_08/README.md) minus generous
# margin. Paper-grade numbers come from N ≥ 100 runs of the repro driver.

using Test
using Statistics

include(joinpath(@__DIR__, "..", "repro", "uq_coverage_harness_2026_08", "coverage_driver.jl"))

@testset "UQ coverage smoke (two_exp, N=20, estimate-conditioned)" begin
	res = run_coverage(two_exp_pep;
		N = 20, noise_level = 0.01, datasize = 61,
		time_interval = [0.0, 1.0], seed0 = 7000)

	# The 2026-06-30 crash class ("No successful audit trials") — replicates
	# must actually produce reports.
	@test res.n_reported >= 18

	for label in ["k1", "k2", "x1", "x2"]
		@test label in res.labels
		zv = get(res.zs, label, Float64[])
		# σ̂ finite and nonzero on nearly every reporting replicate
		@test get(res.usable, label, 0) >= 18
		# Coverage tripwire (baseline 100% at nominal 95%)
		@test coverage_fraction(res, label) >= 0.7
		# Center corruption tripwire (baseline |mean z| ≤ 0.1)
		@test abs(mean(zv)) <= 1.0
		# σ̂ degeneracy tripwires: collapse (sd z ≫ 1) or blow-up (sd z ≈ 0)
		@test 0.05 <= std(zv) <= 2.5
	end
end
