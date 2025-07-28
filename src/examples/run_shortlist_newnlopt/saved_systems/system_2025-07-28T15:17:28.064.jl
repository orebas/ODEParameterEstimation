# Polynomial system saved on 2025-07-28T15:17:28.064
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:17:28.064
# num_equations: 12

# Variables
varlist_str = """
_tpk21_
_tpke_
_t390_C1_t_
_t390_C2_t_
_t390_C1ˍt_t_
_t390_C1ˍtt_t_
_t390_C2ˍt_t_
_t501_C1_t_
_t501_C2_t_
_t501_C1ˍt_t_
_t501_C1ˍtt_t_
_t501_C2ˍt_t_
"""
@variables _tpk21_ _tpke_ _t390_C1_t_ _t390_C2_t_ _t390_C1ˍt_t_ _t390_C1ˍtt_t_ _t390_C2ˍt_t_ _t501_C1_t_ _t501_C2_t_ _t501_C1ˍt_t_ _t501_C1ˍtt_t_ _t501_C2ˍt_t_
varlist = [_tpk21__tpke__t390_C1_t__t390_C2_t__t390_C1ˍt_t__t390_C1ˍtt_t__t390_C2ˍt_t__t501_C1_t__t501_C2_t__t501_C1ˍt_t__t501_C1ˍtt_t__t501_C2ˍt_t_]

# Polynomial System
poly_system = [
    -0.4945277063235327 + _t390_C1_t_,
    0.021659342251431745 + _t390_C1ˍt_t_,
    -0.0009486919654115228 + _t390_C1ˍtt_t_,
    0.8679157004048588_t390_C1_t_ + _t390_C1ˍt_t_ + _t390_C1_t_*_tpke_ - 1.1824653499659303_t390_C2_t_*_tpk21_,
    0.8679157004048588_t390_C1ˍt_t_ + _t390_C1ˍtt_t_ + _t390_C1ˍt_t_*_tpke_ - 1.1824653499659303_t390_C2ˍt_t_*_tpk21_,
    -0.733988273254574_t390_C1_t_ + _t390_C2ˍt_t_ + _t390_C2_t_*_tpk21_,
    -0.3100987704254481 + _t501_C1_t_,
    0.013581961418225054 + _t501_C1ˍt_t_,
    -0.0005908567805463557 + _t501_C1ˍtt_t_,
    0.8679157004048588_t501_C1_t_ + _t501_C1ˍt_t_ + _t501_C1_t_*_tpke_ - 1.1824653499659303_t501_C2_t_*_tpk21_,
    0.8679157004048588_t501_C1ˍt_t_ + _t501_C1ˍtt_t_ + _t501_C1ˍt_t_*_tpke_ - 1.1824653499659303_t501_C2ˍt_t_*_tpk21_,
    -0.733988273254574_t501_C1_t_ + _t501_C2ˍt_t_ + _t501_C2_t_*_tpk21_
]

