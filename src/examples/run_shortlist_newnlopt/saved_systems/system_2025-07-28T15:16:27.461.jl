# Polynomial system saved on 2025-07-28T15:16:27.461
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:27.461
# num_equations: 3

# Variables
varlist_str = """
_tpb_
_t111_x1_t_
_t111_x1ˍt_t_
"""
@variables _tpb_ _t111_x1_t_ _t111_x1ˍt_t_
varlist = [_tpb__t111_x1_t__t111_x1ˍt_t_]

# Polynomial System
poly_system = [
    -7.486842754520038 + _t111_x1_t_,
    -8.984211305432098 + _t111_x1ˍt_t_,
    _t111_x1ˍt_t_ + _t111_x1_t_*(-0.9476713343821631 - _tpb_)
]

