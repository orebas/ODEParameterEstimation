# Polynomial system saved on 2025-07-28T15:35:58.863
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:35:58.862
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
    -0.4716127304958344 + _t112_x2_t_,
    0.37704043761230294 + _t112_x2ˍt_t_,
    0.4713005601351701 + _t112_x1_t_,
    0.188645083689092 + _t112_x1ˍt_t_,
    _t112_x2ˍt_t_ - _t112_x1_t_*_tpb_,
    _t112_x1ˍt_t_ + _t112_x2_t_*_tpa_
]

