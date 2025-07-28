# Polynomial system saved on 2025-07-28T15:24:02.247
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:24:02.247
# num_equations: 18

# Variables
varlist_str = """
_tpg_
_tpa_
_tpb_
_t445_V_t_
_t445_R_t_
_t445_Vˍt_t_
_t445_Vˍtt_t_
_t445_Vˍttt_t_
_t445_Rˍt_t_
_t445_Rˍtt_t_
_t501_V_t_
_t501_R_t_
_t501_Vˍt_t_
_t501_Vˍtt_t_
_t501_Vˍttt_t_
_t501_Rˍt_t_
_t501_Rˍtt_t_
"""
@variables _tpg_ _tpa_ _tpb_ _t445_V_t_ _t445_R_t_ _t445_Vˍt_t_ _t445_Vˍtt_t_ _t445_Vˍttt_t_ _t445_Rˍt_t_ _t445_Rˍtt_t_ _t501_V_t_ _t501_R_t_ _t501_Vˍt_t_ _t501_Vˍtt_t_ _t501_Vˍttt_t_ _t501_Rˍt_t_ _t501_Rˍtt_t_
varlist = [_tpg__tpa__tpb__t445_V_t__t445_R_t__t445_Vˍt_t__t445_Vˍtt_t__t445_Vˍttt_t__t445_Rˍt_t__t445_Rˍtt_t__t501_V_t__t501_R_t__t501_Vˍt_t__t501_Vˍtt_t__t501_Vˍttt_t__t501_Rˍt_t__t501_Rˍtt_t_]

# Polynomial System
poly_system = [
    1.0536349564127752 + _t445_V_t_,
    2.0239252794614817 + _t445_Vˍt_t_,
    0.5870075162535691 + _t445_Vˍtt_t_,
    -23.78650017548145 + _t445_Vˍttt_t_,
    _t445_Vˍt_t_ - (_t445_R_t_ + _t445_V_t_ - (1//3)*(_t445_V_t_^3))*_tpg_,
    _t445_Vˍtt_t_ - (_t445_Rˍt_t_ + _t445_Vˍt_t_ - (_t445_V_t_^2)*_t445_Vˍt_t_)*_tpg_,
    _t445_Vˍttt_t_ + (-_t445_Rˍtt_t_ - _t445_Vˍtt_t_ + (_t445_V_t_^2)*_t445_Vˍtt_t_ + (2//1)*_t445_V_t_*(_t445_Vˍt_t_^2))*_tpg_,
    -_t445_V_t_ + _tpa_ - _t445_R_t_*_tpb_ + _t445_Rˍt_t_*_tpg_,
    -_t445_Vˍt_t_ - _t445_Rˍt_t_*_tpb_ + _t445_Rˍtt_t_*_tpg_,
    1.0604385073020077 + _t501_V_t_,
    2.025760683884125 + _t501_Vˍt_t_,
    0.5021869624200921 + _t501_Vˍtt_t_,
    -31.00091368206632 + _t501_Vˍttt_t_,
    _t501_Vˍt_t_ - (_t501_R_t_ + _t501_V_t_ - (1//3)*(_t501_V_t_^3))*_tpg_,
    _t501_Vˍtt_t_ - (_t501_Rˍt_t_ + _t501_Vˍt_t_ - (_t501_V_t_^2)*_t501_Vˍt_t_)*_tpg_,
    _t501_Vˍttt_t_ + (-_t501_Rˍtt_t_ - _t501_Vˍtt_t_ + (_t501_V_t_^2)*_t501_Vˍtt_t_ + (2//1)*_t501_V_t_*(_t501_Vˍt_t_^2))*_tpg_,
    -_t501_V_t_ + _tpa_ - _t501_R_t_*_tpb_ + _t501_Rˍt_t_*_tpg_,
    -_t501_Vˍt_t_ - _t501_Rˍt_t_*_tpb_ + _t501_Rˍtt_t_*_tpg_
]

