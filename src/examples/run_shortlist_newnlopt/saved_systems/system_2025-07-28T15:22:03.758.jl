# Polynomial system saved on 2025-07-28T15:22:03.759
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:22:03.758
# num_equations: 12

# Variables
varlist_str = """
_tpg_
_tpa_
_tpb_
_t334_V_t_
_t334_R_t_
_t334_Vˍt_t_
_t334_Vˍtt_t_
_t334_Vˍttt_t_
_t334_Vˍtttt_t_
_t334_Rˍt_t_
_t334_Rˍtt_t_
_t334_Rˍttt_t_
"""
@variables _tpg_ _tpa_ _tpb_ _t334_V_t_ _t334_R_t_ _t334_Vˍt_t_ _t334_Vˍtt_t_ _t334_Vˍttt_t_ _t334_Vˍtttt_t_ _t334_Rˍt_t_ _t334_Rˍtt_t_ _t334_Rˍttt_t_
varlist = [_tpg__tpa__tpb__t334_V_t__t334_R_t__t334_Vˍt_t__t334_Vˍtt_t__t334_Vˍttt_t__t334_Vˍtttt_t__t334_Rˍt_t__t334_Rˍtt_t__t334_Rˍttt_t_]

# Polynomial System
poly_system = [
    1.040169807758475 + _t334_V_t_,
    2.019487141147291 + _t334_Vˍt_t_,
    0.7451575797453835 + _t334_Vˍtt_t_,
    -23.557203025456886 + _t334_Vˍttt_t_,
    46.268135273548125 + _t334_Vˍtttt_t_,
    _t334_Vˍt_t_ - (_t334_R_t_ + _t334_V_t_ - (1//3)*(_t334_V_t_^3))*_tpg_,
    _t334_Vˍtt_t_ - (_t334_Rˍt_t_ + _t334_Vˍt_t_ - (_t334_V_t_^2)*_t334_Vˍt_t_)*_tpg_,
    _t334_Vˍttt_t_ + (-_t334_Rˍtt_t_ - _t334_Vˍtt_t_ + (_t334_V_t_^2)*_t334_Vˍtt_t_ + (2//1)*_t334_V_t_*(_t334_Vˍt_t_^2))*_tpg_,
    _t334_Vˍtttt_t_ + (-_t334_Rˍttt_t_ - _t334_Vˍttt_t_ + (_t334_V_t_^2)*_t334_Vˍttt_t_ + (6//1)*_t334_V_t_*_t334_Vˍt_t_*_t334_Vˍtt_t_ + (2//1)*(_t334_Vˍt_t_^3))*_tpg_,
    -_t334_V_t_ + _tpa_ - _t334_R_t_*_tpb_ + _t334_Rˍt_t_*_tpg_,
    -_t334_Vˍt_t_ - _t334_Rˍt_t_*_tpb_ + _t334_Rˍtt_t_*_tpg_,
    -_t334_Vˍtt_t_ - _t334_Rˍtt_t_*_tpb_ + _t334_Rˍttt_t_*_tpg_
]

