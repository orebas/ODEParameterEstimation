# Polynomial system saved on 2025-07-28T15:22:47.782
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:22:47.782
# num_equations: 12

# Variables
varlist_str = """
_tpg_
_tpa_
_tpb_
_t223_V_t_
_t223_R_t_
_t223_Vˍt_t_
_t223_Vˍtt_t_
_t223_Vˍttt_t_
_t223_Vˍtttt_t_
_t223_Rˍt_t_
_t223_Rˍtt_t_
_t223_Rˍttt_t_
"""
@variables _tpg_ _tpa_ _tpb_ _t223_V_t_ _t223_R_t_ _t223_Vˍt_t_ _t223_Vˍtt_t_ _t223_Vˍttt_t_ _t223_Vˍtttt_t_ _t223_Rˍt_t_ _t223_Rˍtt_t_ _t223_Rˍttt_t_
varlist = [_tpg__tpa__tpb__t223_V_t__t223_R_t__t223_Vˍt_t__t223_Vˍtt_t__t223_Vˍttt_t__t223_Vˍtttt_t__t223_Rˍt_t__t223_Rˍtt_t__t223_Rˍttt_t_]

# Polynomial System
poly_system = [
    1.0267377047743775 + _t223_V_t_,
    2.0140051881326144 + _t223_Vˍt_t_,
    0.9003969132900238 + _t223_Vˍtt_t_,
    -23.038557052612305 + _t223_Vˍttt_t_,
    -77.6875 + _t223_Vˍtttt_t_,
    _t223_Vˍt_t_ - (_t223_R_t_ + _t223_V_t_ - (1//3)*(_t223_V_t_^3))*_tpg_,
    _t223_Vˍtt_t_ - (_t223_Rˍt_t_ + _t223_Vˍt_t_ - (_t223_V_t_^2)*_t223_Vˍt_t_)*_tpg_,
    _t223_Vˍttt_t_ + (-_t223_Rˍtt_t_ - _t223_Vˍtt_t_ + (_t223_V_t_^2)*_t223_Vˍtt_t_ + (2//1)*_t223_V_t_*(_t223_Vˍt_t_^2))*_tpg_,
    _t223_Vˍtttt_t_ + (-_t223_Rˍttt_t_ - _t223_Vˍttt_t_ + (_t223_V_t_^2)*_t223_Vˍttt_t_ + (6//1)*_t223_V_t_*_t223_Vˍt_t_*_t223_Vˍtt_t_ + (2//1)*(_t223_Vˍt_t_^3))*_tpg_,
    -_t223_V_t_ + _tpa_ - _t223_R_t_*_tpb_ + _t223_Rˍt_t_*_tpg_,
    -_t223_Vˍt_t_ - _t223_Rˍt_t_*_tpb_ + _t223_Rˍtt_t_*_tpg_,
    -_t223_Vˍtt_t_ - _t223_Rˍtt_t_*_tpb_ + _t223_Rˍttt_t_*_tpg_
]

