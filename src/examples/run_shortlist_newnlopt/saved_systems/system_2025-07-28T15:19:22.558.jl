# Polynomial system saved on 2025-07-28T15:19:22.559
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:19:22.558
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
    -3.535148536749816 + _t56_x2_t_,
    -0.9464850232087946 + _t56_x2ˍt_t_,
    -1.892970293642147 + _t56_x1_t_,
    0.18929700531098487 + _t56_x1ˍt_t_,
    _t56_x2ˍt_t_ + _t56_x1_t_*(-0.8677602926729933 - _tpc_),
    _t56_x1ˍt_t_ + _t56_x1_t_*_tpa_
]

