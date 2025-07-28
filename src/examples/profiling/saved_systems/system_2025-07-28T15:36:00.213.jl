# Polynomial system saved on 2025-07-28T15:36:00.223
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:36:00.213
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t179_x1_t_
_t179_x2_t_
_t179_x2ˍt_t_
_t179_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t179_x1_t_ _t179_x2_t_ _t179_x2ˍt_t_ _t179_x1ˍt_t_
varlist = [_tpa__tpb__t179_x1_t__t179_x2_t__t179_x2ˍt_t__t179_x1ˍt_t_]

# Polynomial System
poly_system = [
    0.26591695986153396 + _t179_x2_t_,
    0.4366986347785005 + _t179_x2ˍt_t_,
    0.5458732317232353 + _t179_x1_t_,
    -0.10636678522063207 + _t179_x1ˍt_t_,
    _t179_x2ˍt_t_ - _t179_x1_t_*_tpb_,
    _t179_x1ˍt_t_ + _t179_x2_t_*_tpa_
]

