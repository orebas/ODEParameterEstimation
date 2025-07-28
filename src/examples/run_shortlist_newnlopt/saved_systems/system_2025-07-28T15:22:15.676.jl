# Polynomial system saved on 2025-07-28T15:22:15.676
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:22:15.676
# num_equations: 12

# Variables
varlist_str = """
_tpg_
_tpa_
_tpb_
_t390_V_t_
_t390_R_t_
_t390_Vˍt_t_
_t390_Vˍtt_t_
_t390_Vˍttt_t_
_t390_Vˍtttt_t_
_t390_Rˍt_t_
_t390_Rˍtt_t_
_t390_Rˍttt_t_
"""
@variables _tpg_ _tpa_ _tpb_ _t390_V_t_ _t390_R_t_ _t390_Vˍt_t_ _t390_Vˍtt_t_ _t390_Vˍttt_t_ _t390_Vˍtttt_t_ _t390_Rˍt_t_ _t390_Rˍtt_t_ _t390_Rˍttt_t_
varlist = [_tpg__tpa__tpb__t390_V_t__t390_R_t__t390_Vˍt_t__t390_Vˍtt_t__t390_Vˍttt_t__t390_Vˍtttt_t__t390_Rˍt_t__t390_Rˍtt_t__t390_Rˍttt_t_]

# Polynomial System
poly_system = [
    1.046959342278738 + _t390_V_t_,
    2.021858179113228 + _t390_Vˍt_t_,
    0.6657591663205235 + _t390_Vˍtt_t_,
    -23.928388700051087 + _t390_Vˍttt_t_,
    -68.46301873931947 + _t390_Vˍtttt_t_,
    _t390_Vˍt_t_ - (_t390_R_t_ + _t390_V_t_ - (1//3)*(_t390_V_t_^3))*_tpg_,
    _t390_Vˍtt_t_ - (_t390_Rˍt_t_ + _t390_Vˍt_t_ - (_t390_V_t_^2)*_t390_Vˍt_t_)*_tpg_,
    _t390_Vˍttt_t_ + (-_t390_Rˍtt_t_ - _t390_Vˍtt_t_ + (_t390_V_t_^2)*_t390_Vˍtt_t_ + (2//1)*_t390_V_t_*(_t390_Vˍt_t_^2))*_tpg_,
    _t390_Vˍtttt_t_ + (-_t390_Rˍttt_t_ - _t390_Vˍttt_t_ + (_t390_V_t_^2)*_t390_Vˍttt_t_ + (6//1)*_t390_V_t_*_t390_Vˍt_t_*_t390_Vˍtt_t_ + (2//1)*(_t390_Vˍt_t_^3))*_tpg_,
    -_t390_V_t_ + _tpa_ - _t390_R_t_*_tpb_ + _t390_Rˍt_t_*_tpg_,
    -_t390_Vˍt_t_ - _t390_Rˍt_t_*_tpb_ + _t390_Rˍtt_t_*_tpg_,
    -_t390_Vˍtt_t_ - _t390_Rˍtt_t_*_tpb_ + _t390_Rˍttt_t_*_tpg_
]

