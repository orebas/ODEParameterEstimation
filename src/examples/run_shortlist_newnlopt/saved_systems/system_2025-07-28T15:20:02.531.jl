# Polynomial system saved on 2025-07-28T15:20:02.531
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:02.531
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpc_
_t445_x1_t_
_t445_x2_t_
_t445_x2ˍt_t_
_t445_x1ˍt_t_
"""
@variables _tpa_ _tpc_ _t445_x1_t_ _t445_x2_t_ _t445_x2ˍt_t_ _t445_x1ˍt_t_
varlist = [_tpa__tpc__t445_x1_t__t445_x2_t__t445_x2ˍt_t__t445_x1ˍt_t_]

# Polynomial System
poly_system = [
    -6.585345791726741 + _t445_x2_t_,
    -0.6414654208271191 + _t445_x2ˍt_t_,
    -1.2829308416546517 + _t445_x1_t_,
    0.1282930841654244 + _t445_x1ˍt_t_,
    _t445_x2ˍt_t_ - _t445_x1_t_*(0.9889560001051162 + _tpc_),
    _t445_x1ˍt_t_ + _t445_x1_t_*_tpa_
]

