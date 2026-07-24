#!/usr/bin/env julia

# Minimal cold-import probe for the controlled precompile A/B. The selected
# ODEPE source tree comes from JULIA_LOAD_PATH; the selected cache/dependency
# tree comes from JULIA_DEPOT_PATH.

println(stderr, "IMPORT_PROBE phase=before_import julia=$(VERSION) pid=$(getpid())")
flush(stderr)
started = time()

using ODEParameterEstimation

elapsed = time() - started
println(stderr, "IMPORT_PROBE phase=after_import elapsed_seconds=$(elapsed)")
flush(stderr)
