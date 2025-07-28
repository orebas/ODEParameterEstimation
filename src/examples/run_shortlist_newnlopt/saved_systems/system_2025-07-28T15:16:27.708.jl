# Polynomial system saved on 2025-07-28T15:16:27.709
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:27.708
# num_equations: 3

# Variables
varlist_str = """
_tpb_
_t445_x1_t_
_t445_x1ˍt_t_
"""
@variables _tpb_ _t445_x1_t_ _t445_x1ˍt_t_
varlist = [_tpb__t445_x1_t__t445_x1ˍt_t_]

# Polynomial System
poly_system = [
    -412.0510216176746 + _t445_x1_t_,
    -494.4612259410369 + _t445_x1ˍt_t_,
    _t445_x1ˍt_t_ - _t445_x1_t_*(0.9943841219959968 + _tpb_)
]

