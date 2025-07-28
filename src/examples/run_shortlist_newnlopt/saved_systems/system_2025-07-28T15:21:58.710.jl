# Polynomial system saved on 2025-07-28T15:21:58.710
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:21:58.710
# num_equations: 12

# Variables
varlist_str = """
_tpg_
_tpa_
_tpb_
_t278_V_t_
_t278_R_t_
_t278_Vˍt_t_
_t278_Vˍtt_t_
_t278_Vˍttt_t_
_t278_Vˍtttt_t_
_t278_Rˍt_t_
_t278_Rˍtt_t_
_t278_Rˍttt_t_
"""
@variables _tpg_ _tpa_ _tpb_ _t278_V_t_ _t278_R_t_ _t278_Vˍt_t_ _t278_Vˍtt_t_ _t278_Vˍttt_t_ _t278_Vˍtttt_t_ _t278_Rˍt_t_ _t278_Rˍtt_t_ _t278_Rˍttt_t_
varlist = [_tpg__tpa__tpb__t278_V_t__t278_R_t__t278_Vˍt_t__t278_Vˍtt_t__t278_Vˍttt_t__t278_Vˍtttt_t__t278_Rˍt_t__t278_Rˍtt_t__t278_Rˍttt_t_]

# Polynomial System
poly_system = [
    1.0333886861429507 + _t278_V_t_,
    2.0168506035336375 + _t278_Vˍt_t_,
    0.8239832426150006 + _t278_Vˍtt_t_,
    -23.289105966105655 + _t278_Vˍttt_t_,
    -104.50223714831803 + _t278_Vˍtttt_t_,
    _t278_Vˍt_t_ - (_t278_R_t_ + _t278_V_t_ - (1//3)*(_t278_V_t_^3))*_tpg_,
    _t278_Vˍtt_t_ - (_t278_Rˍt_t_ + _t278_Vˍt_t_ - (_t278_V_t_^2)*_t278_Vˍt_t_)*_tpg_,
    _t278_Vˍttt_t_ + (-_t278_Rˍtt_t_ - _t278_Vˍtt_t_ + (_t278_V_t_^2)*_t278_Vˍtt_t_ + (2//1)*_t278_V_t_*(_t278_Vˍt_t_^2))*_tpg_,
    _t278_Vˍtttt_t_ + (-_t278_Rˍttt_t_ - _t278_Vˍttt_t_ + (_t278_V_t_^2)*_t278_Vˍttt_t_ + (6//1)*_t278_V_t_*_t278_Vˍt_t_*_t278_Vˍtt_t_ + (2//1)*(_t278_Vˍt_t_^3))*_tpg_,
    -_t278_V_t_ + _tpa_ - _t278_R_t_*_tpb_ + _t278_Rˍt_t_*_tpg_,
    -_t278_Vˍt_t_ - _t278_Rˍt_t_*_tpb_ + _t278_Rˍtt_t_*_tpg_,
    -_t278_Vˍtt_t_ - _t278_Rˍtt_t_*_tpb_ + _t278_Rˍttt_t_*_tpg_
]

