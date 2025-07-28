# Polynomial system saved on 2025-07-28T15:16:22.139
using Symbolics
using StaticArrays

# Metadata
# num_variables: 3
# timestamp: 2025-07-28T15:16:22.139
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
    -108.76038629278094 + _t334_x1_t_,
    -130.51244821130774 + _t334_x1ˍt_t_,
    _t334_x1ˍt_t_ + _t334_x1_t_*(-0.8035167288335747 - _tpb_)
]

