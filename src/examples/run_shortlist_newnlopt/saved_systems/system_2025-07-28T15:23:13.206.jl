# Polynomial system saved on 2025-07-28T15:23:13.216
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:23:13.206
# num_equations: 18

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
_t167_Rˍt_t_
_t167_Rˍtt_t_
_t334_V_t_
_t334_R_t_
_t334_Vˍt_t_
_t334_Vˍtt_t_
_t334_Vˍttt_t_
_t334_Rˍt_t_
_t334_Rˍtt_t_
"""
@variables _tpg_ _tpa_ _tpb_ _t167_V_t_ _t167_R_t_ _t167_Vˍt_t_ _t167_Vˍtt_t_ _t167_Vˍttt_t_ _t167_Rˍt_t_ _t167_Rˍtt_t_ _t334_V_t_ _t334_R_t_ _t334_Vˍt_t_ _t334_Vˍtt_t_ _t334_Vˍttt_t_ _t334_Rˍt_t_ _t334_Rˍtt_t_
varlist = [_tpg__tpa__tpb__t167_V_t__t167_R_t__t167_Vˍt_t__t167_Vˍtt_t__t167_Vˍttt_t__t167_Rˍt_t__t167_Rˍtt_t__t334_V_t__t334_R_t__t334_Vˍt_t__t334_Vˍtt_t__t334_Vˍttt_t__t334_Rˍt_t__t334_Rˍtt_t_]

# Polynomial System
poly_system = [
    1.0199758749273855 + _t167_V_t_,
    2.010850152429178 + _t167_Vˍt_t_,
    0.9773489885983075 + _t167_Vˍtt_t_,
    -22.666897841560502 + _t167_Vˍttt_t_,
    _t167_Vˍt_t_ - (_t167_R_t_ + _t167_V_t_ - (1//3)*(_t167_V_t_^3))*_tpg_,
    _t167_Vˍtt_t_ - (_t167_Rˍt_t_ + _t167_Vˍt_t_ - (_t167_V_t_^2)*_t167_Vˍt_t_)*_tpg_,
    _t167_Vˍttt_t_ + (-_t167_Rˍtt_t_ - _t167_Vˍtt_t_ + (_t167_V_t_^2)*_t167_Vˍtt_t_ + (2//1)*_t167_V_t_*(_t167_Vˍt_t_^2))*_tpg_,
    -_t167_V_t_ + _tpa_ - _t167_R_t_*_tpb_ + _t167_Rˍt_t_*_tpg_,
    -_t167_Vˍt_t_ - _t167_Rˍt_t_*_tpb_ + _t167_Rˍtt_t_*_tpg_,
    1.0401698069783296 + _t334_V_t_,
    2.0194870288699547 + _t334_Vˍt_t_,
    0.7453720464097677 + _t334_Vˍtt_t_,
    -23.4634147230014 + _t334_Vˍttt_t_,
    _t334_Vˍt_t_ - (_t334_R_t_ + _t334_V_t_ - (1//3)*(_t334_V_t_^3))*_tpg_,
    _t334_Vˍtt_t_ - (_t334_Rˍt_t_ + _t334_Vˍt_t_ - (_t334_V_t_^2)*_t334_Vˍt_t_)*_tpg_,
    _t334_Vˍttt_t_ + (-_t334_Rˍtt_t_ - _t334_Vˍtt_t_ + (_t334_V_t_^2)*_t334_Vˍtt_t_ + (2//1)*_t334_V_t_*(_t334_Vˍt_t_^2))*_tpg_,
    -_t334_V_t_ + _tpa_ - _t334_R_t_*_tpb_ + _t334_Rˍt_t_*_tpg_,
    -_t334_Vˍt_t_ - _t334_Rˍt_t_*_tpb_ + _t334_Rˍtt_t_*_tpg_
]

