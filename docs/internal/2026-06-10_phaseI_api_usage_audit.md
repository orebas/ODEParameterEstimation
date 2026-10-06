# Phase I prep — de-facto API usage audit (2026-06-10)

Captured before export-tiering. PEB-local is the LIVE driver (symlinks ODEPE->dev).
KEY: PEB accesses ODEPE via QUALIFIED names (`ODEParameterEstimation.foo`), which
resolve via module-member access REGARDLESS of whether `foo` is exported. So the
export list and PEB's hard dependency are largely orthogonal — unexporting a
qualified-accessed name does NOT break PEB. Bare-`using` names are the real export
constraint (harder to enumerate; spot-check before unexporting common names).

Current unique exported names: 259

## PEB-local qualified usage (count name) — the de-facto API floor (103 names)
```
  18105 with_estimation_timing
  18105 timing_breakdown_to_dict
   4773 shade_lm_estimate
    228 nth_deriv
    168 OrderedODESystem
    160 sample_data
    124 baryEval
     89 create_ordered_ode_system
     85 solve_with_hc
     72 solve_with_rs
     72 solve_with_nlopt
     72 solve_with_fast_nlopt
     66 jl
     52 populate_derivatives
     45 solve_with_nlopt_testing
     45 solve_with_nlopt_quick
     45 get_si_equation_system
     43 agp_gpr_robust
     38 sample_problem_data
     38 convert_to_hc_format
     35 transform_pep_for_estimation
     30 t
     27 ensure_si_template_dd_support
     27 convert_to_si_ode
     26 get_polynomial_system_from_sian
     26 evaluate_trfn_template_variable
     26 evaluate_obs_trfn_template_variable
     26 _hc_solve
     24 multipoint_local_identifiability_analysis
     23 s3_se_interpolator
     23 s2_aaa_mle_interpolator
     14 construct_equation_system_from_si_template
     11 setup_identifiability
      9 simple
      8 parse_derivative_variable_name
      8 _parse_trfn_base_name
      7 get_interpolator_function
      7 compute_shooting_indices
      6 lookup_value
      6 lineage_summary
      6 classify_si_ring_variable
      6 Nemo
      5 validate_options
      5 should_fail_si_placeholder
      5 create_interpolants
      5 ParameterEstimationProblem
      4 merge_options
      4 UnsupportedModelClassError
      3 validate_supported_model_class
      3 simple_linear_combination
      3 resolve_interpolator_list
      3 process_estimation_results
      3 interpolator_method_to_symbol
      3 analyze_parameter_estimation_problem
      3 aaad
      3 TAYLORDIFF_MAX_DERIVATIVE_ORDER
      3 ResultProvenance
      3 ParameterEstimationResult
      2 sync_result_contract!
      2 resolve_states_with_fixed_params
      2 process_raw_solution
      2 prepare_si_template_with_structural_fix
      2 nemo_to_symbolics
      2 count_turns
      2 compatibility_return_code
      2 available_model_categories
      2 apply_uq_failure_policy
      2 _resolve_missing_state_count
      2 UnsupportedDerivativeOrderError
      2 Symbolics
      2 SITemplateShapeError
      2 ALL_MODELS
      1 unpack_ODE
      1 trivial_unident
      1 treatment
      1 throw_on_nonsquare_si_template
      1 threesp_cubed
      1 sum_test
      1 substr_test
      1 si_template_lineage_kwargs
      1 setup_parameter_estimation
      1 seir
      1 onesp_cubed
      1 magnetic_levitation
      1 lotka_volterra
      1 is_residual_polish_method
      1 global_unident_test
      1 get_polish_optimizer
      1 filter_finite_shooting_point_params
      1 copy_provenance
      1 convert_to_hc_format_with_params
      1 collect_used_nemo_variables
      1 calculate_timeseries_stats
      1 biohydrogenation
      1 _polish_single_from_context
      1 _note_algebraic_resolve_failure!
      1 _create_si_symbolic_placeholder!
      1 _build_polish_context
      1 _build_algebraic_resolve_candidate
      1 _algebraic_resolve_failure_notes
      1 SamplingFailureError
      1 OrderedCollections
      1 NumericalIdentifiabilityAdvisory
```

## repro/ qualified usage (distinct)
```
_hc_solve
_polish_external_to_internal
_polish_internal_to_external
apply_prefixed_params_to_model
biohydrogenation
biohydrogenation_m1
convert_to_hc_format
daisy_mamil4
daisy_mamil4_m1
ensure_si_template_dd_support
evaluate_obs_trfn_template_variable
evaluate_trfn_template_variable
get_si_equation_system
latent_subpopulation_branch
latent_subpopulation_observed_control
populate_derivatives
receptor_subtype_binding_branch
receptor_subtype_binding_observed_control
seir
seir_m1
slow_fast_m1
slowfast
solve_with_hc
timing_breakdown_to_dict
with_estimation_timing
```
