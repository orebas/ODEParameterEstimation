# Polynomial system saved on 2025-07-28T15:28:50.581
using Symbolics
using StaticArrays

# Metadata
# num_variables: 7
# timestamp: 2025-07-28T15:28:50.580
# num_equations: 7

# Variables
varlist_str = """
_tpa_
_tpb_
_t223_X_t_
_t223_Y_t_
_t223_Xˍt_t_
_t223_Xˍtt_t_
_t223_Yˍt_t_
"""
@variables _tpa_ _tpb_ _t223_X_t_ _t223_Y_t_ _t223_Xˍt_t_ _t223_Xˍtt_t_ _t223_Yˍt_t_
varlist = [_tpa__tpb__t223_X_t__t223_Y_t__t223_Xˍt_t__t223_Xˍtt_t__t223_Yˍt_t_]

# Polynomial System
poly_system = [
    -2.525586596542269 + _t223_Y_t_,
    -0.5764897673910943 + _t223_X_t_,
    0.4666038798670973 + _t223_Xˍt_t_,
    -0.8035392471446976 + _t223_Xˍtt_t_,
    -1.0 + _t223_Xˍt_t_ + _t223_X_t_*(1 + _tpb_) - (_t223_X_t_^2)*_t223_Y_t_*_tpa_,
    _t223_Xˍtt_t_ - _t223_Xˍt_t_*(-1 - _tpb_) - (_t223_X_t_^2)*_t223_Yˍt_t_*_tpa_ - 2_t223_X_t_*_t223_Xˍt_t_*_t223_Y_t_*_tpa_,
    _t223_Yˍt_t_ - _t223_X_t_*_tpb_ + (_t223_X_t_^2)*_t223_Y_t_*_tpa_
]

