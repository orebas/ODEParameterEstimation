module SimpleUnusedLinter

export @lintfun

"""
	@lintfun function foo(a,b,c)
		 ...
	end

This macro inspects the function body and warns if any parameter (other than those beginning with `_`)
never appears in the function body.
"""
macro lintfun(fdef)
	# Only support function definitions of the normal form:
	#   function f(args...)
	#       body...
	#   end
	if fdef.head != :function
		error("@lintfun must be used on a function definition")
	end

	# Extract the function signature and body.
	sig = fdef.args[1]
	body = fdef.args[2:end]

	# The signature may be simply a symbol or an expression like `:(f(a,b,c))`
	if sig isa Expr
		fname = sig.args[1]  # function name
		args_list = sig.args[2:end]
	else
		error("@lintfun can only handle function definitions with an explicit argument list")
	end

	# Process the argument list to extract the parameter names.
	params = Symbol[]
	for arg in args_list
		if arg isa Symbol
			push!(params, arg)
		elseif arg isa Expr
			if arg.head == :(::) || arg.head == :(=)
				push!(params, arg.args[1])
			else
				# If you use destructuring or more complicated patterns,
				# you might want to add support here.
			end
		end
	end

	# A simple recursive function to collect all symbols from an expression.
	function collect_syms(expr)
		syms = Symbol[]
		if expr isa Symbol
			push!(syms, expr)
		elseif expr isa Expr
			for sub in expr.args
				append!(syms, collect_syms(sub))
			end
		end
		return syms
	end

	# Collect all symbols that appear anywhere in the function body.
	used_syms = Symbol[]
	for stmt in body
		append!(used_syms, collect_syms(stmt))
	end

	# For each parameter, warn if it does not appear in the function body.
	for p in params
		# Ignore parameters with names that begin with an underscore.
		if !startswith(string(p), "_") && !(p in used_syms)
			@warn "In function $(fname): parameter $(p) is never used."
		end
	end

	return esc(fdef)
end

end  # module SimpleUnusedLinter
