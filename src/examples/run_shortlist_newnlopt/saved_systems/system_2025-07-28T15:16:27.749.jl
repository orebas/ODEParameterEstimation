# Polynomial system saved on 2025-07-28T15:16:27.749
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:27.749
# num_equations: 3

# Variables
varlist_str = """
_tpb_
_t501_x1_t_
_t501_x1ˍt_t_
"""
@variables _tpb_ _t501_x1_t_ _t501_x1ˍt_t_
varlist = [_tpb__t501_x1_t__t501_x1ˍt_t_]

# Polynomial System
poly_system = [
    -806.85758698547 + _t501_x1_t_,
    -968.2291043848718 + _t501_x1ˍt_t_,
    _t501_x1ˍt_t_ + _t501_x1_t_*(-0.7940131631304627 - _tpb_)
]

