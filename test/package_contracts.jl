using ODEParameterEstimation
using Test

@testset "Exported bindings are defined" begin
    undefined = filter(name -> !isdefined(ODEParameterEstimation, name),
                       names(ODEParameterEstimation))
    @test isempty(undefined)
end

# A name exported by two imported packages cannot be used unqualified: it stays
# undefined in this module and fails only when that line runs. Lowered method
# bodies record every global they reference, so all of them can be checked up
# front. This reads runtime internals; it returns `nothing` where they are
# unavailable (Julia versions before the single global method table).
function ambiguous_import_references(pkg::Module)
    isdefined(Core, :methodtable) || return nothing
    inpkg(m::Module) = m === pkg || (parentmodule(m) !== m && inpkg(parentmodule(m)))
    referenced = Set{Tuple{Module, Symbol}}()
    function walk(x)
        if x isa GlobalRef
            push!(referenced, (x.mod, x.name))
        elseif x isa Expr
            foreach(walk, x.args)
        end
        return nothing
    end
    Base.visit(Core.methodtable) do method
        inpkg(method.module) || return nothing
        code = try
            Base.uncompressed_ast(method).code
        catch
            return nothing  # no stored source, e.g. generated functions
        end
        foreach(walk, code)
        return nothing
    end
    imports(mod) = ccall(:jl_module_usings, Any, (Any,), mod)
    return sort!([
        string(mod, ".", name) for (mod, name) in referenced
        if inpkg(mod) && !isdefined(mod, name) &&
           any(used -> Base.isexported(used, name), imports(mod))
    ])
end

@testset "Unqualified names are not ambiguous imports" begin
    ambiguous = try
        ambiguous_import_references(ODEParameterEstimation)
    catch err
        err isa InterruptException && rethrow()
        nothing
    end
    ambiguous === nothing && @info "Ambiguous-import check skipped: method bodies are not inspectable on this Julia version"
    @test ambiguous === nothing || isempty(ambiguous)
end
