This adds one private `ReentrantLock` for the compiled-system cache and one for
the compiled-homotopy cache.

Each lock covers the complete lookup, equality check, append, and insertion
transaction, as well as type-level `interpret` reads. Normalization, hashing,
and final parametric type construction remain outside the critical section.

`ReentrantLock` is used because the protected work includes dictionary
operations and structural equality checks, where spinning would be a poor fit.

## Tests

The regression tests:

- hold each cache lock and verify that construction and
  `interpret(typeof(compiled))` wait for its release;
- concurrently build 128 distinct systems and 128 distinct homotopies with two
  workers; and
- check exact cache growth, unique compiled types, and numerical agreement with
  the original symbolic objects.

Focused result on Julia 1.12.6 with two Julia threads: 14/14 passed.

The dynamic lost-update reproduction covers `TSYSTEM_TABLE`.
`THOMOTOPY_TABLE` is included because it has the same unsafe implementation,
but it was not separately reproduced.

Closes #717.
