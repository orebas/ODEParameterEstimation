# Polynomial system saved on 2025-07-28T15:23:05.852
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:23:05.852
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
    1.0199758751653398 + _t167_V_t_,
    2.0108502495797187 + _t167_Vˍt_t_,
    0.9773430630673526 + _t167_Vˍtt_t_,
    -22.742457274568977 + _t167_Vˍttt_t_,
    _t167_Vˍt_t_ - (_t167_R_t_ + _t167_V_t_ - (1//3)*(_t167_V_t_^3))*_tpg_,
    _t167_Vˍtt_t_ - (_t167_Rˍt_t_ + _t167_Vˍt_t_ - (_t167_V_t_^2)*_t167_Vˍt_t_)*_tpg_,
    _t167_Vˍttt_t_ + (-_t167_Rˍtt_t_ - _t167_Vˍtt_t_ + (_t167_V_t_^2)*_t167_Vˍtt_t_ + (2//1)*_t167_V_t_*(_t167_Vˍt_t_^2))*_tpg_,
    -_t167_V_t_ + _tpa_ - _t167_R_t_*_tpb_ + _t167_Rˍt_t_*_tpg_,
    -_t167_Vˍt_t_ - _t167_Rˍt_t_*_tpb_ + _t167_Rˍtt_t_*_tpg_,
    1.0401698075315788 + _t334_V_t_,
    2.0194871014394526 + _t334_Vˍt_t_,
    0.745290190624408 + _t334_Vˍtt_t_,
    -23.50846825408983 + _t334_Vˍttt_t_,
    _t334_Vˍt_t_ - (_t334_R_t_ + _t334_V_t_ - (1//3)*(_t334_V_t_^3))*_tpg_,
    _t334_Vˍtt_t_ - (_t334_Rˍt_t_ + _t334_Vˍt_t_ - (_t334_V_t_^2)*_t334_Vˍt_t_)*_tpg_,
    _t334_Vˍttt_t_ + (-_t334_Rˍtt_t_ - _t334_Vˍtt_t_ + (_t334_V_t_^2)*_t334_Vˍtt_t_ + (2//1)*_t334_V_t_*(_t334_Vˍt_t_^2))*_tpg_,
    -_t334_V_t_ + _tpa_ - _t334_R_t_*_tpb_ + _t334_Rˍt_t_*_tpg_,
    -_t334_Vˍt_t_ - _t334_Rˍt_t_*_tpb_ + _t334_Rˍtt_t_*_tpg_
]

