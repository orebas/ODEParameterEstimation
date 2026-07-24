# HomotopyContinuation.jl submission kits

These are three independent changes based directly on upstream commit
`cd74c49474959e0b2661f81587affba29a42c5ed` (HomotopyContinuation.jl 2.21).
They are intentionally split so that each can be reviewed and submitted on its own:

1. `compiled_cache_thread_safety/`
2. `threaded_early_stop_results/`
3. `polyhedral_progress_flag/`

Each directory contains issue text, pull-request text, submission notes, a
`git format-patch` patch, and a focused test log.

| Change | Issue | Pull request |
| --- | --- | --- |
| Compiled-cache thread safety | [#717](https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/issues/717) | [#720](https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/pull/720) |
| Threaded early-stop results | [#718](https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/issues/718) | [#721](https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/pull/721) |
| Polyhedral progress flag | [#719](https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/issues/719) | [#722](https://github.com/JuliaHomotopyContinuation/HomotopyContinuation.jl/pull/722) |

The first kit fixes a demonstrated cache race. The other two are independent
correctness and usability fixes.
