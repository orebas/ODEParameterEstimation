# Polynomial system saved on 2025-07-28T15:44:40.666
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:44:40.666
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t112_x1_t_
_t112_x2_t_
_t112_x2ˍt_t_
_t112_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t112_x1_t_ _t112_x2_t_ _t112_x2ˍt_t_ _t112_x1ˍt_t_
varlist = [_tpa__tpb__t112_x1_t__t112_x2_t__t112_x2ˍt_t__t112_x1ˍt_t_]

# Polynomial System
poly_system = [
    -0.47161272362835593 + _t112_x2_t_,
    0.377040433724994 + _t112_x2ˍt_t_,
    0.4713006019157112 + _t112_x1_t_,
    0.18864509384275782 + _t112_x1ˍt_t_,
    _t112_x2ˍt_t_ - _t112_x1_t_*_tpb_,
    _t112_x1ˍt_t_ + _t112_x2_t_*_tpa_
]

