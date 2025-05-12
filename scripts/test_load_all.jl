println("Loading ODEParameterEstimation...")
using ODEParameterEstimation

# Check if multipoint_parameter_estimation function exists
if isdefined(ODEParameterEstimation, :multipoint_parameter_estimation)
    println("multipoint_parameter_estimation function exists!")
else
    println("ERROR: multipoint_parameter_estimation function not found!")
end

# Check if multishot_parameter_estimation function exists
if isdefined(ODEParameterEstimation, :multishot_parameter_estimation)
    println("multishot_parameter_estimation function exists!")
else
    println("ERROR: multishot_parameter_estimation function not found!")
end

println("Successfully loaded all functions!")