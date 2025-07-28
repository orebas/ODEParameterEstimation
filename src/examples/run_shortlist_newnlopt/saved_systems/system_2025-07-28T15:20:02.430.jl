# Polynomial system saved on 2025-07-28T15:20:02.431
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:02.430
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpc_
_t390_x1_t_
_t390_x2_t_
_t390_x2ˍt_t_
_t390_x1ˍt_t_
"""
@variables _tpa_ _tpc_ _t390_x1_t_ _t390_x2_t_ _t390_x2ˍt_t_ _t390_x1ˍt_t_
varlist = [_tpa__tpc__t390_x1_t__t390_x2_t__t390_x2ˍt_t__t390_x1ˍt_t_]

# Polynomial System
poly_system = [
    -6.222657299860289 + _t390_x2_t_,
    -0.6777342700139712 + _t390_x2ˍt_t_,
    -1.3554685400279418 + _t390_x1_t_,
    0.13554685400279531 + _t390_x1ˍt_t_,
    _t390_x2ˍt_t_ - _t390_x1_t_*(0.7052191713247161 + _tpc_),
    _t390_x1ˍt_t_ + _t390_x1_t_*_tpa_
]

