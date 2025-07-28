# Polynomial system saved on 2025-07-28T15:31:15.608
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:31:15.607
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t390_x1_t_
_t390_x2_t_
_t390_x2ˍt_t_
_t390_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t390_x1_t_ _t390_x2_t_ _t390_x2ˍt_t_ _t390_x1ˍt_t_
varlist = [_tpa__tpb__t390_x1_t__t390_x2_t__t390_x2ˍt_t__t390_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.5708452796225951 + _t390_x2_t_,
    -0.513294047109486 + _t390_x2ˍt_t_,
    1.807563549522954 + _t390_x1_t_,
    -0.570845279622489 + _t390_x1ˍt_t_,
    _t390_x1_t_ + _t390_x2ˍt_t_ + (-1 + _t390_x1_t_^2)*_t390_x2_t_*_tpb_,
    _t390_x1ˍt_t_ - _t390_x2_t_*_tpa_
]

