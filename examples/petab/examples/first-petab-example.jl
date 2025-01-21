using ModelingToolkit
using PEtab, OrdinaryDiffEq, DataFrames, Plots, Optim
using ModelingToolkit: t_nounits as t, D_nounits as D


function petab_example()

	@mtkmodel Growth begin
		@parameters begin
			k = 1.0
		end
		@variables begin
			x(t) = 1.0
		end
		@equations begin
			D(x) ~ k * x
		end
	end


	@mtkbuild sys = Growth()

	# 2. Simulate synthetic data using "true" parameter k = 0.5
	prob = ODEProblem(sys, [], (0.0, 5.0), [sys.k => 0.5])
	times = 0.0:0.5:5.0
	sol = solve(prob, Tsit5(), saveat = times)


	# Add some noise to create synthetic measurements
	measurements = DataFrame(
		obs_id = "obs_x",             # Name of the observable
		time = times,                 # Measurement times
		measurement = sol[sys.x] .+ 0.1 .* randn(length(times)),  # Add noise
	)

	# 3. Create PEtab problem components
	# Observable (the state x with unknown noise parameter sigma)
	@parameters sigma
	obs = PEtabObservable(sys.x, sigma)
	observables = Dict("obs_x" => obs)

	# Parameters to estimate (k and noise σ)
	p_k = PEtabParameter(:k)  # Growth rate
	p_sigma = PEtabParameter(:sigma)  # Measurement noise
	pest = [p_k, p_sigma]

	# 4. Create and solve the PEtab problem
	model = PEtabModel(sys, observables, measurements, pest)
	petab_prob = PEtabODEProblem(model)

	# 5. Estimate parameters using multi-start
	result = calibrate_multistart(petab_prob, IPNewton(), 10)

	# 6. Plot results
	plot(result, petab_prob)

end

petab_example()
