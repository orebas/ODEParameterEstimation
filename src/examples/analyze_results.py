import pandas as pd

def analyze_results(filepath="ifac_analysis_results.csv"):
    """
    Analyzes the results from the parameter estimation, finds the best
    solution cluster for each model and noise level, and prints a summary table.
    """
    try:
        df = pd.read_csv(filepath)
    except FileNotFoundError:
        print(f"Error: The file {filepath} was not found.")
        print("Please ensure you have run the analysis in 'IFAC.jl' first.")
        return

    # Get unique models to iterate over
    models = df['model_name'].unique()

    for model in models:
        print(f"\n{'='*20} Model: {model} {'='*20}")
        model_df = df[df['model_name'] == model]

        for noise in sorted(model_df['noise_level'].unique()):
            print(f"\n--- Noise Level: {noise} ---")
            noise_df = model_df[model_df['noise_level'] == noise]

            for estimator in sorted(noise_df['estimator'].unique()):
                print(f"\n##### Estimator: {estimator} #####")
                estimator_df = noise_df[noise_df['estimator'] == estimator]

                if estimator == "PE":
                    for interpolator in sorted(estimator_df['interpolator_method'].unique()):
                        print(f"\n>>>> Interpolator Method: {interpolator} <<<<")
                        final_df = estimator_df[estimator_df['interpolator_method'] == interpolator]
                        print_best_cluster_table(final_df)
                else: # Handles "Opt" and any other future estimators
                    print_best_cluster_table(estimator_df)


def print_best_cluster_table(df):
    """
    Finds and prints a formatted table for the best solution cluster in a given DataFrame.
    """
    if df.empty:
        print("No data to display.")
        return

    # For each cluster, find the maximum relative error
    cluster_max_errors = df.groupby('cluster_id')['rel_error'].max()
    
    # Find the cluster with the minimum of these maximum errors
    if cluster_max_errors.empty:
        print("No clusters found.")
        return
    
    best_cluster_id = cluster_max_errors.idxmin()
    
    best_cluster_df = df[df['cluster_id'] == best_cluster_id].copy()
    
    # Within the best cluster, find the solution with the minimum *mean* relative error
    best_cluster_df['mean_rel_error'] = best_cluster_df.groupby('solution_in_cluster')['rel_error'].transform('mean')
    best_solution_idx = best_cluster_df['mean_rel_error'].idxmin()
    best_solution_in_cluster_id = best_cluster_df.loc[best_solution_idx, 'solution_in_cluster']
    
    best_solution_df = best_cluster_df[best_cluster_df['solution_in_cluster'] == best_solution_in_cluster_id]
    
    best_solution_overall_error = best_solution_df['overall_problem_error'].iloc[0]


    # Get the number of solutions in this cluster to report
    num_solutions_in_cluster = best_solution_df['solution_in_cluster'].nunique()

    print(f"\nBest cluster (ID {best_cluster_id}) found with {num_solutions_in_cluster} similar solutions.")
    print(f"Presenting best solution from this cluster (Error: {best_solution_overall_error:.6f}):")
    
    # Prepare for printing
    display_df = best_solution_df[['variable_name', 'true_value', 'estimated_value', 'rel_error']].copy()
    display_df.rename(columns={
        'variable_name': 'Variable',
        'true_value': 'True Value',
        'estimated_value': 'Estimated',
        'rel_error': 'Rel. Error'
    }, inplace=True)

    # Dynamic column width for 'Variable'
    max_var_len = display_df['Variable'].str.len().max()
    max_var_len = max(max_var_len, len('Variable')) # ensure header fits

    header_fmt = f"{{:<{max_var_len}}} | {{:>12}} | {{:>12}} | {{:>12}}"
    row_fmt = f"{{:<{max_var_len}}} | {{:>12.6f}} | {{:>12.6f}} | {{:>12.6f}}"
    
    print("-" * (max_var_len + 45))
    print(header_fmt.format('Variable', 'True Value', 'Estimated', 'Rel. Error'))
    print("-" * (max_var_len + 45))
    
    for _, row in display_df.iterrows():
        print(row_fmt.format(row['Variable'], row['True Value'], row['Estimated'], row['Rel. Error']))
    print()


if __name__ == "__main__":
    analyze_results()