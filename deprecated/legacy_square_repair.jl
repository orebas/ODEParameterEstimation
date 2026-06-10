# Archived 2026-06-10 from src/core/parameter_estimation.jl — NOT part of the build.
# Zero callers anywhere (src/, test/, PEB); superseded by
# prepare_si_template_with_structural_fix. Reference only.
# ============================================================================

# Deprecated internal helper retained only for debugging/forensics of older
# square-repair behavior. The supported flow no longer calls this.
function prepare_si_template_with_legacy_square_repair(
	ordered_model,
	measured_quantities,
	data_sample,
	base_DD,
	diagnostics;
	states = nothing,
	params = nothing,
	infolevel = diagnostics ? 1 : 0,
	placeholder_fail_categories = Symbol[],
	max_residual_fix_iterations = 10,
)
	initial_template = build_si_template_for_fixed_params(
		ordered_model,
		measured_quantities,
		data_sample,
		base_DD;
		infolevel = infolevel,
		pre_fixed_params = OrderedDict{Num, Float64}(),
		placeholder_fail_categories = placeholder_fail_categories,
	)

	structural_fix_info = derive_structural_fix_set(initial_template, diagnostics; states = states, params = params)
	structural_fix_set = structural_fix_info.pre_fixed
	structural_fix_report = structural_fix_info.reported
	structural_unidentifiable = structural_fix_info.structural_unidentifiable
	current_fixed = OrderedDict{Num, Float64}(k => v for (k, v) in structural_fix_set)
	residual_fix_set = OrderedDict{Num, Float64}()
	residual_fix_report = OrderedDict{Num, Float64}()
	template_status_before_residual_fix = nothing
	template_status_after_residual_fix = nothing
	residual_iteration = 0
	final_template = initial_template
	final_structure = nothing

	while residual_iteration <= max_residual_fix_iterations
		si_template = build_si_template_for_fixed_params(
			ordered_model,
			measured_quantities,
			data_sample,
			base_DD;
			infolevel = infolevel,
			pre_fixed_params = current_fixed,
			placeholder_fail_categories = placeholder_fail_categories,
		)
		structure = analyze_si_template_structure(si_template)
		isnothing(template_status_before_residual_fix) && (template_status_before_residual_fix = structure.status)

		if diagnostics
			@info "[LEGACY-TEMPLATE-REPAIR] System status: $(structure.n_equations) equations, $(structure.n_variables) unknowns (+ $(structure.n_data_vars) data variables)"
			if structure.n_trfn_vars > 0
				@info "[LEGACY-TEMPLATE-REPAIR] _trfn_ vars: $(structure.n_trfn_vars) known inputs, $(structure.n_trfn_only_eqs) trivial equations"
				@info "[LEGACY-TEMPLATE-REPAIR] Effective system: $(structure.n_effective_eqs) equations, $(structure.n_effective_vars) real unknowns"
			end
		end

		final_template = (
			equations = si_template.equations,
			all_equations = hasproperty(si_template, :all_equations) ? si_template.all_equations : si_template.equations,
			deriv_dict = si_template.deriv_dict,
			template_DD = si_template.template_DD,
			unidentifiable = si_template.unidentifiable,
			identifiable_funcs = si_template.identifiable_funcs,
			si_variable_role_summary = si_template.si_variable_role_summary,
			rank_trimming_metadata = si_template.rank_trimming_metadata,
			structural_unidentifiable = structural_unidentifiable,
			structural_fix_set = structural_fix_report,
			residual_fix_set = copy(residual_fix_report),
			template_status_before_residual_fix = template_status_before_residual_fix,
			template_status_after_residual_fix = structure.status,
			practical_identifiability_status = :not_assessed,
		)
		final_structure = structure
		template_status_after_residual_fix = structure.status

		if structure.status == :determined
			break
		elseif structure.status == :residual_underdetermined
			residual_iteration += 1
			if residual_iteration > max_residual_fix_iterations
				@warn "[LEGACY-TEMPLATE-REPAIR] Did not converge after $max_residual_fix_iterations residual iterations"
				break
			end
			@info "[LEGACY-TEMPLATE-REPAIR] Iteration $residual_iteration, fixed so far: $(keys(residual_fix_set))"
			param_to_fix, fix_value = select_one_legacy_template_fix_variable(
				si_template, Set(keys(current_fixed)), diagnostics; states = states
			)
			if param_to_fix === nothing
				@warn "[LEGACY-TEMPLATE-REPAIR] No parameter available to fix, stopping legacy square repair"
				break
			end
			@info "[LEGACY-TEMPLATE-REPAIR] Fixing residual template variable: $param_to_fix = $fix_value"
			current_fixed[param_to_fix] = fix_value
			residual_fix_set[param_to_fix] = fix_value
			residual_fix_report[_model_symbol_from_name(string(param_to_fix), states, params)] = fix_value
		else
			@warn "[LEGACY-TEMPLATE-REPAIR] Template remained $(structure.status); stopping legacy repair"
			break
		end
	end

	return final_template, final_structure
end
