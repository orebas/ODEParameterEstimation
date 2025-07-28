# Polynomial system saved on 2025-07-28T15:22:46.963
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:22:46.962
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
    1.0604385060337094 + _t501_V_t_,
    2.0257528097961393 + _t501_Vˍt_t_,
    0.48555149328429925 + _t501_Vˍtt_t_,
    -52.43716549073526 + _t501_Vˍttt_t_,
    -27053.309641149433 + _t501_Vˍtttt_t_,
    _t501_Vˍt_t_ - (_t501_R_t_ + _t501_V_t_ - (1//3)*(_t501_V_t_^3))*_tpg_,
    _t501_Vˍtt_t_ - (_t501_Rˍt_t_ + _t501_Vˍt_t_ - (_t501_V_t_^2)*_t501_Vˍt_t_)*_tpg_,
    _t501_Vˍttt_t_ + (-_t501_Rˍtt_t_ - _t501_Vˍtt_t_ + (_t501_V_t_^2)*_t501_Vˍtt_t_ + (2//1)*_t501_V_t_*(_t501_Vˍt_t_^2))*_tpg_,
    _t501_Vˍtttt_t_ + (-_t501_Rˍttt_t_ - _t501_Vˍttt_t_ + (_t501_V_t_^2)*_t501_Vˍttt_t_ + (6//1)*_t501_V_t_*_t501_Vˍt_t_*_t501_Vˍtt_t_ + (2//1)*(_t501_Vˍt_t_^3))*_tpg_,
    -_t501_V_t_ + _tpa_ - _t501_R_t_*_tpb_ + _t501_Rˍt_t_*_tpg_,
    -_t501_Vˍt_t_ - _t501_Rˍt_t_*_tpb_ + _t501_Rˍtt_t_*_tpg_,
    -_t501_Vˍtt_t_ - _t501_Rˍtt_t_*_tpb_ + _t501_Rˍttt_t_*_tpg_
]

