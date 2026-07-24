## Summary

`solve(...; show_progress=false)` suppresses path-tracking progress, but not
the mixed-cell progress shown while preparing polyhedral start solutions. The
flag is consumed by `solve` before that setup, so
`MixedSubdivisions.fine_mixed_cells` still uses its default
`show_progress=true`.

The public `solver_startsolutions(F; show_progress=false)` path also reports
the keyword as unsupported instead of using it to control mixed-cell output.

## Expected behavior

`show_progress=false` should suppress both progress displays, whether setup is
reached through `solve` or called directly through `solver_startsolutions`.

## Scope

This affects progress output only, not the mixed cells, paths, or solutions.
