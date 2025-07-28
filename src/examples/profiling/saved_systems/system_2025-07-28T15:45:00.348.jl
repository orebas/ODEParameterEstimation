# Polynomial system saved on 2025-07-28T15:45:00.348
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:45:00.348
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
    -0.47161272200287724 + _t112_x2_t_,
    0.3770404530820809 + _t112_x2ˍt_t_,
    0.4713005522417745 + _t112_x1_t_,
    0.18864509503444302 + _t112_x1ˍt_t_,
    _t112_x2ˍt_t_ - _t112_x1_t_*_tpb_,
    _t112_x1ˍt_t_ + _t112_x2_t_*_tpa_
]

