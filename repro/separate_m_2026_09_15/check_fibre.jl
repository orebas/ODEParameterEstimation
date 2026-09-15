# Exact-arithmetic fibre count, with modular unit checks for regularity and
# observability in the finite QQ quotient. The baseline GB is probabilistic.
using Pkg
Pkg.activate(get(ENV,"ODEPE_PETAB_ENV","/tmp/odepe-petab-pilot-env"))
using Nemo, Groebner, JSON, SHA
Base.exit_on_sigint(false)
length(ARGS)==3 || error("Expected counter.json counter_fixed.json output.json")
definition,input,output=ARGS
isfile(output) && error("Use a fresh output file")
data=JSON.parsefile(definition)
frozen=JSON.parsefile(input)
rq,xq=polynomial_ring(QQ,String.(frozen["variables"]);internal_ordering=:degrevlex)
function build(terms,ring,vars)
    sum((ring(parse(BigInt,n)//parse(BigInt,d))*prod(vars[i]^Int(e[i]) for i in eachindex(e))
         for (n,d,e) in terms);init=zero(ring))
end
fs=[build(ts,rq,xq) for ts in frozen["polynomials"]]
record=Dict{String,Any}("status"=>"groebner", "input_sha256"=>bytes2hex(sha256(read(input))),
    "source_sha256"=>bytes2hex(sha256(read(@__FILE__))),"julia_version"=>string(VERSION),
    "baseline"=>"Groebner.groebner defaults over QQ, probabilistic algorithm")
checkpoint()=open(output,"w") do io;JSON.print(io,record,2);end
checkpoint()
started=time_ns()
try
    gb=Groebner.groebner(fs)
    record["groebner_seconds"]=(time_ns()-started)/1e9
    record["dimension"]=Groebner.dimension(gb)
    record["kinetic_algebraic_length"]=length(Groebner.quotient_basis(gb))
    record["status"]="modular_unit_checks"
    checkpoint()
    println("EXACT_KINETIC_LENGTH ",record["kinetic_algebraic_length"]);flush(stdout)
    prime=2147483647
    fp=GF(prime)
    rp,xp=polynomial_ring(fp,String.(frozen["variables"]);internal_ordering=:degrevlex)
    function change_field(f)
        result=zero(rp)
        for (c,e) in zip(coefficients(f),exponent_vectors(f))
            iszero(fp(denominator(c))) && error("Bad prime divides a basis coefficient denominator")
            result += (fp(numerator(c))/fp(denominator(c)))*prod(xp[i]^e[i] for i in eachindex(e))
        end
        return result
    end
    gp=change_field.(gb)
    @assert Groebner.isgroebner(gp)
    @assert length(Groebner.quotient_basis(gp))==record["kinetic_algebraic_length"]
    @assert all(first(exponent_vectors(a))==first(exponent_vectors(b)) for (a,b) in zip(gb,gp))
    normal(f)=Groebner.normalform(gp,f)
    # Division-free determinant with reduction in the finite quotient after
    # every product. This avoids expanding a symbolic observability determinant.
    function quotient_det(matrix)
        cache=Dict(0=>one(rp))
        function visit(mask)
            haskey(cache,mask) && return cache[mask]
            row=size(matrix,1)-count_ones(mask)+1
            result=zero(rp);position=0
            for column in 1:size(matrix,2)
                bit=1<<(column-1)
                mask&bit==0 && continue
                position+=1
                result += (isodd(position) ? 1 : -1)*normal(matrix[row,column]*visit(mask⊻bit))
            end
            cache[mask]=normal(result)
        end
        return visit((1<<size(matrix,1))-1)
    end
    q=derivative(fs[end],xq[end])
    matrix=[begin
        n=build(data["matrix"][i][j],rq,xq[1:5])
        d=build(data["matrix_denominators"][i][j],rq,xq[1:5])
        normal(change_field(n*divexact(q,d)*xq[end]))
    end for i in 1:6,j in 1:6]
    obs=fill(zero(rp),6,6)
    obs[1,:]=rp.(data["observable_linear_weights"])
    for row in 2:6,column in 1:6
        obs[row,column]=normal(sum(obs[row-1,k]*matrix[k,column] for k in 1:6))
    end
    det_obs=quotient_det(obs)
    record["observability_is_unit_mod_prime"]=Groebner.groebner(vcat(gp,[det_obs]))==[one(rp)]
    checkpoint()
    println("OBSERVABILITY_UNIT ",record["observability_is_unit_mod_prime"]);flush(stdout)
    jacobian=[normal(change_field(derivative(f,x))) for f in fs,x in xq]
    det_jac=quotient_det(jacobian)
    record["jacobian_is_unit_mod_prime"]=Groebner.groebner(vcat(gp,[det_jac]))==[one(rp)]
    record["prime"]=prime
    record["unit_check_argument"]="The monic QQ basis has good coefficient denominators and unchanged leading monomials at this prime. Its standard-monomial module specializes freely. Invertibility of multiplication by each determinant mod p implies a nonzero multiplication determinant over QQ."
    record["full_M_at_reference_fibre"]=record["observability_is_unit_mod_prime"] ? 4record["kinetic_algebraic_length"] : nothing
    record["status"]="complete"
catch err
    record["status"]=err isa InterruptException ? "interrupted" : "failed"
    record["error"]=sprint(showerror,err,catch_backtrace())
finally
    record["elapsed_seconds"]=(time_ns()-started)/1e9
    checkpoint()
end
println("FIBRE_CHECK_END ",record);flush(stdout)
record["status"]=="complete" || exit(1)
