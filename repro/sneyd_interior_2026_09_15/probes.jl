# Bounded isolated versions of the earlier SI and multiplicity requests.
function run_probe(pep, phase)
    si = ODEPE.StructuralIdentifiability
    n = ODEPE.Nemo
    scaled, _ = ODEPE.rescale_pep(pep)
    if phase == "denominators"
        # The old eager path stalled clearing the second Lie derivative before
        # representative fixing. Recreate that request with either observation,
        # using unchanged current clear_denoms, not a new simplification method.
        dynamics = Dict(Num(only(S.arguments(S.value(eq.lhs))))=>Num(eq.rhs)
            for eq in MTK.equations(scaled.model.system))
        jet = Num(only(scaled.measured_quantities).rhs)
        record["derivative_steps"] = Any[]
        for order in 1:2
            record["status"] = "differentiating_order_$order"
            checkpoint()
            trial = @timed sum(S.derivative(jet,x)*dynamics[Num(x)] for x in scaled.model.original_states)
            jet = trial.value
            push!(record["derivative_steps"],(; order,seconds=trial.time,bytes=trial.bytes,
                compile_seconds=trial.compile_time,text_length=length(string(jet))))
            checkpoint()
        end
        write(joinpath(out,"second_lie_derivative.txt"),string(jet))
        record["status"] = "clearing_denominators_order_2"
        record["clear_denoms_started_ns"] = time_ns()
        checkpoint()
        trial = @timed ODEPE.clear_denoms(jet ~ S.variable(:probe_y2))
        record["probe_seconds"] = trial.time
        record["probe_compile_seconds"] = trial.compile_time
        record["probe_bytes"] = trial.bytes
        record["cleared_text_length"] = length(string(trial.value))
        write(joinpath(out,"cleared_second_derivative.txt"),string(trial.value))
        checkpoint()
        return nothing
    end
    ode, _, _ = ODEPE.convert_to_si_ode(scaled.model,scaled.measured_quantities)
    quantities = vcat(ode.parameters,ode.x_vars)
    record["si_model"] = (; parameters=string.(ode.parameters), states=string.(ode.x_vars),
        dynamics=Dict(string(k)=>string(v) for (k,v) in ode.x_equations),
        observations=Dict(string(k)=>string(v) for (k,v) in ode.y_equations))
    Random.seed!(STUDY_SEED)
    record["status"] = phase
    record["probe_started_ns"] = time_ns()
    checkpoint()
    measurement = if phase == "global"
        @timed si.assess_identifiability(ode; funcs_to_check=quantities,
            prob_threshold=0.99, loglevel=Logging.Info)
    elseif phase == "functions"
        @timed si.find_identifiable_functions(ode; simplify=:absent,
            with_states=false, prob_threshold=0.99, seed=42, loglevel=Logging.Info)
    elseif phase == "local"
        basis = n.QQMPolyRingElem[]
        trial = @timed si.assess_local_identifiability(ode; funcs_to_check=quantities,
            prob_threshold=0.999,type=:SE,trbasis=basis,loglevel=Logging.Info)
        record["coordinate_basis"] = string.(basis)
        trial
    elseif phase == "multiplicity"
        # Use the same production prefix and input preparation as the earlier
        # fixed-input inspection; do not reimplement rank/jet construction.
        source_path = joinpath(dirname(dirname(pathof(ODEPE))),"src/core/si_equation_builder.jl")
        source = read(source_path,String)
        start = first(findfirst("function get_polynomial_system_from_sian(",source))
        stop = first(findnext("\t# Count solutions of the representative-fixed ideal",source,start))-1
        body = replace(source[start:stop], "function get_polynomial_system_from_sian("=>
            "function inspect_root_comparison_multiplicity(",count=1)
        body *= "\treturn _prepare_sian_multiplicity_system(si_ode, Et, Q, X_eq, Y_eq, all_params, sample, D1; pre_fixed_params)\nend\n"
        write(joinpath(out,"construction_prefix.jl"),body)
        Base.include_string(ODEPE,body,"inspect_root_comparison_multiplicity.jl")
        # Freeze the earlier rational coordinate slice in BOTH observation arms.
        # Generic local identifiability is checked below; positivity is separate.
        fixed_names = model_kind == "rational" ?
            ["l2","k_4","k_3","k_2","k_1","k4","k3","k2","k1"] :
            ["phi1","phi2","phi3","phi4"]
        fixes = OD(name=>1.0 for name in fixed_names)
        construction = @timed Base.invokelatest(ODEPE.inspect_root_comparison_multiplicity,
            ode,quantities;pre_fixed_params=fixes)
        input = construction.value
        verified = all(p->iszero(n.evaluate(p,input.point)),input.polynomials)
        @assert verified
        polynomials = [[(; numerator=string(n.numerator(c)),denominator=string(n.denominator(c)),exponents=e)
            for (c,e) in zip(n.coefficients(p),n.exponent_vectors(p))] for p in input.polynomials]
        write_json(joinpath(out,"multiplicity_input.json"),(; variables=string.(n.gens(input.ring)),
            polynomials, sample=string.(input.point)))
        record["multiplicity_input"] = (; equations=length(polynomials),unknowns=n.ngens(input.ring),
            monomials=sum(length,polynomials), max_degree=maximum(n.total_degree,input.polynomials),
            jacobian_rank=input.jacobian_rank, linearized_dimension=n.ngens(input.ring)-1-input.jacobian_rank,
            fixed_coordinates=input.fixed_coordinates, sample_verified=verified,
            construction_seconds=construction.time, compile_seconds=construction.compile_time)
        record["status"] = "groebner"
        record["groebner_started_ns"] = time_ns()
        checkpoint()
        trial = @timed ODEPE.Groebner.groebner(input.polynomials)
        record["basis_length"] = length(trial.value)
        dim = ODEPE.Groebner.dimension(trial.value)
        record["dimension"] = dim
        record["multiplicity"] = dim == 0 ? length(ODEPE.Groebner.quotient_basis(trial.value)) : nothing
        write_json(joinpath(out,"groebner_basis.json"),string.(trial.value))
        trial
    else
        error("Unknown probe phase: $phase")
    end
    record["probe_seconds"] = measurement.time
    record["probe_compile_seconds"] = measurement.compile_time
    phase == "multiplicity" || (record["probe_result"] = phase == "functions" ? string.(measurement.value) : measurement.value)
    checkpoint()
end
