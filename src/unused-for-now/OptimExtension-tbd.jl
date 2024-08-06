
#below NOT currently included in ODEParameterEstimation.  Let's add it to an extension later (TODO)

using Optimization
using OptimizationOptimJL
using NonlinearSolve




function solveJSwithOptim(input_poly_system, input_varlist)
	resid_counter = 0
	loss = 0

	for i in input_poly_system
		loss = loss + (i)^2
		resid_counter += 1
	end

	lossvars = sort(get_variables(loss), by = string)
	#for i in lossvars
	#	loss += 0.0001 * i^2
	#	resid_counter += 1
	#end
	display(lossvars)
	f_expr = build_function(loss, input_varlist, expression = Val{false})
	f_expr2(u, p) = f_expr(u)
	function f_expr3!(du, u, p)
		du[1] = f_expr(u)
	end

	u0map = ones(Float64, (length(lossvars)))
	for ti in eachindex(u0map)
		u0map[ti] = rand() * 1
	end


	resid_vec = zeros(Float64, resid_counter)

	g = OptimizationFunction(f_expr2, AutoForwardDiff())  #or AutoZygote
	prob = OptimizationProblem(g, u0map)
	sol = Optimization.solve(prob, LBFGS())  #newton was slower
	println("Optimizer solution:")
	display(sol)
	display(sol.original)
	display(sol.retcode)
	#########################################3
	#println(f_expr2(u0map,zeros(Float64, 0)))
	#println("test1")
	#prob4 = NonlinearProblem(NonlinearFunction(f_expr3!),
	#	u0map, zeros(Float64, 0))

	#solnl = NonlinearSolve.solve(prob4,maxiters = 100000)
	#println(solnl.retcode)
	#println(solnl)
	return (sol.u)

end
#move to an extension I guess


function solveJSwithNLLS(input_poly_system, input_varlist)

	nl_expr = build_function(input_poly_system, input_varlist, expression = Val{false})
	nl_expr_p(out, u, p) = nl_expr[2](out, u)
	resid_vec = zeros(Float64, length(input_poly_system))
	u0map = ones(Float64, (length(input_varlist)))
	prob5 = NonlinearLeastSquaresProblem(NonlinearFunction(nl_expr_p, resid_prototype = resid_vec), u0map)
	solnlls = NonlinearSolve.solve(prob5, maxiters = 64000)
	println("Here is the solution in NLLS line 732")
	display(solnlls.retcode)
	display(solnlls.stats)

	display(solnlls.original)
	display(solnlls.resid)
	display(solnlls)

end
