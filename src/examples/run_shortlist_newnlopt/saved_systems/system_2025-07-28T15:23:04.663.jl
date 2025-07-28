# Polynomial system saved on 2025-07-28T15:23:04.663
using Symbolics
using StaticArrays

# Metadata
# num_variables: 17
# timestamp: 2025-07-28T15:23:04.663
# num_equations: 18

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
_t111_Rˍt_t_
_t111_Rˍtt_t_
_t278_V_t_
_t278_R_t_
_t278_Vˍt_t_
_t278_Vˍtt_t_
_t278_Vˍttt_t_
_t278_Rˍt_t_
_t278_Rˍtt_t_
"""
@variables _tpg_ _tpa_ _tpb_ _t111_V_t_ _t111_R_t_ _t111_Vˍt_t_ _t111_Vˍtt_t_ _t111_Vˍttt_t_ _t111_Rˍt_t_ _t111_Rˍtt_t_ _t278_V_t_ _t278_R_t_ _t278_Vˍt_t_ _t278_Vˍtt_t_ _t278_Vˍttt_t_ _t278_Rˍt_t_ _t278_Rˍtt_t_
varlist = [_tpg__tpa__tpb__t111_V_t__t111_R_t__t111_Vˍt_t__t111_Vˍtt_t__t111_Vˍttt_t__t111_Rˍt_t__t111_Rˍtt_t__t278_V_t__t278_R_t__t278_Vˍt_t__t278_Vˍtt_t__t278_Vˍttt_t__t278_Rˍt_t__t278_Rˍtt_t_]

# Polynomial System
poly_system = [
    1.0132250786522015 + _t111_V_t_,
    2.0074384040986724 + _t111_Vˍt_t_,
    1.0533003996523556 + _t111_Vˍtt_t_,
    -22.54912272273352 + _t111_Vˍttt_t_,
    _t111_Vˍt_t_ - (_t111_R_t_ + _t111_V_t_ - (1//3)*(_t111_V_t_^3))*_tpg_,
    _t111_Vˍtt_t_ - (_t111_Rˍt_t_ + _t111_Vˍt_t_ - (_t111_V_t_^2)*_t111_Vˍt_t_)*_tpg_,
    _t111_Vˍttt_t_ + (-_t111_Rˍtt_t_ - _t111_Vˍtt_t_ + (_t111_V_t_^2)*_t111_Vˍtt_t_ + (2//1)*_t111_V_t_*(_t111_Vˍt_t_^2))*_tpg_,
    -_t111_V_t_ + _tpa_ - _t111_R_t_*_tpb_ + _t111_Rˍt_t_*_tpg_,
    -_t111_Vˍt_t_ - _t111_Rˍt_t_*_tpb_ + _t111_Rˍtt_t_*_tpg_,
    1.0333886861418249 + _t278_V_t_,
    2.0168506238765698 + _t278_Vˍt_t_,
    0.8239923750266166 + _t278_Vˍtt_t_,
    -23.289252318374423 + _t278_Vˍttt_t_,
    _t278_Vˍt_t_ - (_t278_R_t_ + _t278_V_t_ - (1//3)*(_t278_V_t_^3))*_tpg_,
    _t278_Vˍtt_t_ - (_t278_Rˍt_t_ + _t278_Vˍt_t_ - (_t278_V_t_^2)*_t278_Vˍt_t_)*_tpg_,
    _t278_Vˍttt_t_ + (-_t278_Rˍtt_t_ - _t278_Vˍtt_t_ + (_t278_V_t_^2)*_t278_Vˍtt_t_ + (2//1)*_t278_V_t_*(_t278_Vˍt_t_^2))*_tpg_,
    -_t278_V_t_ + _tpa_ - _t278_R_t_*_tpb_ + _t278_Rˍt_t_*_tpg_,
    -_t278_Vˍt_t_ - _t278_Rˍt_t_*_tpb_ + _t278_Rˍtt_t_*_tpg_
]

