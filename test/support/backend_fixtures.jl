# Shared inputs for the isolated upstream oracle and ordinary backend tests.
function sian_fixture(backend, rational)
    ring, (x, a, a_10, y, w) = Nemo.polynomial_ring(Nemo.QQ, ["x", "a", "a_10", "y", "w"])
    P = typeof(x)
    rhs = rational ? a*x//(a_10+x) : a*x
    # Freeze the input order as well as the values: Dict iteration order can
    # differ across Julia versions, and the backend must preserve ODE order.
    ode = StructuralIdentifiability.ODE{P}([x], [w,y], Dict(x=>rhs), Dict(y=>x, w=>x^2), P[])
    eqs,Q,xe,ye,xs,ys,us,mu,indets,gens = backend.get_equations(ode)
    n,m,u,s = length(xs),length(ys),length(us),length(xs)+length(mu)
    X,Xeq = backend.get_x_eq(xe,ye,n,m,s,u,gens)
    Y,Yeq = backend.get_y_eq(xe,ye,n,m,s,u,gens)
    params = vcat(gens[end-length(mu)+1:end],gens[1:n])
    Random.seed!(20261004)
    sample = backend.sample_point(big(101),xs,ys,P[],params,Xeq,Yeq,Q)
    vals = backend.insert_zeros_to_vals(sample[4][1],sample[4][2])
    polys = vcat(X[1],Y[1],Y[2])
    jac = backend.jacobi_matrix(polys,params,vals)
    return Dict("variables"=>string.(gens), "denominator"=>string(Q),
        "polynomials"=>string.(polys), "sample_variables"=>string.(sample[4][1]),
        "sample_values"=>string.(sample[4][2]), "jacobian"=>string.(vec(Matrix(jac))))
end
