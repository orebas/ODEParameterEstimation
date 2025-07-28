# Polynomial system saved on 2025-07-28T15:20:14.422
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:20:14.422
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpc_
_t278_x1_t_
_t278_x2_t_
_t278_x2ˍt_t_
_t278_x1ˍt_t_
"""
@variables _tpa_ _tpc_ _t278_x1_t_ _t278_x2_t_ _t278_x2ˍt_t_ _t278_x1ˍt_t_
varlist = [_tpa__tpc__t278_x1_t__t278_x2_t__t278_x2ˍt_t__t278_x1ˍt_t_]

# Polynomial System
poly_system = [
    -5.419454993299118 + _t278_x2_t_,
    -0.7580545050123424 + _t278_x2ˍt_t_,
    -1.5161089893698287 + _t278_x1_t_,
    0.1516108972191496 + _t278_x1ˍt_t_,
    _t278_x2ˍt_t_ + _t278_x1_t_*(-0.5852341860632426 - _tpc_),
    _t278_x1ˍt_t_ + _t278_x1_t_*_tpa_
]

