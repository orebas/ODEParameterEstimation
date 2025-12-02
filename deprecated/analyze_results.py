import pandas as pd
import re
import argparse

def escape_latex(s):
    """
    Escapes characters that have special meaning in LaTeX,
    and formats variable names like x1(t) into $x_1(t)$.
    """
    # First, handle specific variable formatting like x1(t) -> $x_{1}(t)$
    match = re.match(r'([a-zA-Z]+)(\d*)\(t\)', s)
    if match:
        base, num = match.groups()
        if num:
            return f'${base}_{{{num}}}(t)$'
        else:
            return f'${base}(t)$'
    
    # General replacements for other symbols
    s = s.replace('_', r'\_')
    return s

def format_table_latex(df, model, noise, estimator, interpolator=None):
    """
    Finds the best solution from a DataFrame and formats it into a LaTeX table string.
    """
    if df.empty:
        return ""

    # --- Logic to find the best solution cluster and best solution ---
    cluster_max_errors = df.groupby('cluster_id')['rel_error'].max()
    if cluster_max_errors.empty: return ""
    best_cluster_id = cluster_max_errors.idxmin()
    best_cluster_df = df[df['cluster_id'] == best_cluster_id].copy()
    
    best_cluster_df['mean_rel_error'] = best_cluster_df.groupby('solution_in_cluster')['rel_error'].transform('mean')
    best_solution_idx = best_cluster_df['mean_rel_error'].idxmin()
    best_solution_in_cluster_id = best_cluster_df.loc[best_solution_idx, 'solution_in_cluster']
    best_solution_df = best_cluster_df[best_cluster_df['solution_in_cluster'] == best_solution_in_cluster_id]
    
    best_solution_overall_error = best_solution_df['overall_problem_error'].iloc[0]
    num_solutions_in_cluster = best_cluster_df['solution_in_cluster'].nunique()

    # --- LaTeX Table Generation ---
    display_df = best_solution_df[['variable_name', 'true_value', 'estimated_value', 'rel_error']].copy()
    display_df['variable_name'] = display_df['variable_name'].apply(escape_latex)

    caption = f"Results for Model: \\texttt{{{model.replace('_', ' ')}}}, Estimator: \\texttt{{{estimator}}}"
    if interpolator:
        caption += f", Interpolator: \\texttt{{{interpolator}}}"
    caption += f", Noise: {noise}."
    caption += f" Best solution from cluster of {num_solutions_in_cluster} (Loss: {best_solution_overall_error:.4f})."
    
    label = f"tab:{model}_{estimator}_{interpolator if interpolator else ''}_{str(noise).replace('.', '')}"

    latex_string = "\\begin{table}[H]\n"
    latex_string += "\\centering\n"
    latex_string += "\\begin{tabular}{lrrr}\n"
    latex_string += "\\toprule\n"
    latex_string += "Variable & True Value & Estimated & Rel. Error \\\\\n"
    latex_string += "\\midrule\n"

    for _, row in display_df.iterrows():
        latex_string += f"{row['variable_name']} & {row['true_value']:.6f} & {row['estimated_value']:.6f} & {row['rel_error']:.6f} \\\\\n"

    latex_string += "\\bottomrule\n"
    latex_string += "\\end{tabular}\n"
    latex_string += f"\\caption{{{caption}}}\n"
    latex_string += f"\\label{{{label}}}\n"
    latex_string += "\\end{table}\n\n"
    
    return latex_string

def analyze_results_to_latex(filepath, output_path="ifac_tables.tex"):
    """
    Analyzes results from a CSV file and generates a LaTeX file with tables for each case.
    """
    try:
        df = pd.read_csv(filepath)
    except FileNotFoundError:
        print(f"Error: The file '{filepath}' was not found.")
        return

    all_latex_tables = ""
    models = sorted(df['model_name'].unique())
    
    for model in models:
        model_df = df[df['model_name'] == model]
        for noise in sorted(model_df['noise_level'].unique()):
            noise_df = model_df[model_df['noise_level'] == noise]
            for estimator in sorted(noise_df['estimator'].unique()):
                estimator_df = noise_df[noise_df['estimator'] == estimator]
                
                if estimator == "PE":
                    for interpolator in sorted(estimator_df['interpolator_method'].unique()):
                        final_df = estimator_df[estimator_df['interpolator_method'] == interpolator]
                        all_latex_tables += format_table_latex(final_df, model, noise, estimator, interpolator)
                else: # "Opt" or other estimators without an interpolator
                    all_latex_tables += format_table_latex(estimator_df, model, noise, estimator)

    header = """\\documentclass{article}
\\usepackage{booktabs} % For professional quality tables
\\usepackage{float}    % For the [H] table placement specifier
\\usepackage{amsmath}  % For math formatting

\\begin{document}

"""
    footer = "\\end{document}\n"
    
    full_latex_doc = header + all_latex_tables + footer
    
    with open(output_path, 'w') as f:
        f.write(full_latex_doc)
        
    print(f"LaTeX tables successfully written to {output_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Analyze parameter estimation results and generate LaTeX tables.")
    parser.add_argument('input_file', type=str, help="Path to the input CSV file (e.g., ifac_analysis_results.csv)")
    parser.add_argument('--output', '-o', type=str, default="ifac_tables.tex", help="Path for the output .tex file.")
    args = parser.parse_args()
    
    analyze_results_to_latex(args.input_file, args.output) 