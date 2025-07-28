# Polynomial system saved on 2025-07-28T15:17:13.896
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:13.896
# num_equations: 9

# Variables
varlist_str = """
_tpk21_
_tpke_
_t501_C1_t_
_t501_C2_t_
_t501_C1ˍt_t_
_t501_C1ˍtt_t_
_t501_C1ˍttt_t_
_t501_C2ˍt_t_
_t501_C2ˍtt_t_
"""
@variables _tpk21_ _tpke_ _t501_C1_t_ _t501_C2_t_ _t501_C1ˍt_t_ _t501_C1ˍtt_t_ _t501_C1ˍttt_t_ _t501_C2ˍt_t_ _t501_C2ˍtt_t_
varlist = [_tpk21__tpke__t501_C1_t__t501_C2_t__t501_C1ˍt_t__t501_C1ˍtt_t__t501_C1ˍttt_t__t501_C2ˍt_t__t501_C2ˍtt_t_]

# Polynomial System
poly_system = [
    -0.3100987732488813 + _t501_C1_t_,
    0.013581730806923376 + _t501_C1ˍt_t_,
    -0.0005948537288629763 + _t501_C1ˍtt_t_,
    2.6053451831986596e-5 + _t501_C1ˍttt_t_,
    0.7910424225971253_t501_C1_t_ + _t501_C1ˍt_t_ + _t501_C1_t_*_tpke_ - 0.9484448654325145_t501_C2_t_*_tpk21_,
    0.7910424225971253_t501_C1ˍt_t_ + _t501_C1ˍtt_t_ + _t501_C1ˍt_t_*_tpke_ - 0.9484448654325145_t501_C2ˍt_t_*_tpk21_,
    0.7910424225971253_t501_C1ˍtt_t_ + _t501_C1ˍttt_t_ + _t501_C1ˍtt_t_*_tpke_ - 0.9484448654325145_t501_C2ˍtt_t_*_tpk21_,
    -0.8340415467760378_t501_C1_t_ + _t501_C2ˍt_t_ + _t501_C2_t_*_tpk21_,
    -0.8340415467760378_t501_C1ˍt_t_ + _t501_C2ˍtt_t_ + _t501_C2ˍt_t_*_tpk21_
]

