# Polynomial system saved on 2025-07-28T15:30:42.055
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:30:42.055
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
    2.297717049625693 + _t223_x2_t_,
    2.128384526655786 + _t223_x2ˍt_t_,
    0.1303128601643989 + _t223_x1_t_,
    2.297716804540255 + _t223_x1ˍt_t_,
    _t223_x1_t_ + _t223_x2ˍt_t_ + (-1 + _t223_x1_t_^2)*_t223_x2_t_*_tpb_,
    _t223_x1ˍt_t_ - _t223_x2_t_*_tpa_
]

