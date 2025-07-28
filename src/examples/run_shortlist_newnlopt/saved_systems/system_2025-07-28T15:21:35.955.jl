# Polynomial system saved on 2025-07-28T15:21:35.956
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:21:35.955
# num_equations: 12

# Variables
varlist_str = """
_tpg_
_tpa_
_tpb_
_t111_V_t_
_t111_R_t_
_t111_Vˍt_t_
_t111_Vˍtt_t_
_t111_Vˍttt_t_
_t111_Vˍtttt_t_
_t111_Rˍt_t_
_t111_Rˍtt_t_
_t111_Rˍttt_t_
"""
@variables _tpg_ _tpa_ _tpb_ _t111_V_t_ _t111_R_t_ _t111_Vˍt_t_ _t111_Vˍtt_t_ _t111_Vˍttt_t_ _t111_Vˍtttt_t_ _t111_Rˍt_t_ _t111_Rˍtt_t_ _t111_Rˍttt_t_
varlist = [_tpg__tpa__tpb__t111_V_t__t111_R_t__t111_Vˍt_t__t111_Vˍtt_t__t111_Vˍttt_t__t111_Vˍtttt_t__t111_Rˍt_t__t111_Rˍtt_t__t111_Rˍttt_t_]

# Polynomial System
poly_system = [
    1.0132250787467387 + _t111_V_t_,
    2.007438385385783 + _t111_Vˍt_t_,
    1.0533827853971738 + _t111_Vˍtt_t_,
    -22.538480936504396 + _t111_Vˍttt_t_,
    -24.835360416218773 + _t111_Vˍtttt_t_,
    _t111_Vˍt_t_ - (_t111_R_t_ + _t111_V_t_ - (1//3)*(_t111_V_t_^3))*_tpg_,
    _t111_Vˍtt_t_ - (_t111_Rˍt_t_ + _t111_Vˍt_t_ - (_t111_V_t_^2)*_t111_Vˍt_t_)*_tpg_,
    _t111_Vˍttt_t_ + (-_t111_Rˍtt_t_ - _t111_Vˍtt_t_ + (_t111_V_t_^2)*_t111_Vˍtt_t_ + (2//1)*_t111_V_t_*(_t111_Vˍt_t_^2))*_tpg_,
    _t111_Vˍtttt_t_ + (-_t111_Rˍttt_t_ - _t111_Vˍttt_t_ + (_t111_V_t_^2)*_t111_Vˍttt_t_ + (6//1)*_t111_V_t_*_t111_Vˍt_t_*_t111_Vˍtt_t_ + (2//1)*(_t111_Vˍt_t_^3))*_tpg_,
    -_t111_V_t_ + _tpa_ - _t111_R_t_*_tpb_ + _t111_Rˍt_t_*_tpg_,
    -_t111_Vˍt_t_ - _t111_Rˍt_t_*_tpb_ + _t111_Rˍtt_t_*_tpg_,
    -_t111_Vˍtt_t_ - _t111_Rˍtt_t_*_tpb_ + _t111_Rˍttt_t_*_tpg_
]

