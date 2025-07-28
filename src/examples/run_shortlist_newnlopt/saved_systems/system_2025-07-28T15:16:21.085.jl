# Polynomial system saved on 2025-07-28T15:16:21.085
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:21.085
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
    -55.54242406756826 + _t278_x1_t_,
    -66.65097033040855 + _t278_x1ˍt_t_,
    _t278_x1ˍt_t_ + _t278_x1_t_*(-0.8620678761658627 - _tpb_)
]

