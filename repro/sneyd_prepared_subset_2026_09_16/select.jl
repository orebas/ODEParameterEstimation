# Exercise ODEPE's existing row selector on the complete prepared rational map.
using Pkg
Pkg.activate(get(ENV, "ODEPE_PETAB_ENV", "/tmp/odepe-petab-pilot-env"))
using ODEParameterEstimation, ModelingToolkit, Symbolics, OrderedCollections
using JSON, SHA, LinearAlgebra, Profile
using ModelingToolkit: t_nounits as t, D_nounits as D
const ODEPE = ODEParameterEstimation
length(ARGS) == 2 || error("Expected SYSTEM_JSON OUTPUT_DIRECTORY")
input_path, out = ARGS
mkpath(out)
input = JSON.parsefile(input_path)
Base.exit_on_sigint(false)
record = Dict{String,Any}("status"=>"building_pool", "profile_ready"=>true,
    "julia_version"=>string(VERSION), "odepe_version"=>string(pkgversion(ODEPE)),
    "input_sha256"=>bytes2hex(sha256(read(input_path))),
    "worker_sha256"=>bytes2hex(sha256(read(@__FILE__))),
    "manifest_sha256"=>bytes2hex(sha256(read(joinpath(dirname(Base.active_project()), "Manifest.toml")))),
    "truth_root_supplied"=>false, "parameter_elimination"=>false,
    "settings"=>Dict("compute_mixed_volume"=>false, "candidate_limit"=>64,
                     "beam_width"=>16, "rank_atol"=>1e-8, "n_rank_probes"=>3))
function checkpoint()
    open(joinpath(out,"result.json.tmp"),"w") do io; JSON.print(io,record,2); end
    mv(joinpath(out,"result.json.tmp"),joinpath(out,"result.json");force=true)
end
function stage!(name)
    record["status"]=name; checkpoint(); println("STAGE ",name); flush(stdout)
end
Profile.init(;n=10^7,delay=0.002)
Profile.set_peek_duration(5.0)
Profile.peek_report[] = () -> Profile.print(joinpath(out,"profile_$(time_ns()).txt");
    format=:flat,C=true,sortedby=:count)
checkpoint()

function rates(eta,c,p)
    L1,U1,V1,L5,U5,V5,k2,km2,l4,lm4,k3,km3 = eta
    L3=km2*l4/(k2*lm4)
    [(c*lm4+km2)/(c/L5+1), p*(c*l4+L3*k2)/(c*(1+L3/L1)+L3),
     c*U1/(c*(1+L1/L3)+L1), V1, c*U5/(c+L5), L1*V5/(c+L1),
     c*U1/(c+L1), L5*k3/(c+L5), km3]
end
function jets(f)
    f1,f2,f3,f4,f5,f6,f7,f8,f9=f; u=f2+f3; v=f1+f5+f8
    [f2/10, f2*(9*f5-u-v)/10,
     f2*(u^2+f1*f2+f4*f3+(v-9*f5)*(u+v)-8*f5*f6-9*f5*f7+f8*f9)/10]
end
function rational(s)
    values=split(s,"/")
    parse(BigInt,values[1]) // (length(values)==1 ? BigInt(1) : parse(BigInt,values[2]))
end
function polynomial(terms,variables)
    sum((parse(BigInt,term["numerator"]) // parse(BigInt,term["denominator"])) *
        prod(v^Int(e) for (v,e) in zip(variables,term["exponents"]);init=1)
        for term in terms;init=Num(0))
end

try
    @parameters L1 U1 V1 L5 U5 V5 b2 bm2 d4 dm4 b3 bm3
    variables=Num[L1,U1,V1,L5,U5,V5,b2,bm2,d4,dm4,b3,bm3]
    @assert string.(variables)==input["unknowns"]
    @variables A(t) I1(t) I2(t) O(t) R(t) S(t) z(t)
    f1,f2,f3,f4,f5,f6,f7,f8,f9=rates(variables,0.1,10.0)
    eqs=[D(A)~f4*I2+f5*O-(f6+f7)*A,
         D(I1)~f3*R-f4*I1, D(I2)~f7*A-f4*I2,
         D(O)~f2*R+f6*A+f9*S-(f1+f5+f8)*O,
         D(R)~f1*O-(f2+f3)*R+f4*I1, D(S)~f8*O-f9*S]
    model,measured=ODEPE.create_ordered_ode_system("sneyd_prepared_metadata",
        [A,I1,I2,O,R,S],variables,eqs,[z~(9*A+O)/10])
    # The selector uses only symbol roles from this model. Known preparation
    # has already been substituted into every jet; no anchor states are solved.
    pep=ODEPE.ParameterEstimationProblem("sneyd_prepared_metadata",model,measured,
        OrderedDict{Union{Num,String},Vector{Float64}}(),[0.0,1.0],
        ODEPE.package_wide_default_ode_solver,OrderedDict{Num,Float64}(),
        OrderedDict{Num,Float64}(),0)
    data=Num[Symbolics.variable(Symbol("z_$(row["order"])_pt$(row["condition_index"] )")) for row in input["rows"]]
    rational_jets=Num[jets(rates(variables,Float64(rational(row["Ca"])),
        Float64(rational(row["IP3"]))))[Int(row["order"])] for row in input["rows"]]
    metadata=ODEPE.NoiseEqMeta[(point=Int(row["condition_index"]),source_index=i,
        max_observed_order=Int(row["order"]),support_score=0.0) for (i,row) in enumerate(input["rows"])]
    pool=(symbolic_equations=Any[rational_jets[i]-data[i] for i in eachindex(data)],
          instantiated_equations=Any[rational_jets...],instantiated_vars=Any[variables...],
          metadata=metadata,template_DD=nothing,full_equation_count=27,n_points=9)
    materialized=Ref{Any}(nothing)
    function materialize(pool)
        stage!("materialize_polynomials")
        polys=Any[polynomial(row["numerator"],variables)-data[i]*polynomial(row["denominator"],variables)
                  for (i,row) in enumerate(input["rows"])]
        meta=ODEPE.NoiseEqMeta[(;pool.metadata[i]...,
             support_score=length(Symbolics.get_variables(poly))+0.001*length(string(poly)))
             for (i,poly) in enumerate(polys)]
        materialized[]=(;pool...,symbolic_equations=polys,metadata=meta)
        record["polynomial_support_scores"]=[m.support_score for m in meta]
        stage!("candidate_selection")
        materialized[]
    end
    record["operation_started_ns"]=time_ns();stage!("rational_rank_and_selection")
    selected=@timed ODEPE._noise_select_pool(pep,pool;
        compute_mixed_volume=false,candidate_limit=64,beam_width=16,
        rank_atol=1e-8,n_rank_probes=3,diagnostics=true,materialize_polynomials=materialize)
    frontier=selected.value
    record["selection_seconds"]=selected.time
    record["selection_compile_seconds"]=selected.compile_time
    record["frontier"]=frontier.frontier
    record["candidates"]=ODEPE.noise_frontier_rows(frontier)
    ODEPE.write_noise_frontier_csv(joinpath(out,"candidates.csv"),frontier)
    isnothing(frontier.selected) && error("No square full-rank candidate")
    best=frontier.selected
    record["selected_rows"]=best.selected_equation_indices
    record["selected_solve_variables"]=string.(best.solve_vars)
    record["selected_data_variables"]=string.(best.data_vars)
    record["selected_conditions_orders"]=[Dict("row"=>i,"condition"=>input["rows"][i]["condition_id"],
        "order"=>input["rows"][i]["order"],"degree"=>input["rows"][i]["solve_degree"],
        "terms"=>input["rows"][i]["terms_after_data_substitution"]) for i in best.selected_equation_indices]
    @assert best.is_square && best.rank_complete && length(best.solve_vars)==12
    stage!("complete")
    println("SELECTED ",best.selected_equation_indices);flush(stdout)
catch err
    record["error"]=sprint(showerror,err,catch_backtrace());stage!("failed")
    rethrow()
end
