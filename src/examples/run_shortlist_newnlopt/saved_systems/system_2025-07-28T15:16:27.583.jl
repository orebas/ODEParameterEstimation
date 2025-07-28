# Polynomial system saved on 2025-07-28T15:16:27.583
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:27.583
# num_equations: 3

# Variables
varlist_str = """
_tpb_
_t278_x1_t_
_t278_x1ˍt_t_
"""
@variables _tpb_ _t278_x1_t_ _t278_x1ˍt_t_
varlist = [_tpb__t278_x1_t__t278_x1ˍt_t_]

# Polynomial System
poly_system = [
    -55.542427077797164 + _t278_x1_t_,
    -66.65091249328364 + _t278_x1ˍt_t_,
    _t278_x1ˍt_t_ + _t278_x1_t_*(-0.9339308173438567 - _tpb_)
]

