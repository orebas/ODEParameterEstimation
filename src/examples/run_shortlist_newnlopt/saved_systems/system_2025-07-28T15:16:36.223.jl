# Polynomial system saved on 2025-07-28T15:16:36.223
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:36.223
# num_equations: 3

# Variables
varlist_str = """
_tpb_
_t334_x1_t_
_t334_x1ˍt_t_
"""
@variables _tpb_ _t334_x1_t_ _t334_x1ˍt_t_
varlist = [_tpb__t334_x1_t__t334_x1ˍt_t_]

# Polynomial System
poly_system = [
    -108.76038568597764 + _t334_x1_t_,
    -130.5124841092616 + _t334_x1ˍt_t_,
    _t334_x1ˍt_t_ + _t334_x1_t_*(-0.3619374158335672 - _tpb_)
]

