# Polynomial system saved on 2025-07-28T15:30:54.886
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:30:54.885
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
    -0.8398952835142469 + _t445_x2_t_,
    -0.5647872736918206 + _t445_x2ˍt_t_,
    1.4211129638248092 + _t445_x1_t_,
    -0.8398951832663824 + _t445_x1ˍt_t_,
    _t445_x1_t_ + _t445_x2ˍt_t_ + (-1 + _t445_x1_t_^2)*_t445_x2_t_*_tpb_,
    _t445_x1ˍt_t_ - _t445_x2_t_*_tpa_
]

