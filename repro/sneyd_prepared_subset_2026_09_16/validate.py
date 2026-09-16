#!/usr/bin/env python3
"""Independent finite-field rank checks and full rational validation of HC roots."""
import argparse
import importlib.util
import json
import math
from pathlib import Path

import mpmath as mp
import sympy as sp

HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location("prepared",HERE.parent/"sneyd_prepared_jets_2026_09_16/probe.py")
prepared=importlib.util.module_from_spec(spec);spec.loader.exec_module(prepared)


def rates(eta,c,p):
    L1,U1,V1,L5,U5,V5,k2,km2,l4,lm4,k3,km3=eta
    L3=km2*l4/(k2*lm4)
    return [(c*lm4+km2)/(c/L5+1),p*(c*l4+L3*k2)/(c*(1+L3/L1)+L3),
            c*U1/(c*(1+L1/L3)+L1),V1,c*U5/(c+L5),L1*V5/(c+L1),
            c*U1/(c+L1),L5*k3/(c+L5),km3]


def jets(f):
    f1,f2,f3,f4,f5,f6,f7,f8,f9=f;u=f2+f3;v=f1+f5+f8
    return [f2/10,f2*(9*f5-u-v)/10,
            f2*(u*u+f1*f2+f4*f3+(v-9*f5)*(u+v)-8*f5*f6-9*f5*f7+f8*f9)/10]


def mod_number(s):
    r=sp.Rational(s);return int(r.p)*pow(int(r.q),-1,prepared.P)%prepared.P


def mod_poly(terms,values):
    total=0
    for term in terms:
        v=mod_number(term["numerator"]+"/"+term["denominator"])
        for x,e in zip(values,term["exponents"]):v=v*pow(x,e,prepared.P)%prepared.P
        total=(total+v)%prepared.P
    return total


def modular_check(system,selected):
    prepared.N=12;results=[]
    probes={"generic_2_to_13":list(range(2,14))}
    for label in ("moderate","nominal"):
        oracle=json.loads((HERE.parent/"sneyd_manual_hc_2026_09_16/evidence"/label/"oracle.json").read_text())
        probes[label]=oracle["eta"]
    for prime in (2147483647,1000000007):
        prepared.P=prime
        for label,values in probes.items():
            values=list(map(mod_number,values))
            eta=[prepared.Jet(x,[int(i==j) for j in range(12)]) for i,x in enumerate(values)]
            jacobian=[]
            for row in system["rows"]:
                c,p=(prepared.Jet(mod_number(row[key])) for key in ("Ca","IP3"))
                jet=jets(rates(eta,c,p))[row["order"]-1]
                n,d=(mod_poly(row[key],values) for key in ("numerator","denominator"))
                assert d!=0 and n*pow(d,-1,prime)%prime==jet.v
                jacobian.append(jet.g)
            profile=[prepared.rank([r for r,meta in zip(jacobian,system["rows"]) if meta["order"]<=order])
                     for order in (1,2,3)]
            selected_rank=prepared.rank([jacobian[i-1] for i in selected])
            assert profile==[3,7,12] and selected_rank==12
            results.append({"prime":prime,"probe":label,"full_ranks_by_order":profile,"selected_rank":selected_rank})
    return results


def number(s):
    parts=s.split("/");return mp.mpf(parts[0])/(mp.mpf(parts[1]) if len(parts)==2 else 1)


def root_check(system,solve):
    mp.mp.dps=100;label=solve["case"]
    oracle=json.loads((HERE.parent/"sneyd_manual_hc_2026_09_16/evidence"/label/"oracle.json").read_text())
    truth=list(map(number,oracle["eta"]));targets=list(map(number,system["cases"][label]["targets"]))
    roots=[]
    for index,(re,im) in enumerate(zip(solve["roots_real"],solve["roots_imag"]),1):
        root=[mp.mpc(a,b) for a,b in zip(re,im)]
        recovery=max(abs(x-t)/abs(t) for x,t in zip(root,truth))
        imag=max(abs(mp.im(x))/max(1,abs(mp.re(x))) for x in root)
        result={"index":index,"max_relative_eta_error":float(recovery),
                "max_scaled_imaginary":float(imag),"positive_real_parts":all(mp.re(x)>0 for x in root)}
        try:
            errors=[]
            for row,target in zip(system["rows"],targets):
                value=jets(rates(root,number(row["Ca"]),number(row["IP3"])))[row["order"]-1]
                errors.append(abs(value-target)/max(abs(target),mp.mpf("1e-100")))
            result["all_27_max_relative_jet_residual"]=float(max(errors))
            result["selected_max_relative_jet_residual"]=float(max(errors[i-1] for i in solve["selected_rows"]))
            result["validated_positive_root"]=bool(imag<mp.mpf("1e-7") and all(mp.re(x)>0 for x in root)
                and max(errors)<mp.mpf("1e-7"))
        except (ZeroDivisionError,ValueError):
            result["undefined_rational_map"]=True;result["validated_positive_root"]=False
        result["recovered_generating_eta"]=bool(result["validated_positive_root"] and recovery<mp.mpf("1e-6"))
        roots.append(result)
    return {"solve_status":solve["status"],"case":label,"root_count":len(roots),
            "validated_positive_endpoints":sum(r["validated_positive_root"] for r in roots),
            "recovered_eta_endpoints":sum(r["recovered_generating_eta"] for r in roots),
            "best_relative_eta_error":min((r["max_relative_eta_error"] for r in roots),default=None),
            "roots":roots}


def v1_sensitivity(system,label):
    """Oracle-only precision diagnostic; never supplied to either solver."""
    oracle=json.loads((HERE.parent/"sneyd_manual_hc_2026_09_16/evidence"/label/"oracle.json").read_text())
    eta=list(map(sp.Rational,oracle["eta"]));eta[2]*=2
    equal_rows=0;details=[]
    for row,target in zip(system["rows"],system["cases"][label]["targets"]):
        c,p=map(sp.Rational,(row["Ca"],row["IP3"]))
        old=sp.Rational(target);new=jets(rates(eta,c,p))[row["order"]-1]
        equal=float(old)==float(new);equal_rows+=equal
        if row["order"]==3:
            change=new-old
            details.append({"condition":row["condition_id"],"old_jet":str(old),"new_jet":str(new),
                "relative_change":abs(float(change/old)),"Float64_equal":equal,
                "change_in_float64_ulps":float(change)/math.ulp(float(old))})
    return {"case":label,"perturbed_parameter":"V1","factor":2,"float64_equal_rows":equal_rows,
            "row_count":27,"third_derivative_details":details}


def relative_conditioning(system,selected,label):
    """100-digit local relative sensitivities; oracle-only, not solver scaling."""
    mp.mp.dps=100
    oracle=json.loads((HERE.parent/"sneyd_manual_hc_2026_09_16/evidence"/label/"oracle.json").read_text())
    eta=list(map(number,oracle["eta"]));targets=list(map(number,system["cases"][label]["targets"]))
    rows=[]
    for row,target in zip(system["rows"],targets):
        c,p=map(number,(row["Ca"],row["IP3"]));values=[]
        for j,x in enumerate(eta):
            def f(value):
                changed=eta.copy();changed[j]=value
                return jets(rates(changed,c,p))[row["order"]-1]
            values.append(mp.diff(f,x)*x/target)
        rows.append(values)
    result={"case":label,"arithmetic_digits":100,
            "matrix":"diag(1 / true jets) * J * diag(true eta)","oracle_only":True}
    for key,rr in (("full",rows),("selected",[rows[i-1] for i in selected])):
        singular=mp.svd(mp.matrix(rr),compute_uv=False)
        result[key]={"singular_values":[mp.nstr(s,35) for s in singular],
                     "condition_number":mp.nstr(singular[0]/singular[singular.rows-1],35)}
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("system",type=Path);parser.add_argument("selection",type=Path)
    parser.add_argument("output",type=Path);parser.add_argument("--solve",type=Path,action="append",default=[])
    args=parser.parse_args()
    system=json.loads(args.system.read_text());selection=json.loads(args.selection.read_text())
    pole_component=all(all(term["exponents"][0]+term["exponents"][8]>0
                           for key in ("numerator","denominator") for term in row[key])
                       for row in system["rows"])
    assert pole_component
    record={"modular_checks":modular_check(system,selection["selected_rows"]),
            "all_polynomials_vanish_when_L1_and_d4_zero":pole_component,
            "V1_sensitivity":[v1_sensitivity(system,label) for label in ("moderate","nominal")],
            "relative_conditioning":[relative_conditioning(system,selection["selected_rows"],label)
                                     for label in ("moderate","nominal")],
            "root_checks":[root_check(system,json.loads(p.read_text())) for p in args.solve]}
    args.output.write_text(json.dumps(record,indent=2)+"\n")
    print(json.dumps({"rank_checks":record["modular_checks"],
                      "solves":[{k:v for k,v in r.items() if k!="roots"} for r in record["root_checks"]]},indent=2))


if __name__=="__main__":main()
