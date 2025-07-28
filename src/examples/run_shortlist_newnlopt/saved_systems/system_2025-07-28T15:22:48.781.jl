# Polynomial system saved on 2025-07-28T15:22:48.781
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:22:48.781
# num_equations: 12

# Variables
varlist_str = """
_tpg_
_tpa_
_tpb_
_t501_V_t_
_t501_R_t_
_t501_Vˍt_t_
_t501_Vˍtt_t_
_t501_Vˍttt_t_
_t501_Vˍtttt_t_
_t501_Rˍt_t_
_t501_Rˍtt_t_
_t501_Rˍttt_t_
"""
@variables _tpg_ _tpa_ _tpb_ _t501_V_t_ _t501_R_t_ _t501_Vˍt_t_ _t501_Vˍtt_t_ _t501_Vˍttt_t_ _t501_Vˍtttt_t_ _t501_Rˍt_t_ _t501_Rˍtt_t_ _t501_Rˍttt_t_
varlist = [_tpg__tpa__tpb__t501_V_t__t501_R_t__t501_Vˍt_t__t501_Vˍtt_t__t501_Vˍttt_t__t501_Vˍtttt_t__t501_Rˍt_t__t501_Rˍtt_t__t501_Rˍttt_t_]

# Polynomial System
poly_system = [
    1.0604385074559521 + _t501_V_t_,
    2.0257620595248795 + _t501_Vˍt_t_,
    0.5060978994879406 + _t501_Vˍtt_t_,
    -24.189497550949454 + _t501_Vˍttt_t_,
    -59.75559711456299 + _t501_Vˍtttt_t_,
    _t501_Vˍt_t_ - (_t501_R_t_ + _t501_V_t_ - (1//3)*(_t501_V_t_^3))*_tpg_,
    _t501_Vˍtt_t_ - (_t501_Rˍt_t_ + _t501_Vˍt_t_ - (_t501_V_t_^2)*_t501_Vˍt_t_)*_tpg_,
    _t501_Vˍttt_t_ + (-_t501_Rˍtt_t_ - _t501_Vˍtt_t_ + (_t501_V_t_^2)*_t501_Vˍtt_t_ + (2//1)*_t501_V_t_*(_t501_Vˍt_t_^2))*_tpg_,
    _t501_Vˍtttt_t_ + (-_t501_Rˍttt_t_ - _t501_Vˍttt_t_ + (_t501_V_t_^2)*_t501_Vˍttt_t_ + (6//1)*_t501_V_t_*_t501_Vˍt_t_*_t501_Vˍtt_t_ + (2//1)*(_t501_Vˍt_t_^3))*_tpg_,
    -_t501_V_t_ + _tpa_ - _t501_R_t_*_tpb_ + _t501_Rˍt_t_*_tpg_,
    -_t501_Vˍt_t_ - _t501_Rˍt_t_*_tpb_ + _t501_Rˍtt_t_*_tpg_,
    -_t501_Vˍtt_t_ - _t501_Rˍtt_t_*_tpb_ + _t501_Rˍttt_t_*_tpg_
]

