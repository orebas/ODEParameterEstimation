## Summary

Threaded early-stop cleanup scanned `1:started[]`, but `started` was never
incremented, so every completed result could be discarded.

This removes `started`. After worker tasks join, cleanup scans all
`path_results` slots and keeps assigned ones in path-index order. The full scan
is necessary because workers can finish out of order. The regression now
rejects empty results. A nearby comment typo is also fixed.

## Tests

- Focused threaded early-stop test: 2/2 passed with four Julia threads.
- Complete `test/solve_test.jl`: 74/74 passed with four Julia threads.

## Out of scope

This does not serialize `stop_early_cb`; callbacks may still overlap across
worker tasks.

Closes #718.
