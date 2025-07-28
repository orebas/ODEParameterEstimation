# Polynomial system saved on 2025-07-28T15:16:25.776
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:25.776
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
    -212.9691235118308 + _t390_x1_t_,
    -255.56300828417898 + _t390_x1ˍt_t_,
    _t390_x1ˍt_t_ + _t390_x1_t_*(-0.6633326527500267 - _tpb_)
]

