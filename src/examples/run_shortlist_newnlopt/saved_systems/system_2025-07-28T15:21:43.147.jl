# Polynomial system saved on 2025-07-28T15:21:43.147
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:21:43.147
# num_equations: 12

# Variables
varlist_str = """
_tpg_
_tpa_
_tpb_
_t167_V_t_
_t167_R_t_
_t167_Vˍt_t_
_t167_Vˍtt_t_
_t167_Vˍttt_t_
_t167_Vˍtttt_t_
_t167_Rˍt_t_
_t167_Rˍtt_t_
_t167_Rˍttt_t_
"""
@variables _tpg_ _tpa_ _tpb_ _t167_V_t_ _t167_R_t_ _t167_Vˍt_t_ _t167_Vˍtt_t_ _t167_Vˍttt_t_ _t167_Vˍtttt_t_ _t167_Rˍt_t_ _t167_Rˍtt_t_ _t167_Rˍttt_t_
varlist = [_tpg__tpa__tpb__t167_V_t__t167_R_t__t167_Vˍt_t__t167_Vˍtt_t__t167_Vˍttt_t__t167_Vˍtttt_t__t167_Rˍt_t__t167_Rˍtt_t__t167_Rˍttt_t_]

# Polynomial System
poly_system = [
    1.0199758764720064 + _t167_V_t_,
    2.0108502167832607 + _t167_Vˍt_t_,
    0.9773668330009454 + _t167_Vˍtt_t_,
    -22.73265808215 + _t167_Vˍttt_t_,
    -87.58420544685717 + _t167_Vˍtttt_t_,
    _t167_Vˍt_t_ - (_t167_R_t_ + _t167_V_t_ - (1//3)*(_t167_V_t_^3))*_tpg_,
    _t167_Vˍtt_t_ - (_t167_Rˍt_t_ + _t167_Vˍt_t_ - (_t167_V_t_^2)*_t167_Vˍt_t_)*_tpg_,
    _t167_Vˍttt_t_ + (-_t167_Rˍtt_t_ - _t167_Vˍtt_t_ + (_t167_V_t_^2)*_t167_Vˍtt_t_ + (2//1)*_t167_V_t_*(_t167_Vˍt_t_^2))*_tpg_,
    _t167_Vˍtttt_t_ + (-_t167_Rˍttt_t_ - _t167_Vˍttt_t_ + (_t167_V_t_^2)*_t167_Vˍttt_t_ + (6//1)*_t167_V_t_*_t167_Vˍt_t_*_t167_Vˍtt_t_ + (2//1)*(_t167_Vˍt_t_^3))*_tpg_,
    -_t167_V_t_ + _tpa_ - _t167_R_t_*_tpb_ + _t167_Rˍt_t_*_tpg_,
    -_t167_Vˍt_t_ - _t167_Rˍt_t_*_tpb_ + _t167_Rˍtt_t_*_tpg_,
    -_t167_Vˍtt_t_ - _t167_Rˍtt_t_*_tpb_ + _t167_Rˍttt_t_*_tpg_
]

