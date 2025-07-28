# Polynomial system saved on 2025-07-28T15:23:18.741
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:23:18.740
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
    1.019975875288043 + _t167_V_t_,
    2.01085027487798 + _t167_Vˍt_t_,
    0.977331906794812 + _t167_Vˍtt_t_,
    -22.743820914503875 + _t167_Vˍttt_t_,
    _t167_Vˍt_t_ - (_t167_R_t_ + _t167_V_t_ - (1//3)*(_t167_V_t_^3))*_tpg_,
    _t167_Vˍtt_t_ - (_t167_Rˍt_t_ + _t167_Vˍt_t_ - (_t167_V_t_^2)*_t167_Vˍt_t_)*_tpg_,
    _t167_Vˍttt_t_ + (-_t167_Rˍtt_t_ - _t167_Vˍtt_t_ + (_t167_V_t_^2)*_t167_Vˍtt_t_ + (2//1)*_t167_V_t_*(_t167_Vˍt_t_^2))*_tpg_,
    -_t167_V_t_ + _tpa_ - _t167_R_t_*_tpb_ + _t167_Rˍt_t_*_tpg_,
    -_t167_Vˍt_t_ - _t167_Rˍt_t_*_tpb_ + _t167_Rˍtt_t_*_tpg_,
    1.0401698075079562 + _t334_V_t_,
    2.019487100722234 + _t334_Vˍt_t_,
    0.745275961004298 + _t334_Vˍtt_t_,
    -23.500427425425528 + _t334_Vˍttt_t_,
    _t334_Vˍt_t_ - (_t334_R_t_ + _t334_V_t_ - (1//3)*(_t334_V_t_^3))*_tpg_,
    _t334_Vˍtt_t_ - (_t334_Rˍt_t_ + _t334_Vˍt_t_ - (_t334_V_t_^2)*_t334_Vˍt_t_)*_tpg_,
    _t334_Vˍttt_t_ + (-_t334_Rˍtt_t_ - _t334_Vˍtt_t_ + (_t334_V_t_^2)*_t334_Vˍtt_t_ + (2//1)*_t334_V_t_*(_t334_Vˍt_t_^2))*_tpg_,
    -_t334_V_t_ + _tpa_ - _t334_R_t_*_tpb_ + _t334_Rˍt_t_*_tpg_,
    -_t334_Vˍt_t_ - _t334_Rˍt_t_*_tpb_ + _t334_Rˍtt_t_*_tpg_
]

