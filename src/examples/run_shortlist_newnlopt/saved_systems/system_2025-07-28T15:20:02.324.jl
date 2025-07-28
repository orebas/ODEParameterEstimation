# Polynomial system saved on 2025-07-28T15:20:02.324
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:02.324
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpc_
_t334_x1_t_
_t334_x2_t_
_t334_x2ˍt_t_
_t334_x1ˍt_t_
"""
@variables _tpa_ _tpc_ _t334_x1_t_ _t334_x2_t_ _t334_x2ˍt_t_ _t334_x1ˍt_t_
varlist = [_tpa__tpc__t334_x1_t__t334_x2_t__t334_x2ˍt_t__t334_x1ˍt_t_]

# Polynomial System
poly_system = [
    -5.832298058442998 + _t334_x2_t_,
    -0.7167701941557099 + _t334_x2ˍt_t_,
    -1.4335403883114006 + _t334_x1_t_,
    0.14335403883114192 + _t334_x1ˍt_t_,
    _t334_x2ˍt_t_ - _t334_x1_t_*(0.16684508860577074 + _tpc_),
    _t334_x1ˍt_t_ + _t334_x1_t_*_tpa_
]

