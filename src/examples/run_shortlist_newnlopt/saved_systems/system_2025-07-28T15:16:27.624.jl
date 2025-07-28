# Polynomial system saved on 2025-07-28T15:16:27.624
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:27.624
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
    -108.76038727281922 + _t334_x1_t_,
    -130.51246472745277 + _t334_x1ˍt_t_,
    _t334_x1ˍt_t_ + _t334_x1_t_*(-0.250486127667367 - _tpb_)
]

