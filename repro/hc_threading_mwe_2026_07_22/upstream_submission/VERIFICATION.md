# Verification matrix

All three worktrees were created directly from
`cd74c49474959e0b2661f81587affba29a42c5ed`. Each branch is exactly one commit
ahead of that base and had a clean working tree after commit.

| Kit | Branch head | Focused test | Broader focused test |
| --- | --- | --- | --- |
| Compiled cache thread safety | `4b542974fe0984d78e34530a0f8687fc3838362b` | 14/14 pass, 2 threads | Full ModelKit partition started but intentionally not recorded as complete |
| Threaded early-stop results | `673ff92d21ac9c2f49a68b21b2a40817bcce8b10` | 2/2 pass, 4 threads | `solve_test.jl`: 74/74 pass |
| Polyhedral progress flag | `c6279ce8b5d76e5ce957e82508842851e5b44074` | 4/4 pass, 4 threads | `solve_test.jl`: 76/76 pass |

Additional checks:

- JuliaFormatter 1.0.33 was run on every affected Julia source/test file.
- `git diff --check` passed for every commit.
- Each generated patch passed `git apply --check` independently against the
  exact upstream base.
- `SHA256SUMS` covers every patch and focused test log.
- The branches were pushed to `orebas/HomotopyContinuation.jl` and opened as
  upstream pull requests #720, #721, and #722, linked to issues #717, #718,
  and #719 respectively.
