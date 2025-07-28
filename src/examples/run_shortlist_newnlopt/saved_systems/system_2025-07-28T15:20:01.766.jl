# Polynomial system saved on 2025-07-28T15:20:01.766
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:01.766
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
    -3.535148520465175 + _t56_x2_t_,
    -0.946485147953573 + _t56_x2ˍt_t_,
    -1.8929702959069652 + _t56_x1_t_,
    0.18929702959071504 + _t56_x1ˍt_t_,
    _t56_x2ˍt_t_ + _t56_x1_t_*(-0.3118827708019427 - _tpc_),
    _t56_x1ˍt_t_ + _t56_x1_t_*_tpa_
]

