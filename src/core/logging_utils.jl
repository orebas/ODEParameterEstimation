using Logging

"""
    configure_logging(level=Logging.Info)

Configure the logging level for ODEParameterEstimation.
Default level is Info, but can be set to Debug for more verbose output.

# Arguments
- `level`: Logging level (Logging.Debug, Logging.Info, Logging.Warn, or Logging.Error)

# Example
```julia
configure_logging(Logging.Debug) # Enable detailed debug messages
```
"""
function configure_logging(level=Logging.Info)
    logger = ConsoleLogger(stderr, level)
    global_logger(logger)
end

"""
    log_matrix(matrix, title; level=Logging.Debug)

Log a matrix with an informative title at the specified logging level.

# Arguments
- `matrix`: Matrix to be logged
- `title`: Title for the matrix log
- `level`: Logging level (default: Debug)
"""
function log_matrix(matrix, title; level=Logging.Debug)
    Logging.with_logger(ConsoleLogger(stderr, level)) do
        @logmsg level "$title:\n$(summary(matrix))"
        rows, cols = size(matrix)
        if rows <= 20 && cols <= 20
            for i in 1:rows
                row_str = join(["$(round(matrix[i,j], digits=5))" for j in 1:cols], "\t")
                @logmsg level "Row $i:\t$row_str"
            end
        else
            @logmsg level "Matrix too large to display completely"
            @logmsg level "First few elements: $(matrix[1:min(5,rows), 1:min(5,cols)])"
        end
    end
end

"""
    log_equations(equations, title; level=Logging.Debug)

Log a set of equations with an informative title at the specified logging level.

# Arguments
- `equations`: Collection of equations to be logged
- `title`: Title for the equations log
- `level`: Logging level (default: Debug)
"""
function log_equations(equations, title; level=Logging.Debug)
    Logging.with_logger(ConsoleLogger(stderr, level)) do
        @logmsg level "$title:"
        for (i, eq) in enumerate(equations)
            @logmsg level "Equation $i: $eq"
        end
    end
end

"""
    log_dict(dict, title; level=Logging.Debug)

Log a dictionary with an informative title at the specified logging level.

# Arguments
- `dict`: Dictionary to be logged
- `title`: Title for the dictionary log
- `level`: Logging level (default: Debug)
"""
function log_dict(dict, title; level=Logging.Debug)
    Logging.with_logger(ConsoleLogger(stderr, level)) do
        @logmsg level "$title:"
        for (key, value) in dict
            @logmsg level "  $key => $value"
        end
    end
end

# Enable debug logging if environment variable is set
if haskey(ENV, "ODEPE_DEBUG") && ENV["ODEPE_DEBUG"] == "true"
    configure_logging(Logging.Debug)
else
    configure_logging(Logging.Info)
end