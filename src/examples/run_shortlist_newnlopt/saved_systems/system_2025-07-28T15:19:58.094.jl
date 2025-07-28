# Polynomial system saved on 2025-07-28T15:19:58.094
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:19:58.094
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
    -6.222657295109734 + _t390_x2_t_,
    -0.6777342717166128 + _t390_x2ˍt_t_,
    -1.3554685379925386 + _t390_x1_t_,
    0.1355468508656638 + _t390_x1ˍt_t_,
    _t390_x2ˍt_t_ + _t390_x1_t_*(-0.15032128793039634 - _tpc_),
    _t390_x1ˍt_t_ + _t390_x1_t_*_tpa_
]

