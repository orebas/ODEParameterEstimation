# Polynomial system saved on 2025-07-28T15:31:19.487
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:31:19.487
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t445_x1_t_
_t445_x2_t_
_t445_x2ˍt_t_
_t445_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t445_x1_t_ _t445_x2_t_ _t445_x2ˍt_t_ _t445_x1ˍt_t_
varlist = [_tpa__tpb__t445_x1_t__t445_x2_t__t445_x2ˍt_t__t445_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.839895313853978 + _t445_x2_t_,
    -0.564787580960127 + _t445_x2ˍt_t_,
    1.4211129565357061 + _t445_x1_t_,
    -0.8398953138541003 + _t445_x1ˍt_t_,
    _t445_x1_t_ + _t445_x2ˍt_t_ + (-1 + _t445_x1_t_^2)*_t445_x2_t_*_tpb_,
    _t445_x1ˍt_t_ - _t445_x2_t_*_tpa_
]

