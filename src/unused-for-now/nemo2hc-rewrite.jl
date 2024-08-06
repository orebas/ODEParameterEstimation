"""
	nemo2hc(expr_tree::Union{Expr, Symbol})

Converts a symbolic expression from Nemo to HomotopyContinuation format.
"""
function nemo2hc(expr_tree::Union{Expr, Symbol})
	#traverse expr_tree

	#display(expr_tree)
	if typeof(expr_tree) == Symbol
		#display("SymbolHERE")
		tempret = HomotopyContinuation.Expression(HomotopyContinuation.variables(expr_tree)[1])
		#display(expr_tree)
		#display(tempret)
		return tempret
	end
	if typeof(expr_tree) == Expr
		#display("HHH")
		if expr_tree.head == :call
			if expr_tree.args[1] in [:+, :-, :*, :/, :^, ://]
				if length(expr_tree.args) == 2
					#display("FMODE")
					return eval(expr_tree.args[1])(nemo2hc(expr_tree.args[2]))
				else
					#=
					println("HERE")
					println("1 ", expr_tree.args[1])
					println("2 ", expr_tree.args[2:end])
					println("3 ", typeof(expr_tree.args[2]))
					println("4 ", (expr_tree.args[2]))

					println("5 ", typeof(nemo2hc(expr_tree.args[2])))
					println("6 ", nemo2hc(expr_tree.args[2]))

					println("7 ", typeof(-7))
					println("8 ", nemo2hc(-7))

					=#
					tempmap = map(nemo2hc, expr_tree.args[2:end])

					#println("map success", tempmap)
					return reduce(eval(expr_tree.args[1]),
						tempmap)
				end
			else
				display("fail")

			end
		else
			return BigFloat(string(expr_tree))
		end
	end
end

#function nemo2hc(expr_tree::fmpq_mpoly)
	#println("fmpq_poly")
	# println(expr_tree)
#	return nemo2hc(Meta.parse(string(expr_tree)))
#end

function nemo2hc(expr_tree::Number)
	#println("Number")
	return expr_tree
end

#function nemo2hc(expr_tree::Oscar.Generic.Frac)
	#println("Frac")
#	numer, denom = Oscar.numerator(expr_tree), Oscar.denominator(expr_tree)
#	return nemo2hc(numer) / nemo2hc(denom)
#end
