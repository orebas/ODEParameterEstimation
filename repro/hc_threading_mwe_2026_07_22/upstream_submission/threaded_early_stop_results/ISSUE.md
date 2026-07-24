## Problem

The threaded solve path initializes an atomic `started` counter to zero but
never increments it. When `stop_early_cb` stops the solve, cleanup scans
`1:started[]`, so it discards every completed `PathResult`. The solve can
therefore return an empty `Result` even when a successful path triggered the
callback.

## Reproduction

Solve a total-degree system with many roots using `threading=true` and return
`true` from the callback on the first successful path. `isempty(result)` can
then be true. The existing test checked only that fewer than all paths were
returned, so an empty result passed.

## Expected behavior

After worker tasks join, an interrupted solve should return every assigned
`PathResult`, in path-index order, and omit only unassigned slots.

## Scope

Callback serialization is a separate API/design question and is out of scope.
