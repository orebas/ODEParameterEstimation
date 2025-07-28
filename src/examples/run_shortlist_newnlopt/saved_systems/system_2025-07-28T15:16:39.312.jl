# Polynomial system saved on 2025-07-28T15:16:39.312
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:39.312
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
    -806.8574902034613 + _t501_x1_t_,
    -968.221451639863 + _t501_x1ˍt_t_,
    _t501_x1ˍt_t_ - _t501_x1_t_*(0.5009099954906778 + _tpb_)
]

