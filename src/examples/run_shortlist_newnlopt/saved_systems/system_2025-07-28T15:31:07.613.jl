# Polynomial system saved on 2025-07-28T15:31:07.613
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:31:07.613
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t223_x1_t_
_t223_x2_t_
_t223_x2ˍt_t_
_t223_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t223_x1_t_ _t223_x2_t_ _t223_x2ˍt_t_ _t223_x1ˍt_t_
varlist = [_tpa__tpb__t223_x1_t__t223_x2_t__t223_x2ˍt_t__t223_x1ˍt_t_]

# Polynomial System
poly_system = [
    2.2977170966755787 + _t223_x2_t_,
    2.128385690821176 + _t223_x2ˍt_t_,
    0.13031285839667628 + _t223_x1_t_,
    2.2977170966743143 + _t223_x1ˍt_t_,
    _t223_x1_t_ + _t223_x2ˍt_t_ + (-1 + _t223_x1_t_^2)*_t223_x2_t_*_tpb_,
    _t223_x1ˍt_t_ - _t223_x2_t_*_tpa_
]

