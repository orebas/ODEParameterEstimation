# Polynomial system saved on 2025-07-28T15:23:21.321
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:23:21.321
# num_equations: 18

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
_t223_Rˍt_t_
_t223_Rˍtt_t_
_t390_V_t_
_t390_R_t_
_t390_Vˍt_t_
_t390_Vˍtt_t_
_t390_Vˍttt_t_
_t390_Rˍt_t_
_t390_Rˍtt_t_
"""
@variables _tpg_ _tpa_ _tpb_ _t223_V_t_ _t223_R_t_ _t223_Vˍt_t_ _t223_Vˍtt_t_ _t223_Vˍttt_t_ _t223_Rˍt_t_ _t223_Rˍtt_t_ _t390_V_t_ _t390_R_t_ _t390_Vˍt_t_ _t390_Vˍtt_t_ _t390_Vˍttt_t_ _t390_Rˍt_t_ _t390_Rˍtt_t_
varlist = [_tpg__tpa__tpb__t223_V_t__t223_R_t__t223_Vˍt_t__t223_Vˍtt_t__t223_Vˍttt_t__t223_Rˍt_t__t223_Rˍtt_t__t390_V_t__t390_R_t__t390_Vˍt_t__t390_Vˍtt_t__t390_Vˍttt_t__t390_Rˍt_t__t390_Rˍtt_t_]

# Polynomial System
poly_system = [
    1.0267377045618604 + _t223_V_t_,
    2.014005218468945 + _t223_Vˍt_t_,
    0.9004247070761299 + _t223_Vˍtt_t_,
    -23.044329660063323 + _t223_Vˍttt_t_,
    _t223_Vˍt_t_ - (_t223_R_t_ + _t223_V_t_ - (1//3)*(_t223_V_t_^3))*_tpg_,
    _t223_Vˍtt_t_ - (_t223_Rˍt_t_ + _t223_Vˍt_t_ - (_t223_V_t_^2)*_t223_Vˍt_t_)*_tpg_,
    _t223_Vˍttt_t_ + (-_t223_Rˍtt_t_ - _t223_Vˍtt_t_ + (_t223_V_t_^2)*_t223_Vˍtt_t_ + (2//1)*_t223_V_t_*(_t223_Vˍt_t_^2))*_tpg_,
    -_t223_V_t_ + _tpa_ - _t223_R_t_*_tpb_ + _t223_Rˍt_t_*_tpg_,
    -_t223_Vˍt_t_ - _t223_Rˍt_t_*_tpb_ + _t223_Rˍtt_t_*_tpg_,
    1.0469593419748435 + _t390_V_t_,
    2.0218581868070293 + _t390_Vˍt_t_,
    0.6659188510339389 + _t390_Vˍtt_t_,
    -23.90105874918976 + _t390_Vˍttt_t_,
    _t390_Vˍt_t_ - (_t390_R_t_ + _t390_V_t_ - (1//3)*(_t390_V_t_^3))*_tpg_,
    _t390_Vˍtt_t_ - (_t390_Rˍt_t_ + _t390_Vˍt_t_ - (_t390_V_t_^2)*_t390_Vˍt_t_)*_tpg_,
    _t390_Vˍttt_t_ + (-_t390_Rˍtt_t_ - _t390_Vˍtt_t_ + (_t390_V_t_^2)*_t390_Vˍtt_t_ + (2//1)*_t390_V_t_*(_t390_Vˍt_t_^2))*_tpg_,
    -_t390_V_t_ + _tpa_ - _t390_R_t_*_tpb_ + _t390_Rˍt_t_*_tpg_,
    -_t390_Vˍt_t_ - _t390_Rˍt_t_*_tpb_ + _t390_Rˍtt_t_*_tpg_
]

