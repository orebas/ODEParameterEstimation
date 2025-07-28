# Polynomial system saved on 2025-07-28T15:20:20.360
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:20.359
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
    -6.222657342147004 + _t390_x2_t_,
    -0.6777342516811953 + _t390_x2ˍt_t_,
    -1.3554685350542224 + _t390_x1_t_,
    0.13554685671580718 + _t390_x1ˍt_t_,
    _t390_x2ˍt_t_ - _t390_x1_t_*(0.5430455225803739 + _tpc_),
    _t390_x1ˍt_t_ + _t390_x1_t_*_tpa_
]

