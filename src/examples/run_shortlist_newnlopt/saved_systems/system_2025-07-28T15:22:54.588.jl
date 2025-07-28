# Polynomial system saved on 2025-07-28T15:22:54.588
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:22:54.588
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
    1.006606402427083 + _t56_V_t_,
    2.0038399359501726 + _t56_Vˍt_t_,
    1.1269092146370325 + _t56_Vˍtt_t_,
    -21.789175480917695 + _t56_Vˍttt_t_,
    _t56_Vˍt_t_ - (_t56_R_t_ + _t56_V_t_ - (1//3)*(_t56_V_t_^3))*_tpg_,
    _t56_Vˍtt_t_ - (_t56_Rˍt_t_ + _t56_Vˍt_t_ - (_t56_V_t_^2)*_t56_Vˍt_t_)*_tpg_,
    _t56_Vˍttt_t_ + (-_t56_Rˍtt_t_ - _t56_Vˍtt_t_ + (_t56_V_t_^2)*_t56_Vˍtt_t_ + (2//1)*_t56_V_t_*(_t56_Vˍt_t_^2))*_tpg_,
    -_t56_V_t_ + _tpa_ - _t56_R_t_*_tpb_ + _t56_Rˍt_t_*_tpg_,
    -_t56_Vˍt_t_ - _t56_Rˍt_t_*_tpb_ + _t56_Rˍtt_t_*_tpg_,
    1.0267377045210824 + _t223_V_t_,
    2.0140052188601554 + _t223_Vˍt_t_,
    0.9005135044958159 + _t223_Vˍtt_t_,
    -23.060770788475434 + _t223_Vˍttt_t_,
    _t223_Vˍt_t_ - (_t223_R_t_ + _t223_V_t_ - (1//3)*(_t223_V_t_^3))*_tpg_,
    _t223_Vˍtt_t_ - (_t223_Rˍt_t_ + _t223_Vˍt_t_ - (_t223_V_t_^2)*_t223_Vˍt_t_)*_tpg_,
    _t223_Vˍttt_t_ + (-_t223_Rˍtt_t_ - _t223_Vˍtt_t_ + (_t223_V_t_^2)*_t223_Vˍtt_t_ + (2//1)*_t223_V_t_*(_t223_Vˍt_t_^2))*_tpg_,
    -_t223_V_t_ + _tpa_ - _t223_R_t_*_tpb_ + _t223_Rˍt_t_*_tpg_,
    -_t223_Vˍt_t_ - _t223_Rˍt_t_*_tpb_ + _t223_Rˍtt_t_*_tpg_
]

