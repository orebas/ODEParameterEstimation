# Polynomial system saved on 2025-07-28T15:17:13.272
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:17:13.272
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
    -0.49452772099358155 + _t390_C1_t_,
    0.0216593645718072 + _t390_C1ˍt_t_,
    -0.0009486385772714545 + _t390_C1ˍtt_t_,
    4.154854810167058e-5 + _t390_C1ˍttt_t_,
    0.5488305442342104_t390_C1_t_ + _t390_C1ˍt_t_ + _t390_C1_t_*_tpke_ - 1.582862938076134_t390_C2_t_*_tpk21_,
    0.5488305442342104_t390_C1ˍt_t_ + _t390_C1ˍtt_t_ + _t390_C1ˍt_t_*_tpke_ - 1.582862938076134_t390_C2ˍt_t_*_tpk21_,
    0.5488305442342104_t390_C1ˍtt_t_ + _t390_C1ˍttt_t_ + _t390_C1ˍtt_t_*_tpke_ - 1.582862938076134_t390_C2ˍtt_t_*_tpk21_,
    -0.34673282887100626_t390_C1_t_ + _t390_C2ˍt_t_ + _t390_C2_t_*_tpk21_,
    -0.34673282887100626_t390_C1ˍt_t_ + _t390_C2ˍtt_t_ + _t390_C2ˍt_t_*_tpk21_
]

