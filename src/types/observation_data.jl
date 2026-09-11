"""
    ObservationSeries(observable_id, experiment_id, expression, times, values; noise_std=nothing)

Measurements of one signal in one experiment. Times may repeat; each row remains
an observation. Values are in the units of `expression`, before any likelihood
transformation. `noise_std`, when supplied, is in those same units.

# Arguments
- `expression`: symbolic observable in the experiment's state variables.
- `times`, `values`: equally sized, finite vectors; copied and sorted by time.

# Returns
An owned series with optional known per-row standard deviations.
"""
struct ObservationSeries
    observable_id::String
    experiment_id::String
    expression::Num
    times::Vector{Float64}
    values::Vector{Float64}
    noise_std::Union{Nothing, Vector{Float64}}

    function ObservationSeries(observable_id::AbstractString, experiment_id::AbstractString,
            expression, times::AbstractVector, values::AbstractVector; noise_std=nothing)
        length(times) == length(values) || throw(DimensionMismatch("Observation times and values must have equal lengths"))
        isempty(times) && throw(ArgumentError("An observation series must contain data"))
        ts, ys = Float64.(times), Float64.(values)
        all(isfinite, ts) && all(isfinite, ys) || throw(ArgumentError("Observations must have finite times and values"))
        ns = isnothing(noise_std) ? nothing : Float64.(noise_std)
        if !isnothing(ns)
            length(ns) == length(ts) || throw(DimensionMismatch("One noise standard deviation is required per observation"))
            all(x -> isfinite(x) && x > 0, ns) || throw(ArgumentError("Noise standard deviations must be finite and positive"))
        end
        order = sortperm(ts)
        new(String(observable_id), String(experiment_id), Num(expression), ts[order], ys[order],
            isnothing(ns) ? nothing : ns[order])
    end
end

"""
    ObservationData(series; initial_time=0.0)

Independent observation grids with an explicit physical initial epoch. The
dictionary interface preserves the legacy observable lookup, but `data["t"]`
is only the algebraic anchor grid in the common observed interval. Use
`observation_times(data, expression)` for actual measurement times. No missing
values are filled and no repeated measurements are averaged.

# Arguments
- `series`: observation series whose expressions use experiment-local states.
- `initial_time`: epoch at which estimated state initial values are reported.

# Returns
Data for `ParameterEstimationProblem`. Identical expressions are pooled only for
interpolation; the original series and row identities remain available.
"""
struct ObservationData <: AbstractDict{Union{String, Num}, Vector{Float64}}
    series::Vector{ObservationSeries}
    columns::OrderedDict{Union{String, Num}, Vector{Float64}}
    times::Dict{Num, Vector{Float64}}
    initial_time::Float64

    function ObservationData(series::AbstractVector{ObservationSeries}; initial_time::Real=0.0)
        isempty(series) && throw(ArgumentError("At least one observation series is required"))
        owned = deepcopy(collect(series))
        columns = OrderedDict{Union{String, Num}, Vector{Float64}}()
        times = Dict{Num, Vector{Float64}}()
        for s in owned
            append!(get!(columns, s.expression, Float64[]), s.values)
            append!(get!(times, s.expression, Float64[]), s.times)
        end
        for key in keys(times)
            order = sortperm(times[key])
            times[key] = times[key][order]
            columns[key] = columns[key][order]
        end
        epoch = Float64(initial_time)
        isfinite(epoch) && epoch <= minimum(first, values(times)) ||
            throw(ArgumentError("initial_time must be finite and no later than the first observation"))
        left, right = maximum(first, values(times)), minimum(last, values(times))
        left < right || throw(ArgumentError("Algebraic interpolation needs an observed interval common to all signals"))
        grid = sort!(unique!(reduce(vcat, values(times))))
        columns["t"] = filter(x -> left <= x <= right, grid)
        new(owned, columns, times, epoch)
    end
end

Base.length(data::ObservationData) = length(data.columns)
Base.iterate(data::ObservationData, state...) = iterate(data.columns, state...)
Base.getindex(data::ObservationData, key) = data.columns[key]
Base.haskey(data::ObservationData, key) = haskey(data.columns, key)
Base.keys(data::ObservationData) = keys(data.columns)
Base.copy(data::ObservationData) = deepcopy(data)

"""Actual observation times for a signal (including repeated times)."""
observation_times(data::AbstractDict, key) = data["t"]
observation_times(data::ObservationData, key) = data.times[Num(key)]
_initial_time(data::AbstractDict) = first(data["t"])
_initial_time(data::ObservationData) = data.initial_time
_observation_union(data::AbstractDict) = data["t"]
_observation_union(data::ObservationData) = sort!(unique!(reduce(vcat, values(data.times))))

function _validate_observation_options(data, opts)
    if data isa ObservationData && opts.compute_uncertainty
        throw(ArgumentError("Uncertainty quantification for independent observation grids is not implemented; use compute_uncertainty=false."))
    end
    return nothing
end

"""
    load_petab_problem(path; kwargs...)

Load a PEtab problem for algebraic candidate generation and faithful likelihood
scoring. Load the optional PEtab.jl dependency first (`using PEtab`).
"""
function load_petab_problem end

"""
    estimate_petab_problem(problem; options=EstimationOptions(), kwargs...)

Generate algebraic candidates and score them with the original PEtab objective.
Optional numerical refinement must retain all PEtab-estimated parameters.
"""
function estimate_petab_problem end
