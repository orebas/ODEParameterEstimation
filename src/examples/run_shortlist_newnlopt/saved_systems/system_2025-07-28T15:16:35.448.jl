# Polynomial system saved on 2025-07-28T15:16:35.449
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:35.448
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
    -55.54242297182125 + _t278_x1_t_,
    -66.65095908580399 + _t278_x1ˍt_t_,
    _t278_x1ˍt_t_ + _t278_x1_t_*(-0.5705079469457601 - _tpb_)
]

