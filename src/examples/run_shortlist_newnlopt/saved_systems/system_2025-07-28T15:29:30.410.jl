# Polynomial system saved on 2025-07-28T15:29:30.410
using Symbolics
using StaticArrays

# Metadata
# num_variables: 8
# timestamp: 2025-07-28T15:29:30.410
# num_equations: 8

# Variables
varlist_str = """
_tpa_
_tpb_
_t56_X_t_
_t56_Y_t_
_t56_Xˍt_t_
_t223_X_t_
_t223_Y_t_
_t223_Xˍt_t_
"""
@variables _tpa_ _tpb_ _t56_X_t_ _t56_Y_t_ _t56_Xˍt_t_ _t223_X_t_ _t223_Y_t_ _t223_Xˍt_t_
varlist = [_tpa__tpb__t56_X_t__t56_Y_t__t56_Xˍt_t__t223_X_t__t223_Y_t__t223_Xˍt_t_]

# Polynomial System
poly_system = [
    -2.9690622307029217 + _t56_Y_t_,
    -0.3209046725638546 + _t56_X_t_,
    -0.022134431613513358 + _t56_Xˍt_t_,
    -1.0 + _t56_Xˍt_t_ + _t56_X_t_*(1 + _tpb_) - (_t56_X_t_^2)*_t56_Y_t_*_tpa_,
    -2.5255865883161293 + _t223_Y_t_,
    -0.5764897604728138 + _t223_X_t_,
    0.4666041777763686 + _t223_Xˍt_t_,
    -1.0 + _t223_Xˍt_t_ + _t223_X_t_*(1 + _tpb_) - (_t223_X_t_^2)*_t223_Y_t_*_tpa_
]

