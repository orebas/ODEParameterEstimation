#!/usr/bin/env python3
"""Sneyd derivative-information probe; no fitting, SI, HC, or package changes.

Uses SymPy for SBML/formula checks, exact finite-field Jacobian ranks, and
mpmath for a separate fully observed, reachable later-anchor check. Reported
ranks concern local parameter information, not uniqueness or noisy recovery.
"""
import argparse
import csv,json,math,random,hashlib,sys
import xml.etree.ElementTree as ET
from pathlib import Path
import sympy as sp
import mpmath as mp

PARAMETERS = 'k1 k2 k3 k4 k_1 k_2 k_3 k_4 l2 l4 l6 l_2 l_4 l_6'.split()
STATES = 'IPR_A IPR_I1 IPR_I2 IPR_O IPR_R IPR_S'.split()

P=2147483647
N=14
class Jet:
    def __init__(self,v,g=None):
        self.v=int(v)%P; self.g=[0]*N if g is None else [int(x)%P for x in g]
    def __add__(a,b):
        if not isinstance(b,Jet):b=Jet(b)
        return Jet(a.v+b.v,[x+y for x,y in zip(a.g,b.g)])
    __radd__=__add__
    def __neg__(a):return Jet(-a.v,[-x for x in a.g])
    def __sub__(a,b):return a+-b
    def __rsub__(a,b):return -a+b
    def __mul__(a,b):
        if not isinstance(b,Jet):b=Jet(b)
        return Jet(a.v*b.v,[x*b.v+y*a.v for x,y in zip(a.g,b.g)])
    __rmul__=__mul__
    def __pow__(a,n):
        if a.v==0 and n<0:raise ZeroDivisionError()
        if n==0:return Jet(1)
        return Jet(pow(a.v,n,P),[n*pow(a.v,n-1,P)*g for g in a.g])
    def __truediv__(a,b):
        if not isinstance(b,Jet):b=Jet(b)
        return a*b**-1
    def __rtruediv__(a,b):return Jet(b)*a**-1

def rank(rows):
    a=[list(r) for r in rows]; k=0
    if not a:return 0
    for j in range(len(a[0])):
        pivot=next((i for i in range(k,len(a)) if a[i][j]%P),None)
        if pivot is None:continue
        a[k],a[pivot]=a[pivot],a[k];v=pow(a[k][j],-1,P)
        a[k]=[(x*v)%P for x in a[k]]
        for i in range(k+1,len(a)):
            c=a[i][j]
            if c:a[i]=[(x-c*y)%P for x,y in zip(a[i],a[k])]
        k+=1
        if k==len(a):break
    return k

def qmatrix(theta,c,p):
    k1,k2,k3,k4,km1,km2,km3,km4,l2,l4,l6,lm2,lm4,lm6=theta
    L1=km1*l2/(k1*lm2);L3=km2*l4/(k2*lm4);L5=km4*l6/(k4*lm6)
    rates=[(c*lm4+km2)/(c/L5+1),p*(c*l4+L3*k2)/(c*(1+L3/L1)+L3),c*(L1*k1+l2)/(c*(L1/L3+1)+L1),km1+lm2,c*(L5*k4+l6)/(c+L5),L1*(km4+lm6)/(c+L1),c*(L1*k1+l2)/(c+L1),L5*k3/(c+L5),km3]
    return q_from_rates(rates),rates

def q_from_rates(rates):
    # order A,I1,I2,O,R,S; each edge is source,destination,rate index
    q=[[0 for j in range(6)] for i in range(6)]
    for a,b,r in [(3,4,0),(4,3,1),(4,1,2),(1,4,3),(3,0,4),(0,3,5),(0,2,6),(2,0,3),(3,5,7),(5,3,8)]:
        q[b][a]=q[b][a]+rates[r];q[a][a]=q[a][a]-rates[r]
    return q

def jets(q,x,order):
    v=[Jet(a) for a in x]; xs=[v]; zs=[]
    for k in range(order+1):
        zs.append((9*v[0]+v[3])/10)
        if k<order:
            v=[sum(q[i][j]*v[j] for j in range(6)) for i in range(6)];xs.append(v)
    def conv(a,b):return [sum(math.comb(k,j)*a[j]*b[k-j] for j in range(k+1)) for k in range(order+1)]
    zz=conv(zs,zs);ys=conv(zz,zz)
    return xs,zs,ys

def rational_mod(value):
    value=sp.Rational(value)
    return int(value.p)*pow(int(value.q),-1,P)%P


def mathml(node):
    tag=node.tag.split('}')[-1]
    if tag=='math':return mathml(node[0])
    if tag=='ci':return sp.Symbol(node.text.strip())
    if tag=='cn':return sp.Rational(node.text.strip())
    assert tag=='apply',tag
    op=node[0].tag.split('}')[-1];args=[mathml(x) for x in node[1:]]
    if op=='plus':return sp.Add(*args)
    if op=='times':return sp.Mul(*args)
    if op=='divide':return args[0]/args[1]
    if op=='power':return args[0]**args[1]
    if op=='minus':return -args[0] if len(args)==1 else args[0]-args[1]
    raise ValueError(op)


def validate_sbml(model):
    root=ET.parse(model/'model_Sneyd_PNAS2002.xml').getroot()
    assignments={sp.Symbol(r.attrib['variable']):mathml(r.find('{*}math'))
                 for r in root.findall('.//{*}assignmentRule')}
    q=sp.zeros(6);state_symbols=sp.symbols(' '.join(STATES))
    for reaction in root.findall('.//{*}reaction'):
        rate=mathml(reaction.find('{*}kineticLaw/{*}math')).subs(assignments)
        for group,sign in [('listOfReactants',-1),('listOfProducts',1)]:
            for ref in reaction.findall('{*}'+group+'/{*}speciesReference'):
                i=STATES.index(ref.attrib['species'])
                stoich=sp.Rational(ref.attrib.get('stoichiometry','1'))
                for j,state in enumerate(state_symbols):
                    q[i,j]+=sign*stoich*sp.diff(rate,state)
    theta=sp.symbols(' '.join(PARAMETERS));c,p=sp.symbols('Ca IP3')
    manual,rates=qmatrix(theta,c,p)
    assert all(sp.cancel(a-b)==0 for a,b in zip(q,sp.Matrix(manual)))
    assert all(sp.cancel(sum(q[:,j]))==0 for j in range(6))
    initial={s.attrib['id']:sp.Rational(s.attrib['initialConcentration'])
             for s in root.findall('.//{*}species')}
    assert [initial[s] for s in STATES]==[0,0,0,0,1,0]
    observable=list(csv.DictReader((model/'observables_Sneyd_PNAS2002.tsv').open(),delimiter='\t'))[0]
    actual_y=sp.sympify(observable['observableFormula'].replace('^','**'),rational=True)
    assert sp.expand(actual_y-((9*state_symbols[0]+state_symbols[3])/10)**4)==0

    # An exact 12-combination factorization of the complete input->rate map.
    L1,U1,V1,L5,U5,V5,b2,bm2,d4,dm4,b3,bm3=sp.symbols('L1 U1 V1 L5 U5 V5 b2 bm2 d4 dm4 b3 bm3')
    eta=(L1,U1,V1,L5,U5,V5,b2,bm2,d4,dm4,b3,bm3)
    k1,k2,k3,k4,km1,km2,km3,km4,l2,l4,l6,lm2,lm4,lm6=theta
    a1=km1*l2/(k1*lm2);a5=km4*l6/(k4*lm6)
    combinations=(a1,a1*k1+l2,km1+lm2,a5,a5*k4+l6,km4+lm6,k2,km2,l4,lm4,k3,km3)
    L3=bm2*d4/(b2*dm4)
    reduced=[(c*dm4+bm2)/(c/L5+1),p*(c*d4+L3*b2)/(c*(1+L3/L1)+L3),
             c*U1/(c*(1+L1/L3)+L1),V1,c*U5/(c+L5),L1*V5/(c+L1),
             c*U1/(c+L1),L5*b3/(c+L5),bm3]
    replacement=dict(zip(eta,combinations))
    assert all(sp.cancel(a-b.subs(replacement,simultaneous=True))==0 for a,b in zip(rates,reduced))
    L,U,V,a=sp.symbols('L U V a',positive=True)
    forward_other=U-L*a;reverse_a=L*a*V/U;reverse_other=(1-L*a/U)*V
    assert sp.cancel(reverse_a*forward_other/(a*reverse_other)-L)==0
    assert sp.cancel(L*a+forward_other-U)==0
    assert sp.cancel(reverse_a+reverse_other-V)==0

    # Validate the displayed prepared output identities without parameter substitution.
    phi=sp.symbols('f1:10');free_q=sp.Matrix(q_from_rates(phi));x=sp.Matrix([0,0,0,0,1,0])
    z=[]
    for k in range(4):
        z.append(sp.expand((9*x[0]+x[3])/10));x=free_q*x
    f1,f2,f3,f4,f5,f6,f7,f8,f9=phi
    assert z[0]==0 and z[1]==f2/10
    assert sp.expand(z[2]-f2*(8*f5-f1-f2-f3-f8)/10)==0
    # First two rooted derivatives over *any* input design factor through
    # seven quantities. This supplies an exact upper bound, not just sampled
    # ranks below the 12-combination ceiling.
    delta=L1*L3/(L1+L3)
    alpha=L1*d4/(L1+L3);beta=delta*b2;gamma=L3*U1/(L1+L3)
    h1=8*U5-L5*dm4;h0=-L5*(bm2+b3)
    phi2=p*(alpha*c+beta)/(c+delta)
    assert sp.cancel(phi2-reduced[1])==0
    second=phi2*((h1*c+h0)/(c+L5)-phi2-gamma*c/(c+delta))/10
    assert sp.cancel(second-reduced[1]*(8*reduced[4]-reduced[0]-reduced[1]-reduced[2]-reduced[7])/10)==0
    t,aa,bb,dd=sp.symbols('t a b d')
    y=sp.Poly((aa*t+bb*t**2/2+dd*t**3/6)**4,t)
    assert 24*y.nth(4)==24*aa**4
    assert sp.expand(120*y.nth(5)-240*aa**3*bb)==0
    assert sp.expand(720*y.nth(6)-480*aa**3*dd-1080*aa**2*bb**2)==0
    nominal={p.attrib['id']:p.attrib['value'] for p in root.findall('.//{*}parameter')}
    return {'q':q,'rates':rates,'theta':theta,'c':c,'p':p,'nominal':nominal,
            'reduced_q':sp.Matrix(q_from_rates(reduced)),'eta':eta,'combinations':combinations,
            'prepared_rooted_third_derivative':str(sp.factor(z[3]))}


def modular_case(conditions,values,seed,order=12):
    rng=random.Random(seed)
    theta=[Jet(rational_mod(v),[int(i==j) for j in range(N)]) for i,v in enumerate(values)]
    cases=[];rate_rows=[];anchors={}
    for condition in (conditions if N==14 else conditions[:1]):
        c=Jet(rational_mod(condition['Ca']));p=Jet(rational_mod(condition['IP3']))
        q,r=qmatrix(theta,c,p) if N==14 else (q_from_rates(theta),theta)
        rate_rows.extend(x.g for x in r)
        key=(c.v,p.v)
        if key not in anchors:
            z=[rng.randrange(1,50) for _ in range(6)];inv=pow(sum(z),-1,P)
            anchors[key]=[a*inv%P for a in z]
        cases.append((jets(q,[0,0,0,0,1,0],order),jets(q,anchors[key],order)))
    out={'prime':P,'parameter_count':N,'values':list(map(str,values)),
         'seed':seed,'rate_map_rank':rank(rate_rows),'ranks':{}}
    for group,label in [(0,'prepared'),(1,'arbitrary_known_positive_anchor')]:
        out['ranks'][label]={}
        for member,name in [(1,'rooted'),(2,'quartic'),(0,'all_states')]:
            ranks=[];rows=[]
            for k in range(order+1):
                for case in cases:
                    val=case[group][member][k]
                    rows.extend([v.g for v in val] if member==0 else [val.g])
                ranks.append(rank(rows))
            out['ranks'][label][name]=ranks
    return out


def validate_modular_ad(model):
    """Check the rate AD against independent symbolic differentiation."""
    assert N==14
    values=list(range(2,16));c=sp.Rational(1,10);p=sp.Integer(10)
    substitutions=dict(zip(model['theta'],values)) | {model['c']:c,model['p']:p}
    theta=[Jet(v,[int(i==j) for j in range(N)]) for i,v in enumerate(values)]
    _,rates=qmatrix(theta,Jet(rational_mod(c)),Jet(rational_mod(p)))
    for symbolic,automatic in zip(model['rates'],rates):
        assert automatic.v==rational_mod(symbolic.subs(substitutions))
        assert automatic.g==[rational_mod(sp.diff(symbolic,v).subs(substitutions)) for v in model['theta']]


def reachable_later_check(model,conditions,values,dps):
    """Hold each actual x(t*) fixed when differentiating Q(eta)x(t*).

    Differentiate only Q: x is fully observed, not an unknown state or a
    parameter-dependent prediction here. Use relative columns and row scaling
    solely to report diagnostic singular values at high precision.
    """
    mp.mp.dps=dps
    theta=model['theta'];c=model['c'];p=model['p'];eta=model['eta']
    replacements=dict(zip(theta,map(sp.Rational,values)))
    eta_values=[v.subs(replacements) for v in model['combinations']]
    substitutions=dict(zip(eta,eta_values))
    q=model['reduced_q'];dq=[q.diff(v) for v in eta]
    x0=mp.matrix([0,0,0,0,1,0]);rows=[];min_state=mp.mpf(1)
    def number(x):return mp.mpf(str(x.p))/mp.mpf(str(x.q))
    def matrix(x):return mp.matrix([[number(x[i,j]) for j in range(x.cols)] for i in range(x.rows)])
    for condition in conditions:
        sub=substitutions | {c:sp.Rational(condition['Ca']),p:sp.Rational(condition['IP3'])}
        qm=matrix(q.subs(sub));anchor=mp.expm(qm*mp.mpf('0.01'))*x0
        min_state=min(min_state,*anchor)
        columns=[matrix(derivative.subs(sub))*anchor*number(v) for derivative,v in zip(dq,eta_values)]
        for i in range(6):
            row=[column[i] for column in columns];scale=max(map(abs,row))
            rows.append([v/scale for v in row] if scale else row)
    singular=mp.svd(mp.matrix(rows),compute_uv=False)
    return {'digits':dps,'time':'0.01','rows':len(rows),'columns':12,
            'smallest_state':mp.nstr(min_state,20),
            'singular_values':list(map(lambda v:mp.nstr(v,20),singular)),
            'numerical_rank_at_relative_1e_minus_40':sum(v>singular[0]*mp.mpf('1e-40') for v in singular)}


def main():
    global N,P
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--model-dir',type=Path,required=True)
    parser.add_argument('--output',type=Path,default=Path(__file__).parent/'evidence/results.json')
    args=parser.parse_args();model=args.model_dir
    symbolic=validate_sbml(model)
    print('SBML generator, preparation, output, and 12-combination factorization verified.',flush=True)
    conditions=list(csv.DictReader((model/'experimentalCondition_Sneyd_PNAS2002.tsv').open(),delimiter='\t'))
    result={'method':'Exact modular Jacobian ranks of raw derivatives with known anchors; no recovery solve.',
            'python':sys.version,'sympy':sp.__version__,'mpmath':mp.__version__,
            'source_sha256':{f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted(model.iterdir()) if f.suffix in ['.xml','.tsv','.yaml']},
            'conditions':conditions,'symbolic_validation':True,'structural_upper_bound':12,
            'prepared_rooted_rank_upper_bounds_by_order':[0,3,7,12],
            'probe_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            'prepared_rooted_third_derivative':symbolic['prepared_rooted_third_derivative'],
            'modular_cases':[],'reachable_later_checks':[]}
    for P in [2147483647,1000000007]:
        N=14;validate_modular_ad(symbolic)
        for N in [14,9]:
            for seed in [1,2,3]:
                rng=random.Random(seed);values=[rng.randrange(2,100) for _ in range(N)]
                case=modular_case(conditions,values,seed)
                result['modular_cases'].append(case)
                print(P,N,seed,case['ranks']['prepared'],flush=True)
        N=14
        case=modular_case(conditions,[symbolic['nominal'][p] for p in PARAMETERS],4)
        case['nominal_sbml_values']=True;result['modular_cases'].append(case)
        print(P,'nominal',case['ranks']['prepared'],flush=True)
    for dps in [70,100]:
        rng=random.Random(1);values=[rng.randrange(2,100) for _ in range(14)]
        record=reachable_later_check(symbolic,conditions,values,dps);record['parameters']='moderate_seed_1'
        result['reachable_later_checks'].append(record);print('reachable',record,flush=True)
        record=reachable_later_check(symbolic,conditions,[symbolic['nominal'][p] for p in PARAMETERS],dps)
        record['parameters']='nominal_sbml';result['reachable_later_checks'].append(record)
        print('reachable',record,flush=True)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(result,indent=2)+'\n')


if __name__=='__main__':main()
