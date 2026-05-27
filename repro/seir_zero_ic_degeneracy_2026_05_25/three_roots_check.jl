# Show that TRUTH, the ANCHOR, and BRANCH-2 are ALL roots of the same
# t0-instantiated SI-template system => the system cannot distinguish them.
using ODEParameterEstimation, Symbolics, LinearAlgebra

@variables In_0 nu_0 a_0 E_0 In_1 N_0 N_1 E_1 In_2 b_0 S_0 In_3 E_2 S_1 In_4 E_3 N_2 S_2 E_4 In_5 S_3 N_3 In_6 E_5 N_4 S_4
varlist = [In_0, nu_0, a_0, E_0, In_1, N_0, N_1, E_1, In_2, b_0, S_0, In_3, E_2, S_1, In_4, E_3, N_2, S_2, E_4, In_5, S_3, N_3, In_6, E_5, N_4, S_4]
eq_strs = [
 "1.2795795700830634e-13 - In_0","In_1 - E_0*nu_0 + In_0*a_0","1000.0 - N_0","N_1","1.499999999999488 - In_1",
 "In_2 - E_1*nu_0 + In_1*a_0","E_1*N_0 + E_0*N_0*nu_0 - In_0*S_0*b_0","-0.5250000000023717 - In_2",
 "In_3 - E_2*nu_0 + In_2*a_0","E_1*N_1 + E_2*N_0 + E_0*N_1*nu_0 + E_1*N_0*nu_0 - In_0*S_1*b_0 - In_1*S_0*b_0",
 "N_0*S_1 + In_0*S_0*b_0","0.22785000003994654 - In_3","In_4 - E_3*nu_0 + In_3*a_0",
 "E_1*N_2 + (2//1)*E_2*N_1 + E_3*N_0 + E_0*N_2*nu_0 + (2//1)*E_1*N_1*nu_0 + E_2*N_0*nu_0 - In_0*S_2*b_0 - (2//1)*In_1*S_1*b_0 - In_2*S_0*b_0",
 "N_0*S_2 + N_1*S_1 + In_0*S_1*b_0 + In_1*S_0*b_0","N_2","-0.09518250002782218 - In_4","In_5 - E_4*nu_0 + In_4*a_0",
 "E_1*N_3 + (3//1)*E_2*N_2 + (3//1)*E_3*N_1 + E_4*N_0 + E_0*N_3*nu_0 + (3//1)*E_1*N_2*nu_0 + (3//1)*E_2*N_1*nu_0 + E_3*N_0*nu_0 - In_0*S_3*b_0 - (3//1)*In_1*S_2*b_0 - (3//1)*In_2*S_1*b_0 - In_3*S_0*b_0",
 "N_3","N_0*S_3 + (2//1)*N_1*S_2 + N_2*S_1 + In_0*S_2*b_0 + (2//1)*In_1*S_1*b_0 + In_2*S_0*b_0","0.03985228323336705 - In_5",
 "In_6 - E_5*nu_0 + In_5*a_0",
 "E_1*N_4 + (4//1)*E_2*N_3 + (6//1)*E_3*N_2 + (4//1)*E_4*N_1 + E_5*N_0 + E_0*N_4*nu_0 + (4//1)*E_1*N_3*nu_0 + (6//1)*E_2*N_2*nu_0 + (4//1)*E_3*N_1*nu_0 + E_4*N_0*nu_0 - In_0*S_4*b_0 - (4//1)*In_1*S_3*b_0 - (6//1)*In_2*S_2*b_0 - (4//1)*In_3*S_1*b_0 - In_4*S_0*b_0",
 "N_0*S_4 + (3//1)*N_1*S_3 + (3//1)*N_2*S_2 + N_3*S_1 + In_0*S_3*b_0 + (3//1)*In_1*S_2*b_0 + (3//1)*In_2*S_1*b_0 + In_3*S_0*b_0","N_4",
]
eqs = [eval(Meta.parse(s)) for s in eq_strs]

# exact derivative-jet (n-th derivatives, Leibniz convention) for the SEIR ODE
function jet(S0,E0,In0; a,b,nu, maxord=6, N=1000.0)
    S=zeros(maxord+1); E=zeros(maxord+1); In=zeros(maxord+1); Nn=zeros(maxord+1)
    S[1]=S0; E[1]=E0; In[1]=In0; Nn[1]=N
    for k in 0:maxord-1
        SIn_k = sum(binomial(k,j)*S[j+1]*In[k-j+1] for j in 0:k)
        In[k+2] = nu*E[k+1] - a*In[k+1]
        E[k+2]  = (b/N)*SIn_k - nu*E[k+1]
        S[k+2]  = -(b/N)*SIn_k
        Nn[k+2] = 0.0
    end
    return S,E,In,Nn
end

function valvec(S0,E0,In0; a,b,nu)
    S,E,In,Nn = jet(S0,E0,In0; a=a,b=b,nu=nu)
    Dict(
      In_0=>In[1], nu_0=>nu, a_0=>a, E_0=>E[1], In_1=>In[2], N_0=>Nn[1], N_1=>Nn[2],
      E_1=>E[2], In_2=>In[3], b_0=>b, S_0=>S[1], In_3=>In[4], E_2=>E[3], S_1=>S[2],
      In_4=>In[5], E_3=>E[4], N_2=>Nn[3], S_2=>S[3], E_4=>E[5], In_5=>In[6], S_3=>S[4],
      N_3=>Nn[4], In_6=>In[7], E_5=>E[6], N_4=>Nn[5], S_4=>S[5],
    )
end

resid(d) = norm([Float64(Symbolics.value(Symbolics.substitute(eq, d))) for eq in eqs])

cases = [
 ("TRUTH   ", 990.0, 10.0, 0.0,                       0.2,                 0.4,                0.15),
 ("ANCHOR  ", 420.01056337722684, 5.62234793784651, 1.2795795700830634e-13, 0.08320754663852091, 0.46047786217746406, 0.2667924533631822),
 ("BRANCH-2", 352.1317801877017, 5.319028342517032, -2.3808610440999783e-14, 0.06799360647273368, 0.48915369730500985, 0.28200639353832047),
]
println("Residual of the SAME t0 system at each candidate (tiny => it is a root):")
for (nm,S0,E0,In0,a,b,nu) in cases
    println("  ", nm, "  ‖F‖ = ", resid(valvec(S0,E0,In0; a=a,b=b,nu=nu)))
end
