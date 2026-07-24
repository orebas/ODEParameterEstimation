include("gensys.jl")
n = parse(Int, ARGS[1]); d = parse(Int, ARGS[2]); seed = parse(Int, ARGS[3])
F = dense_system(n, d, seed)
println("system n=$n d=$d  #eqs=", length(F.expressions), " nthreads=", Threads.nthreads()); flush(stdout)
t0 = time(); r = HC.solve(F; threading=true, show_progress=false); el = time()-t0
println("SOLVED n=$n d=$d in ", round(el,digits=2), "s  npaths~nsol=", HC.nsolutions(r)); flush(stdout)
