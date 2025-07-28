# Polynomial system saved on 2025-07-28T15:20:36.026
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:36.025
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
    0.012204031579693853 + _t390_x2_t_,
    0.46182872357582444 + _t390_x2ˍt_t_,
    0.5772859169524249 + _t390_x1_t_,
    -0.004881617193235945 + _t390_x1ˍt_t_,
    _t390_x2ˍt_t_ - _t390_x1_t_*_tpb_,
    _t390_x1ˍt_t_ + _t390_x2_t_*_tpa_
]

