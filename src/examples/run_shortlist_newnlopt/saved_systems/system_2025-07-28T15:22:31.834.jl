# Polynomial system saved on 2025-07-28T15:22:31.834
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:22:31.834
# num_equations: 12

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
_t445_Vˍtttt_t_
_t445_Rˍt_t_
_t445_Rˍtt_t_
_t445_Rˍttt_t_
"""
@variables _tpg_ _tpa_ _tpb_ _t445_V_t_ _t445_R_t_ _t445_Vˍt_t_ _t445_Vˍtt_t_ _t445_Vˍttt_t_ _t445_Vˍtttt_t_ _t445_Rˍt_t_ _t445_Rˍtt_t_ _t445_Rˍttt_t_
varlist = [_tpg__tpa__tpb__t445_V_t__t445_R_t__t445_Vˍt_t__t445_Vˍtt_t__t445_Vˍttt_t__t445_Vˍtttt_t__t445_Rˍt_t__t445_Rˍtt_t__t445_Rˍttt_t_]

# Polynomial System
poly_system = [
    1.0536349562874485 + _t445_V_t_,
    2.0239251881627944 + _t445_Vˍt_t_,
    0.5870906072200291 + _t445_Vˍtt_t_,
    -23.5846988244184 + _t445_Vˍttt_t_,
    189.35100118279846 + _t445_Vˍtttt_t_,
    _t445_Vˍt_t_ - (_t445_R_t_ + _t445_V_t_ - (1//3)*(_t445_V_t_^3))*_tpg_,
    _t445_Vˍtt_t_ - (_t445_Rˍt_t_ + _t445_Vˍt_t_ - (_t445_V_t_^2)*_t445_Vˍt_t_)*_tpg_,
    _t445_Vˍttt_t_ + (-_t445_Rˍtt_t_ - _t445_Vˍtt_t_ + (_t445_V_t_^2)*_t445_Vˍtt_t_ + (2//1)*_t445_V_t_*(_t445_Vˍt_t_^2))*_tpg_,
    _t445_Vˍtttt_t_ + (-_t445_Rˍttt_t_ - _t445_Vˍttt_t_ + (_t445_V_t_^2)*_t445_Vˍttt_t_ + (6//1)*_t445_V_t_*_t445_Vˍt_t_*_t445_Vˍtt_t_ + (2//1)*(_t445_Vˍt_t_^3))*_tpg_,
    -_t445_V_t_ + _tpa_ - _t445_R_t_*_tpb_ + _t445_Rˍt_t_*_tpg_,
    -_t445_Vˍt_t_ - _t445_Rˍt_t_*_tpb_ + _t445_Rˍtt_t_*_tpg_,
    -_t445_Vˍtt_t_ - _t445_Rˍtt_t_*_tpb_ + _t445_Rˍttt_t_*_tpg_
]

