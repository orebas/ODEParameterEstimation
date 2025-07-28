# Polynomial system saved on 2025-07-28T15:17:09.190
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:09.189
# num_equations: 9

# Variables
varlist_str = """
_tpk21_
_tpke_
_t390_C1_t_
_t390_C2_t_
_t390_C1ˍt_t_
_t390_C1ˍtt_t_
_t390_C1ˍttt_t_
_t390_C2ˍt_t_
_t390_C2ˍtt_t_
"""
@variables _tpk21_ _tpke_ _t390_C1_t_ _t390_C2_t_ _t390_C1ˍt_t_ _t390_C1ˍtt_t_ _t390_C1ˍttt_t_ _t390_C2ˍt_t_ _t390_C2ˍtt_t_
varlist = [_tpk21__tpke__t390_C1_t__t390_C2_t__t390_C1ˍt_t__t390_C1ˍtt_t__t390_C1ˍttt_t__t390_C2ˍt_t__t390_C2ˍtt_t_]

# Polynomial System
poly_system = [
    -0.49452772623764507 + _t390_C1_t_,
    0.021659383082712987 + _t390_C1ˍt_t_,
    -0.0009485502817678518 + _t390_C1ˍtt_t_,
    4.143624237920537e-5 + _t390_C1ˍttt_t_,
    0.35906143208490626_t390_C1_t_ + _t390_C1ˍt_t_ + _t390_C1_t_*_tpke_ - 2.301855494457389_t390_C2_t_*_tpk21_,
    0.35906143208490626_t390_C1ˍt_t_ + _t390_C1ˍtt_t_ + _t390_C1ˍt_t_*_tpke_ - 2.301855494457389_t390_C2ˍt_t_*_tpk21_,
    0.35906143208490626_t390_C1ˍtt_t_ + _t390_C1ˍttt_t_ + _t390_C1ˍtt_t_*_tpke_ - 2.301855494457389_t390_C2ˍtt_t_*_tpk21_,
    -0.15598782501746353_t390_C1_t_ + _t390_C2ˍt_t_ + _t390_C2_t_*_tpk21_,
    -0.15598782501746353_t390_C1ˍt_t_ + _t390_C2ˍtt_t_ + _t390_C2ˍt_t_*_tpk21_
]

