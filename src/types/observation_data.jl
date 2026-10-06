"""
    ObservationSeries(name, experiment, quantity, times, values; noise_std = nothing)

One measured series with its own time points.

# Arguments
- `name`: a label for the series.
- `experiment`: a label for the experiment it belongs to.
- `quantity`: what was measured, as an expression in the model's states, such
  as `x1` or `x1 + x2`.
- `times`, `values`: the measurements. They are copied and sorted by time. A
  time may appear more than once.
- `noise_std`: the standard deviation of the noise in each value, if you know
  it. It is kept with the series. Estimation does not use it.
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
    ObservationData(series; initial_time = 0.0)

Measurements in which each series has its own time points. Pass one as `data`
to [`ParameterEstimationProblem`](@ref) in place of a table.

# Arguments
- `series`: a vector of [`ObservationSeries`](@ref).
- `initial_time`: the time at which initial conditions are reported. It cannot
  be later than the first measurement.

The series have to overlap in time, because the equations are solved inside the
interval that all of them cover. Gaps are not filled in and repeated
measurements are not averaged. Uncertainty (`compute_uncertainty`) is not
available for data of this kind.
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

"""
    observation_times(data, quantity)

The times at which `quantity` was measured.
"""
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
