# Polynomial system saved on 2025-07-28T15:24:15.021
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:24:15.021
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
    1.0536349561981508 + _t445_V_t_,
    2.02392526943672 + _t445_Vˍt_t_,
    0.5871229347470062 + _t445_Vˍtt_t_,
    -23.6993006628485 + _t445_Vˍttt_t_,
    _t445_Vˍt_t_ - (_t445_R_t_ + _t445_V_t_ - (1//3)*(_t445_V_t_^3))*_tpg_,
    _t445_Vˍtt_t_ - (_t445_Rˍt_t_ + _t445_Vˍt_t_ - (_t445_V_t_^2)*_t445_Vˍt_t_)*_tpg_,
    _t445_Vˍttt_t_ + (-_t445_Rˍtt_t_ - _t445_Vˍtt_t_ + (_t445_V_t_^2)*_t445_Vˍtt_t_ + (2//1)*_t445_V_t_*(_t445_Vˍt_t_^2))*_tpg_,
    -_t445_V_t_ + _tpa_ - _t445_R_t_*_tpb_ + _t445_Rˍt_t_*_tpg_,
    -_t445_Vˍt_t_ - _t445_Rˍt_t_*_tpb_ + _t445_Rˍtt_t_*_tpg_,
    1.0604385068393318 + _t501_V_t_,
    2.025759242266276 + _t501_Vˍt_t_,
    0.4997862377266358 + _t501_Vˍtt_t_,
    -33.60366616532632 + _t501_Vˍttt_t_,
    _t501_Vˍt_t_ - (_t501_R_t_ + _t501_V_t_ - (1//3)*(_t501_V_t_^3))*_tpg_,
    _t501_Vˍtt_t_ - (_t501_Rˍt_t_ + _t501_Vˍt_t_ - (_t501_V_t_^2)*_t501_Vˍt_t_)*_tpg_,
    _t501_Vˍttt_t_ + (-_t501_Rˍtt_t_ - _t501_Vˍtt_t_ + (_t501_V_t_^2)*_t501_Vˍtt_t_ + (2//1)*_t501_V_t_*(_t501_Vˍt_t_^2))*_tpg_,
    -_t501_V_t_ + _tpa_ - _t501_R_t_*_tpb_ + _t501_Rˍt_t_*_tpg_,
    -_t501_Vˍt_t_ - _t501_Rˍt_t_*_tpb_ + _t501_Rˍtt_t_*_tpg_
]

