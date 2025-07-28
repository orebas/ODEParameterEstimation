# Polynomial system saved on 2025-07-28T15:16:37.702
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:37.702
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
    -412.0510203418715 + _t445_x1_t_,
    -494.4612198820785 + _t445_x1ˍt_t_,
    _t445_x1ˍt_t_ - _t445_x1_t_*(0.8533008992199557 + _tpb_)
]

