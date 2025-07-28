# Polynomial system saved on 2025-07-28T15:19:51.009
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:19:51.008
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpc_
_t223_x1_t_
_t223_x2_t_
_t223_x2ˍt_t_
_t223_x1ˍt_t_
"""
@variables _tpa_ _tpc_ _t223_x1_t_ _t223_x2_t_ _t223_x2ˍt_t_ _t223_x1ˍt_t_
varlist = [_tpa__tpc__t223_x1_t__t223_x2_t__t223_x2ˍt_t__t223_x1ˍt_t_]

# Polynomial System
poly_system = [
    -4.9908463516577575 + _t223_x2_t_,
    -0.8009154091278731 + _t223_x2ˍt_t_,
    -1.6018307287139482 + _t223_x1_t_,
    0.16018307767455373 + _t223_x1ˍt_t_,
    _t223_x2ˍt_t_ + _t223_x1_t_*(-0.3589703731055983 - _tpc_),
    _t223_x1ˍt_t_ + _t223_x1_t_*_tpa_
]

