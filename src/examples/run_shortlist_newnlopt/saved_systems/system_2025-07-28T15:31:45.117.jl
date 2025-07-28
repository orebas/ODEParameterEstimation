# Polynomial system saved on 2025-07-28T15:31:45.117
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:31:45.117
# num_equations: 6

# Variables
varlist_str = """
_tpa_
_tpb_
_t278_x1_t_
_t278_x2_t_
_t278_x2ˍt_t_
_t278_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _t278_x1_t_ _t278_x2_t_ _t278_x2ˍt_t_ _t278_x1ˍt_t_
varlist = [_tpa__tpb__t278_x1_t__t278_x2_t__t278_x2ˍt_t__t278_x1ˍt_t_]

# Polynomial System
poly_system = [
    2.077685830499022 + _t278_x2_t_,
    -4.161238402786566 + _t278_x2ˍt_t_,
    1.5088439143316967 + _t278_x1_t_,
    2.077685979567843 + _t278_x1ˍt_t_,
    _t278_x1_t_ + _t278_x2ˍt_t_ + (-1 + _t278_x1_t_^2)*_t278_x2_t_*_tpb_,
    _t278_x1ˍt_t_ - _t278_x2_t_*_tpa_
]

