# Polynomial system saved on 2025-07-28T15:24:15.819
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:24:15.819
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
    1.0536349563028853 + _t445_V_t_,
    2.0239252768819394 + _t445_Vˍt_t_,
    0.5870248213077027 + _t445_Vˍtt_t_,
    -23.798079096949813 + _t445_Vˍttt_t_,
    _t445_Vˍt_t_ - (_t445_R_t_ + _t445_V_t_ - (1//3)*(_t445_V_t_^3))*_tpg_,
    _t445_Vˍtt_t_ - (_t445_Rˍt_t_ + _t445_Vˍt_t_ - (_t445_V_t_^2)*_t445_Vˍt_t_)*_tpg_,
    _t445_Vˍttt_t_ + (-_t445_Rˍtt_t_ - _t445_Vˍtt_t_ + (_t445_V_t_^2)*_t445_Vˍtt_t_ + (2//1)*_t445_V_t_*(_t445_Vˍt_t_^2))*_tpg_,
    -_t445_V_t_ + _tpa_ - _t445_R_t_*_tpb_ + _t445_Rˍt_t_*_tpg_,
    -_t445_Vˍt_t_ - _t445_Rˍt_t_*_tpb_ + _t445_Rˍtt_t_*_tpg_,
    1.0604385071824032 + _t501_V_t_,
    2.0257606031216255 + _t501_Vˍt_t_,
    0.5023637873577308 + _t501_Vˍtt_t_,
    -30.379380517226018 + _t501_Vˍttt_t_,
    _t501_Vˍt_t_ - (_t501_R_t_ + _t501_V_t_ - (1//3)*(_t501_V_t_^3))*_tpg_,
    _t501_Vˍtt_t_ - (_t501_Rˍt_t_ + _t501_Vˍt_t_ - (_t501_V_t_^2)*_t501_Vˍt_t_)*_tpg_,
    _t501_Vˍttt_t_ + (-_t501_Rˍtt_t_ - _t501_Vˍtt_t_ + (_t501_V_t_^2)*_t501_Vˍtt_t_ + (2//1)*_t501_V_t_*(_t501_Vˍt_t_^2))*_tpg_,
    -_t501_V_t_ + _tpa_ - _t501_R_t_*_tpb_ + _t501_Rˍt_t_*_tpg_,
    -_t501_Vˍt_t_ - _t501_Rˍt_t_*_tpb_ + _t501_Rˍtt_t_*_tpg_
]

