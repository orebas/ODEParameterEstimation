# Polynomial system saved on 2025-07-28T15:21:08.115
using Symbolics
using StaticArrays

# Metadata
# num_variables: 12
# timestamp: 2025-07-28T15:21:08.114
# num_equations: 12

# Variables
varlist_str = """
_tpg_
_tpa_
_tpb_
_t56_V_t_
_t56_R_t_
_t56_Vˍt_t_
_t56_Vˍtt_t_
_t56_Vˍttt_t_
_t56_Vˍtttt_t_
_t56_Rˍt_t_
_t56_Rˍtt_t_
_t56_Rˍttt_t_
"""
@variables _tpg_ _tpa_ _tpb_ _t56_V_t_ _t56_R_t_ _t56_Vˍt_t_ _t56_Vˍtt_t_ _t56_Vˍttt_t_ _t56_Vˍtttt_t_ _t56_Rˍt_t_ _t56_Rˍtt_t_ _t56_Rˍttt_t_
varlist = [_tpg__tpa__tpb__t56_V_t__t56_R_t__t56_Vˍt_t__t56_Vˍtt_t__t56_Vˍttt_t__t56_Vˍtttt_t__t56_Rˍt_t__t56_Rˍtt_t__t56_Rˍttt_t_]

# Polynomial System
poly_system = [
    1.0066064023306966 + _t56_V_t_,
    2.0038399843461385 + _t56_Vˍt_t_,
    1.1271215854578096 + _t56_Vˍtt_t_,
    -21.948132639281745 + _t56_Vˍttt_t_,
    -229.5085083390172 + _t56_Vˍtttt_t_,
    _t56_Vˍt_t_ - (_t56_R_t_ + _t56_V_t_ - (1//3)*(_t56_V_t_^3))*_tpg_,
    _t56_Vˍtt_t_ - (_t56_Rˍt_t_ + _t56_Vˍt_t_ - (_t56_V_t_^2)*_t56_Vˍt_t_)*_tpg_,
    _t56_Vˍttt_t_ + (-_t56_Rˍtt_t_ - _t56_Vˍtt_t_ + (_t56_V_t_^2)*_t56_Vˍtt_t_ + (2//1)*_t56_V_t_*(_t56_Vˍt_t_^2))*_tpg_,
    _t56_Vˍtttt_t_ + (-_t56_Rˍttt_t_ - _t56_Vˍttt_t_ + (_t56_V_t_^2)*_t56_Vˍttt_t_ + (6//1)*_t56_V_t_*_t56_Vˍt_t_*_t56_Vˍtt_t_ + (2//1)*(_t56_Vˍt_t_^3))*_tpg_,
    -_t56_V_t_ + _tpa_ - _t56_R_t_*_tpb_ + _t56_Rˍt_t_*_tpg_,
    -_t56_Vˍt_t_ - _t56_Rˍt_t_*_tpb_ + _t56_Rˍtt_t_*_tpg_,
    -_t56_Vˍtt_t_ - _t56_Rˍtt_t_*_tpb_ + _t56_Rˍttt_t_*_tpg_
]

