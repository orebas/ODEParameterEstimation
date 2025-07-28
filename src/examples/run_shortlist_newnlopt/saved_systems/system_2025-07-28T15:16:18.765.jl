# Polynomial system saved on 2025-07-28T15:16:18.765
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:18.765
# num_equations: 3

# Variables
varlist_str = """
_tpb_
_t167_x1_t_
_t167_x1ˍt_t_
"""
@variables _tpb_ _t167_x1_t_ _t167_x1ˍt_t_
varlist = [_tpb__t167_x1_t__t167_x1ˍt_t_]

# Polynomial System
poly_system = [
    -14.660358611149462 + _t167_x1_t_,
    -17.592439111733256 + _t167_x1ˍt_t_,
    _t167_x1ˍt_t_ + _t167_x1_t_*(-0.9807490285968381 - _tpb_)
]

