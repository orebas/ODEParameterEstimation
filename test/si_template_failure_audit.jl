using Dates
using ODEParameterEstimation

function model_category(name::Symbol)
	for (category, models) in ODEParameterEstimation.available_model_categories()
		category == :all && continue
		haskey(models, name) && return category
	end
	return :unknown
end

function classify_template_error(err)
	err isa ODEParameterEstimation.SITemplateShapeError && return "si_template_shape_error"
	err isa ODEParameterEstimation.UnsupportedDerivativeOrderError && return "unsupported_derivative_order"
	msg = sprint(showerror, err)
	if occursin("Failed to substitute all symbolic variables numerically", msg)
		return "symbolic_substitution_error"
	elseif occursin("Refusing to fabricate a fallback value", msg)
		return "strict_state_reconstruction_error"
	elseif occursin("factorial", msg)
		return "high_order_derivative_overflow"
	elseif occursin("Input arrays must have same length", msg)
		return "input_length_assertion"
	elseif occursin("TaskFailedException", msg)
		return "task_failed"
	else
		return "other_error"
	end
end

function write_row(io, fields)
	println(io, join(map(field -> replace(string(field), '\t' => ' ', '\n' => ' '), fields), '\t'))
end

function run_case(name::Symbol, ctor, opts)
	category = model_category(name)
	t0 = time()
	try
		pep = ctor()
		spep = sample_problem_data(pep, opts)
		ident = ODEParameterEstimation.setup_identifiability(spep; max_num_points = 1, nooutput = true)
		ordered_model = isa(spep.model.system, ODEParameterEstimation.OrderedODESystem) ?
			spep.model.system :
			ODEParameterEstimation.OrderedODESystem(spep.model.system, ident.states, ident.params)
		si_template, structure = ODEParameterEstimation.prepare_si_template_with_structural_fix(
			ordered_model,
			spep.measured_quantities,
			spep.data_sample,
			ident.good_DD,
			false;
			states = ident.states,
			params = ident.params,
			infolevel = 0,
			placeholder_fail_categories = opts.si_placeholder_fail_categories,
		)
		return (
			model = name,
			category = category,
			status = "ok",
			classification = "determined_template",
			runtime_seconds = round(time() - t0; digits = 2),
			template_status = structure.status,
			n_equations = structure.n_equations,
			n_variables = structure.n_variables,
			n_effective_eqs = structure.n_effective_eqs,
			n_effective_vars = structure.n_effective_vars,
			structural_fix_count = length(si_template.structural_fix_set),
			error_type = "",
			message = "",
		)
	catch err
		return (
			model = name,
			category = category,
			status = "error",
			classification = classify_template_error(err),
			runtime_seconds = round(time() - t0; digits = 2),
			template_status = "",
			n_equations = "",
			n_variables = "",
			n_effective_eqs = "",
			n_effective_vars = "",
			structural_fix_count = "",
			error_type = string(typeof(err)),
			message = sprint(showerror, err),
		)
	end
end

function main()
	output_path = get(ENV, "ODEPE_TEMPLATE_AUDIT_OUTPUT", joinpath(pwd(), "artifacts", "si_template_failure_audit.tsv"))
	mkpath(dirname(output_path))
	opts = EstimationOptions(
		datasize = 101,
		noise_level = 1e-8,
		flow = FlowStandard,
		use_si_template = true,
		use_parameter_homotopy = true,
		polish_solver_solutions = true,
		polish_solutions = false,
		interpolators = [InterpolatorAAAD, InterpolatorAGPRobust],
		nooutput = true,
		diagnostics = false,
		save_system = false,
	)
	results = map(sort(collect(keys(ODEParameterEstimation.ALL_MODELS)))) do name
		run_case(name, ODEParameterEstimation.ALL_MODELS[name], opts)
	end

	open(output_path, "w") do io
		write_row(io, (
			"model",
			"category",
			"status",
			"classification",
			"runtime_seconds",
			"template_status",
			"n_equations",
			"n_variables",
			"n_effective_eqs",
			"n_effective_vars",
			"structural_fix_count",
			"error_type",
			"message",
		))
		for row in results
			write_row(io, (
				row.model,
				row.category,
				row.status,
				row.classification,
				row.runtime_seconds,
				row.template_status,
				row.n_equations,
				row.n_variables,
				row.n_effective_eqs,
				row.n_effective_vars,
				row.structural_fix_count,
				row.error_type,
				row.message,
			))
		end
	end

	println("Wrote SI template failure audit to $output_path")
	for row in results
		println(string(row.model, "|", row.category, "|", row.status, "|", row.classification, "|", row.runtime_seconds))
	end
end

main()
