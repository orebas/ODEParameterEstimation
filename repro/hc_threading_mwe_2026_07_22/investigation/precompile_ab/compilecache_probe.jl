#!/usr/bin/env julia

# Compile exactly the supplied ODEPE entry file while dependency resolution and
# dependency caches come from the active environment. Base.compilecache's path
# overload avoids changing the active environment merely to select the source
# tree under test.

isempty(ARGS) && error("usage: compilecache_probe.jl /absolute/path/to/src/ODEParameterEstimation.jl")
source_path = abspath(only(ARGS))
isfile(source_path) || error("ODEPE source not found: $source_path")

package_id = Base.PkgId(
	Base.UUID("482fc905-5656-4c69-b8fe-7a66cd0f77b3"),
	"ODEParameterEstimation",
)
println(stderr, "COMPILECACHE_PROBE phase=before_compilecache source=$(source_path)")
flush(stderr)
started = time()

cache_path = Base.compilecache(package_id, source_path)

elapsed = time() - started
println(
	stderr,
	"COMPILECACHE_PROBE phase=after_compilecache elapsed_seconds=$(elapsed) cache=$(cache_path)",
)
flush(stderr)
