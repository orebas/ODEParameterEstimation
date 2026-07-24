`CompiledSystem` and `CompiledHomotopy` intern normalized symbolic objects in
process-global `Dict` tables. Their lookup, collision scan, insertion, and
type-level `interpret` reads are currently unsynchronized.

Concurrent construction can therefore race on both the dictionaries and their
stored vectors. Reads also need protection because an insertion can rehash a
dictionary while `interpret(::Type)` is accessing it.

## Evidence

In a concurrent `CompiledSystem` stress test, each completed run constructed
720,000 distinct systems. The cache retained only 718,239, 717,437, 717,804,
and 699,567 entries in four runs, directly demonstrating lost or corrupted
`TSYSTEM_TABLE` updates.

`THOMOTOPY_TABLE` has the same unsynchronized access pattern, but I have not
separately reproduced corruption in that table.

One easy-to-miss detail: `interpret(compiled_system)` returns the instance's
original system and does not read the cache. The cache-reading check is
`interpret(typeof(compiled_system))`.

## Expected behavior

Constructing compiled systems or homotopies concurrently should not lose cache
entries or race with generated evaluator lookup.
