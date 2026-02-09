#!/bin/bash
# Line-by-line allocation tracking using Julia's built-in --track-allocation
#
# This produces .jl.mem files next to each source file showing bytes allocated per line.
# Each .jl.mem file mirrors the corresponding .jl source, with allocation counts on each line.
#
# IMPORTANT: The script runs the model twice in one process:
#   1. First run: compiles everything (JIT allocations are NOT counted)
#   2. Profile.clear_malloc_data() resets counters
#   3. Second run: captures only steady-state allocations
#
# Usage:
#   bash src/examples/profiling/track_allocations.sh [model_name]
#
# Examples:
#   bash src/examples/profiling/track_allocations.sh simple
#   bash src/examples/profiling/track_allocations.sh brusselator
#   bash src/examples/profiling/track_allocations.sh lotka_volterra

set -e

MODEL=${1:-simple}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "=== Allocation tracking for model: $MODEL ==="
echo "Project: $PROJECT_DIR"
echo ""

# Clean up old .mem files first
echo "Cleaning old .jl.mem files..."
find "$PROJECT_DIR/src" -name "*.jl.mem" -delete 2>/dev/null || true

echo "Running Julia with --track-allocation=user..."
echo "(This will take a while - two full runs are needed)"
echo ""

julia --track-allocation=user -e "
using ODEParameterEstimation
include(\"$SCRIPT_DIR/../load_examples.jl\")

model_fn = ALL_MODELS[:${MODEL}]
pep = model_fn()
opts = EstimationOptions(
    datasize=101,
    system_solver=SolverHC,
    shooting_points=1,
    noise_level=0.0,
)
sampled = sample_problem_data(pep, opts)

println(\"=== Pass 1: Warmup (compiling) ===\")
@time analyze_parameter_estimation_problem(sampled, opts)

# Clear JIT allocation data - only measure steady-state from here
Profile.clear_malloc_data()

println()
println(\"=== Pass 2: Measured run ===\")
@time analyze_parameter_estimation_problem(sampled, opts)
println()
println(\"Done. .jl.mem files have been written.\")
"

echo ""
echo "=== Top allocation sites in ODEParameterEstimation ==="
echo ""

# Find .mem files and extract lines with non-zero allocations
# Format: bytes  filename:line
find "$PROJECT_DIR/src" -name "*.jl.mem" -print0 | while IFS= read -r -d '' memfile; do
    # Get the corresponding .jl file path for nice output
    jlfile="${memfile%.mem}"
    relpath="${jlfile#$PROJECT_DIR/}"

    # Extract lines with allocations > 0 (format is: "    12345 " at start of line)
    awk -v file="$relpath" '
    {
        # .mem files have format: "        0 " or "   123456 " followed by source
        if (match($0, /^ *([0-9]+)/, arr)) {
            bytes = arr[1] + 0
            if (bytes > 0) {
                printf "%15d  %s:%d\n", bytes, file, NR
            }
        }
    }' "$memfile"
done | sort -rn | head -40

echo ""
echo "=== Summary ==="
echo "To view a specific file's allocations:"
echo "  cat path/to/file.jl.mem"
echo ""
echo "To clean up .mem files:"
echo "  find $PROJECT_DIR/src -name '*.jl.mem' -delete"
