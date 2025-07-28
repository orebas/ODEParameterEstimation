# Polynomial system saved on 2025-07-28T15:21:03.070
using Symbolics
using StaticArrays

# Metadata
# num_variables: 6
# timestamp: 2025-07-28T15:21:03.070
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
    -0.47349602917652156 + _t278_x2_t_,
    0.3762843593815389 + _t278_x2ˍt_t_,
    0.47035544731652107 + _t278_x1_t_,
    0.189398410516289 + _t278_x1ˍt_t_,
    _t278_x2ˍt_t_ - _t278_x1_t_*_tpb_,
    _t278_x1ˍt_t_ + _t278_x2_t_*_tpa_
]

