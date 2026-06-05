# Variable-aware trim probes for receptor.
#
# The old trim probes sort equations by a static equation score and then run a
# rank-greedy basis selection. This probe treats the cost as a marginal cost of
# newly introduced variables. That matters for noisy data: using y1_7 once is the
# expensive event; using it in a second equation is not a second independent
# derivative-estimation cost.
#
# Run:
#   julia --startup-file=no repro/receptor_fast_probes_2026_05_28/variable_cost_trim_probe.jl

include("common.jl")
using .ReceptorFastProbes
using Dates
using LinearAlgebra
using Printf
using Random
using Symbolics

const STATE_JET_BASES = Set(["L", "Ca", "Cb", "S", "Delta"])

function parse_data_var(v)
    text = string(v)
    if occursin("y1", text)
        channel = "y1"
    elseif occursin("y2", text)
        channel = "y2"
    else
        return nothing
    end
    m = match(r"Differential\(t,\s*(\d+)\)", text)
    order = isnothing(m) ? 0 : parse(Int, m.captures[1])
    return (kind = "data", channel = channel, order = order)
end

function parse_solve_var(v)
    text = string(v)
    m = match(r"^([A-Za-z0-9]+)_(\d+)$", text)
    if isnothing(m)
        return (kind = "solve_other", channel = text, order = 0)
    end
    base = m.captures[1]
    order = parse(Int, m.captures[2])
    if base in STATE_JET_BASES
        return (kind = "state_jet", channel = base, order = order)
    end
    return (kind = "parameter", channel = base, order = 0)
end

function token_for_var(S, v)
    for data_var in S.data_vars
        if isequal(data_var, v)
            p = parse_data_var(v)
            isnothing(p) && return nothing
            return "$(p.kind):$(p.channel):$(p.order)", p
        end
    end
    for solve_var in S.solve_vars
        if isequal(solve_var, v)
            p = parse_solve_var(v)
            return "$(p.kind):$(p.channel):$(p.order)", p
        end
    end
    return nothing
end

function variable_cost(prop)
    kind = prop.kind
    order = prop.order
    channel = prop.channel
    if kind == "data"
        weight = channel == "y1" ?
            env_float("ODEPE_RECEPTOR_COST_Y1", 1.0) :
            env_float("ODEPE_RECEPTOR_COST_Y2", 1.0)
        power = env_float("ODEPE_RECEPTOR_COST_DATA_POWER", 4.0)
        return weight * (order + 1)^power
    elseif kind == "state_jet"
        weight = env_float("ODEPE_RECEPTOR_COST_STATE_JET", 0.1)
        power = env_float("ODEPE_RECEPTOR_COST_STATE_POWER", 2.0)
        return weight * (order + 1)^power
    elseif kind == "parameter"
        return env_float("ODEPE_RECEPTOR_COST_PARAMETER", 0.01)
    end
    return env_float("ODEPE_RECEPTOR_COST_OTHER", 0.1)
end

function equation_variable_features(S)
    eqs = ReceptorFastProbes.canonicalize_data_placeholders(S, S.full_equations)
    prop_by_token = Dict{String, Any}()
    records = Vector{Any}(undef, length(eqs))
    for (i, eq) in enumerate(eqs)
        tokens = Set{String}()
        for v in Symbolics.get_variables(eq)
            parsed = token_for_var(S, v)
            isnothing(parsed) && continue
            token, prop = parsed
            push!(tokens, token)
            prop_by_token[token] = prop
        end
        data_orders = [prop_by_token[t].order for t in tokens if prop_by_token[t].kind == "data"]
        state_orders = [prop_by_token[t].order for t in tokens if prop_by_token[t].kind == "state_jet"]
        records[i] = (
            idx = i,
            tokens = tokens,
            max_data_order = isempty(data_orders) ? -1 : maximum(data_orders),
            max_state_order = isempty(state_orders) ? -1 : maximum(state_orders),
            data_tokens = sort([t for t in tokens if prop_by_token[t].kind == "data"]),
            state_tokens = sort([t for t in tokens if prop_by_token[t].kind == "state_jet"]),
            param_tokens = sort([t for t in tokens if prop_by_token[t].kind == "parameter"]),
            solve_var_count = count(t -> prop_by_token[t].kind != "data", tokens),
            text_len = length(string(eq)),
        )
    end
    return records, prop_by_token
end

function rank_of_rows(J, rows)
    isempty(rows) && return 0
    return rank(J[collect(rows), :]; atol = 1e-9)
end

function allowed_indices(features; max_data_order = nothing, max_state_order = nothing)
    allowed = Int[]
    for f in features
        if !isnothing(max_data_order) && f.max_data_order > max_data_order
            continue
        end
        if !isnothing(max_state_order) && f.max_state_order > max_state_order
            continue
        end
        push!(allowed, f.idx)
    end
    return allowed
end

function summarize_introduced(tokens, prop_by_token)
    data = sort([t for t in tokens if prop_by_token[t].kind == "data"])
    state = sort([t for t in tokens if prop_by_token[t].kind == "state_jet"])
    params = sort([t for t in tokens if prop_by_token[t].kind == "parameter"])
    data_orders = [prop_by_token[t].order for t in data]
    state_orders = [prop_by_token[t].order for t in state]
    return Dict{String, Any}(
        "introduced_data" => data,
        "introduced_state_jets" => state,
        "introduced_parameters" => params,
        "introduced_data_count" => length(data),
        "introduced_state_jet_count" => length(state),
        "introduced_parameter_count" => length(params),
        "max_introduced_data_order" => isempty(data_orders) ? -1 : maximum(data_orders),
        "max_introduced_state_order" => isempty(state_orders) ? -1 : maximum(state_orders),
        "introduced_cost" => sum((variable_cost(prop_by_token[t]) for t in tokens); init = 0.0),
    )
end

function dynamic_variable_trim(J, features, prop_by_token, allowed;
        target_rank::Int = size(J, 2), tie_policy::Symbol = :support)
    selected = Int[]
    introduced = Set{String}()
    remaining = Set(allowed)
    current = zeros(Float64, 0, size(J, 2))
    current_rank = 0

    while current_rank < target_rank
        best = nothing
        best_key = nothing
        for idx in sort(collect(remaining))
            trial = vcat(current, J[idx:idx, :])
            trial_rank = rank(trial; atol = 1e-9)
            trial_rank > current_rank || continue
            f = features[idx]
            new_tokens = setdiff(f.tokens, introduced)
            marginal_cost = sum((variable_cost(prop_by_token[t]) for t in new_tokens); init = 0.0)
            marginal_data_orders = [prop_by_token[t].order for t in new_tokens if prop_by_token[t].kind == "data"]
            marginal_state_orders = [prop_by_token[t].order for t in new_tokens if prop_by_token[t].kind == "state_jet"]
            max_new_data = isempty(marginal_data_orders) ? -1 : maximum(marginal_data_orders)
            max_new_state = isempty(marginal_state_orders) ? -1 : maximum(marginal_state_orders)
            key = if tie_policy == :data_order
                (max_new_data < 0 ? 99 : max_new_data,
                    marginal_cost,
                    max_new_state < 0 ? 99 : max_new_state,
                    length(new_tokens),
                    f.solve_var_count,
                    f.text_len,
                    idx)
            else
                (marginal_cost,
                    max_new_data < 0 ? 99 : max_new_data,
                    max_new_state < 0 ? 99 : max_new_state,
                    length(new_tokens),
                    f.solve_var_count,
                    f.text_len,
                    idx)
            end
            if isnothing(best_key) || key < best_key
                best = idx
                best_key = key
            end
        end
        isnothing(best) && break
        push!(selected, best)
        union!(introduced, features[best].tokens)
        current = vcat(current, J[best:best, :])
        current_rank = rank(current; atol = 1e-9)
        delete!(remaining, best)
    end
    return (selected = selected, rank = current_rank, introduced = introduced)
end

function trim_record(S, J, features, prop_by_token; label, max_data_order = nothing,
        max_state_order = nothing, tie_policy::Symbol = :support, compute_mixed_volume::Bool = false)
    allowed = allowed_indices(features; max_data_order = max_data_order, max_state_order = max_state_order)
    allowed_rank = rank_of_rows(J, allowed)
    trim = dynamic_variable_trim(J, features, prop_by_token, allowed;
        target_rank = length(S.solve_vars), tie_policy = tie_policy)
    rec = Dict{String, Any}(
        "case" => label,
        "tie_policy" => string(tie_policy),
        "max_data_order_cap" => isnothing(max_data_order) ? nothing : max_data_order,
        "max_state_order_cap" => isnothing(max_state_order) ? nothing : max_state_order,
        "allowed_count" => length(allowed),
        "allowed_rank" => allowed_rank,
        "rank" => trim.rank,
        "rank_complete" => trim.rank == length(S.solve_vars),
        "selected_equation_indices" => trim.selected,
        "n_selected" => length(trim.selected),
    )
    merge!(rec, summarize_introduced(trim.introduced, prop_by_token))
    if compute_mixed_volume && rec["rank_complete"]
        ps = parameterized_system(S, S.full_equations[trim.selected]; scale = true)
        rec["mixed_volume"] = safe_mixed_volume(ps.system)
    end
    return rec
end

function main()
    out = output_path("variable_cost_trim.jsonl")
    S = receptor_setup()
    J = rank_matrix(S)
    features, prop_by_token = equation_variable_features(S)
    max_cap = env_int("ODEPE_RECEPTOR_VARTRIM_MAX_CAP", 10)
    compute_mv = env_bool("ODEPE_RECEPTOR_VARTRIM_MIXED_VOLUME", false)
    tie_policies = env_list("ODEPE_RECEPTOR_VARTRIM_TIES",
        [:support, :data_order]; parse_item = x -> Symbol(x))

    open(out, "w") do io
        write_jsonl(io, Dict(
            "case" => "metadata",
            "script" => basename(@__FILE__),
            "created_at" => string(now()),
            "n_full_equations" => length(S.full_equations),
            "n_solve_vars" => length(S.solve_vars),
            "max_cap" => max_cap,
            "compute_mixed_volume" => compute_mv,
            "costs" => Dict(
                "y1" => env_float("ODEPE_RECEPTOR_COST_Y1", 1.0),
                "y2" => env_float("ODEPE_RECEPTOR_COST_Y2", 1.0),
                "data_power" => env_float("ODEPE_RECEPTOR_COST_DATA_POWER", 4.0),
                "state_jet" => env_float("ODEPE_RECEPTOR_COST_STATE_JET", 0.1),
                "state_power" => env_float("ODEPE_RECEPTOR_COST_STATE_POWER", 2.0),
                "parameter" => env_float("ODEPE_RECEPTOR_COST_PARAMETER", 0.01),
            ),
        ))

        for tie_policy in tie_policies
            write_jsonl(io, trim_record(S, J, features, prop_by_token;
                label = "no_cap_dynamic",
                tie_policy = tie_policy,
                compute_mixed_volume = compute_mv))
            for cap in 0:max_cap
                write_jsonl(io, trim_record(S, J, features, prop_by_token;
                    label = "observed_cap",
                    max_data_order = cap,
                    tie_policy = tie_policy,
                    compute_mixed_volume = compute_mv))
            end
            for cap in 0:max_cap
                write_jsonl(io, trim_record(S, J, features, prop_by_token;
                    label = "joint_observed_state_cap",
                    max_data_order = cap,
                    max_state_order = cap,
                    tie_policy = tie_policy,
                    compute_mixed_volume = compute_mv))
            end
        end
    end

    println("Wrote ", out)
end

main()
