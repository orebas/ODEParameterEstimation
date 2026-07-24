using HomotopyContinuation
const HC = HomotopyContinuation
@var x y
F = System([x^2 + y^2 - 1, x - y])
println("nthreads = ", Threads.nthreads())
t0 = time()
r = HC.solve(F; threading=true, show_progress=false)
println("solved in ", round(time()-t0, digits=2), "s  nsolutions=", HC.nsolutions(r))
