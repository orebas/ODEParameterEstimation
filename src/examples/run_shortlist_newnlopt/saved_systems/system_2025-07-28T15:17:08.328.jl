# Polynomial system saved on 2025-07-28T15:17:08.329
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:08.328
# num_equations: 9

# Variables
varlist_str = """
_tpk21_
_tpke_
_t334_C1_t_
_t334_C2_t_
_t334_C1ˍt_t_
_t334_C1ˍtt_t_
_t334_C1ˍttt_t_
_t334_C2ˍt_t_
_t334_C2ˍtt_t_
"""
@variables _tpk21_ _tpke_ _t334_C1_t_ _t334_C2_t_ _t334_C1ˍt_t_ _t334_C1ˍtt_t_ _t334_C1ˍttt_t_ _t334_C2ˍt_t_ _t334_C2ˍtt_t_
varlist = [_tpk21__tpke__t334_C1_t__t334_C2_t__t334_C1ˍt_t__t334_C1ˍtt_t__t334_C1ˍttt_t__t334_C2ˍt_t__t334_C2ˍtt_t_]

# Polynomial System
poly_system = [
    -0.6258193047912446 + _t334_C1_t_,
    0.02740971280486295 + _t334_C1ˍt_t_,
    -0.0012007601456079549 + _t334_C1ˍtt_t_,
    5.2151819968369105e-5 + _t334_C1ˍttt_t_,
    0.48590192719908576_t334_C1_t_ + _t334_C1ˍt_t_ + _t334_C1_t_*_tpke_ - 0.044042524232730244_t334_C2_t_*_tpk21_,
    0.48590192719908576_t334_C1ˍt_t_ + _t334_C1ˍtt_t_ + _t334_C1ˍt_t_*_tpke_ - 0.044042524232730244_t334_C2ˍt_t_*_tpk21_,
    0.48590192719908576_t334_C1ˍtt_t_ + _t334_C1ˍttt_t_ + _t334_C1ˍtt_t_*_tpke_ - 0.044042524232730244_t334_C2ˍtt_t_*_tpk21_,
    -11.032563089060805_t334_C1_t_ + _t334_C2ˍt_t_ + _t334_C2_t_*_tpk21_,
    -11.032563089060805_t334_C1ˍt_t_ + _t334_C2ˍtt_t_ + _t334_C2ˍt_t_*_tpk21_
]

