# Polynomial system saved on 2025-07-28T15:16:37.045
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:37.045
# num_equations: 3

# Variables
varlist_str = """
_tpb_
_t390_x1_t_
_t390_x1ˍt_t_
"""
@variables _tpb_ _t390_x1_t_ _t390_x1ˍt_t_
varlist = [_tpb__t390_x1_t__t390_x1ˍt_t_]

# Polynomial System
poly_system = [
    -212.96912190326844 + _t390_x1_t_,
    -255.5629441185386 + _t390_x1ˍt_t_,
    _t390_x1ˍt_t_ + _t390_x1_t_*(-0.9807033981185094 - _tpb_)
]

