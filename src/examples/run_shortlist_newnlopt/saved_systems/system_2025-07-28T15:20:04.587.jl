# Polynomial system saved on 2025-07-28T15:20:04.588
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:04.587
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
    -3.5351485319760148 + _t56_x2_t_,
    -0.9464850409197066 + _t56_x2ˍt_t_,
    -1.8929702935545027 + _t56_x1_t_,
    0.1892970041487321 + _t56_x1ˍt_t_,
    _t56_x2ˍt_t_ - _t56_x1_t_*(0.04273127235841612 + _tpc_),
    _t56_x1ˍt_t_ + _t56_x1_t_*_tpa_
]

