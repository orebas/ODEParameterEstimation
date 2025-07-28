# Polynomial system saved on 2025-07-28T15:35:56.788
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:35:56.788
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t22_x1_t_
_t22_x2_t_
_t22_x2ˍt_t_
_t22_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t22_x1_t_ _t22_x2_t_ _t22_x2ˍt_t_ _t22_x1ˍt_t_
varlist = [_tpa__tpb__t22_x1_t__t22_x2_t__t22_x2ˍt_t__t22_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.7756139668735023 + _t22_x2_t_,
    -0.1443218455223198 + _t22_x2ˍt_t_,
    -0.18040228644608447 + _t22_x1_t_,
    0.3102455938493673 + _t22_x1ˍt_t_,
    _t22_x2ˍt_t_ - _t22_x1_t_*_tpb_,
    _t22_x1ˍt_t_ + _t22_x2_t_*_tpa_
]

