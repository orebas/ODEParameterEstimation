# Polynomial system saved on 2025-07-28T15:19:23.665
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:19:23.665
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpc_
_t56_x1_t_
_t56_x2_t_
_t56_x2ˍt_t_
_t56_x1ˍt_t_
"""
@variables _tpa_ _tpc_ _t56_x1_t_ _t56_x2_t_ _t56_x2ˍt_t_ _t56_x1ˍt_t_
varlist = [_tpa__tpc__t56_x1_t__t56_x2_t__t56_x2ˍt_t__t56_x1ˍt_t_]

# Polynomial System
poly_system = [
    -3.535148526865771 + _t56_x2_t_,
    -0.9464850432773012 + _t56_x2ˍt_t_,
    -1.8929702941255788 + _t56_x1_t_,
    0.1892970059669752 + _t56_x1ˍt_t_,
    _t56_x2ˍt_t_ - _t56_x1_t_*(0.5509079900466128 + _tpc_),
    _t56_x1ˍt_t_ + _t56_x1_t_*_tpa_
]

