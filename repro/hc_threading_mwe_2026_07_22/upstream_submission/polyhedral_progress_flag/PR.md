## Summary

This propagates `show_progress` from `solve` through
`solver_startsolutions` and the polyhedral start-solution iterators to
`MixedSubdivisions.fine_mixed_cells`. Terminal setup methods consume the
keyword, keeping non-polyhedral behavior unchanged and allowing the public
`solver_startsolutions(...; show_progress=false)` path to honor it directly.

The polyhedral option is documented, and the default remains `true`.

## Tests

- Focused regressions for direct `solver_startsolutions` and top-level
  `solve`: 4/4 passed.
- Complete `test/solve_test.jl`: 76/76 passed with four Julia threads.

Closes #719.
