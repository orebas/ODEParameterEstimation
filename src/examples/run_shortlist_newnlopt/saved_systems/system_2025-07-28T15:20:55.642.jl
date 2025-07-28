# Polynomial system saved on 2025-07-28T15:20:55.642
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:55.642
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t445_x1_t_
_t445_x2_t_
_t445_x2ˍt_t_
_t445_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t445_x1_t_ _t445_x2_t_ _t445_x2ˍt_t_ _t445_x1ˍt_t_
varlist = [_tpa__tpb__t445_x1_t__t445_x2_t__t445_x2ˍt_t__t445_x1ˍt_t_]

# Polynomial System
poly_system = [
    0.2615457350000505 + _t445_x2_t_,
    0.4375425297533866 + _t445_x2ˍt_t_,
    0.5469281618747055 + _t445_x1_t_,
    -0.1046182940074516 + _t445_x1ˍt_t_,
    _t445_x2ˍt_t_ - _t445_x1_t_*_tpb_,
    _t445_x1ˍt_t_ + _t445_x2_t_*_tpa_
]

