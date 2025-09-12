using NonlinearSolve

println("Available NonlinearSolve algorithms:")
for name in names(NonlinearSolve)
    if isdefined(NonlinearSolve, name)
        obj = getfield(NonlinearSolve, name)
        if isa(obj, Type) && name != :NonlinearSolve
            # Try to instantiate to see if it's an algorithm
            try
                inst = obj()
                if isa(inst, NonlinearSolve.AbstractNonlinearSolveAlgorithm)
                    println("  ", name)
                end
            catch
                # Not an algorithm type
            end
        end
    end
end