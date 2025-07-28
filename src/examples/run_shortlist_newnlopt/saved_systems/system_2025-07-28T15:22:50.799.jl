# Polynomial system saved on 2025-07-28T15:22:50.799
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:22:50.799
# num_equations: 18

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
_t56_Rˍt_t_
_t56_Rˍtt_t_
_t223_V_t_
_t223_R_t_
_t223_Vˍt_t_
_t223_Vˍtt_t_
_t223_Vˍttt_t_
_t223_Rˍt_t_
_t223_Rˍtt_t_
"""
@variables _tpg_ _tpa_ _tpb_ _t56_V_t_ _t56_R_t_ _t56_Vˍt_t_ _t56_Vˍtt_t_ _t56_Vˍttt_t_ _t56_Rˍt_t_ _t56_Rˍtt_t_ _t223_V_t_ _t223_R_t_ _t223_Vˍt_t_ _t223_Vˍtt_t_ _t223_Vˍttt_t_ _t223_Rˍt_t_ _t223_Rˍtt_t_
varlist = [_tpg__tpa__tpb__t56_V_t__t56_R_t__t56_Vˍt_t__t56_Vˍtt_t__t56_Vˍttt_t__t56_Rˍt_t__t56_Rˍtt_t__t223_V_t__t223_R_t__t223_Vˍt_t__t223_Vˍtt_t__t223_Vˍttt_t__t223_Rˍt_t__t223_Rˍtt_t_]

# Polynomial System
poly_system = [
    1.0066064024207602 + _t56_V_t_,
    2.003839977679264 + _t56_Vˍt_t_,
    1.1270227636671826 + _t56_Vˍtt_t_,
    -21.910339803151224 + _t56_Vˍttt_t_,
    _t56_Vˍt_t_ - (_t56_R_t_ + _t56_V_t_ - (1//3)*(_t56_V_t_^3))*_tpg_,
    _t56_Vˍtt_t_ - (_t56_Rˍt_t_ + _t56_Vˍt_t_ - (_t56_V_t_^2)*_t56_Vˍt_t_)*_tpg_,
    _t56_Vˍttt_t_ + (-_t56_Rˍtt_t_ - _t56_Vˍtt_t_ + (_t56_V_t_^2)*_t56_Vˍtt_t_ + (2//1)*_t56_V_t_*(_t56_Vˍt_t_^2))*_tpg_,
    -_t56_V_t_ + _tpa_ - _t56_R_t_*_tpb_ + _t56_Rˍt_t_*_tpg_,
    -_t56_Vˍt_t_ - _t56_Rˍt_t_*_tpb_ + _t56_Rˍtt_t_*_tpg_,
    1.0267377047402755 + _t223_V_t_,
    2.0140052150784564 + _t223_Vˍt_t_,
    0.9004589272129994 + _t223_Vˍtt_t_,
    -23.052291971269565 + _t223_Vˍttt_t_,
    _t223_Vˍt_t_ - (_t223_R_t_ + _t223_V_t_ - (1//3)*(_t223_V_t_^3))*_tpg_,
    _t223_Vˍtt_t_ - (_t223_Rˍt_t_ + _t223_Vˍt_t_ - (_t223_V_t_^2)*_t223_Vˍt_t_)*_tpg_,
    _t223_Vˍttt_t_ + (-_t223_Rˍtt_t_ - _t223_Vˍtt_t_ + (_t223_V_t_^2)*_t223_Vˍtt_t_ + (2//1)*_t223_V_t_*(_t223_Vˍt_t_^2))*_tpg_,
    -_t223_V_t_ + _tpa_ - _t223_R_t_*_tpb_ + _t223_Rˍt_t_*_tpg_,
    -_t223_Vˍt_t_ - _t223_Rˍt_t_*_tpb_ + _t223_Rˍtt_t_*_tpg_
]

