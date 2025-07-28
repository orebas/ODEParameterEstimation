# Polynomial system saved on 2025-07-28T15:10:04.079
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:10:04.078
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t278_x1_t_
_t278_x2_t_
_t278_x3_t_
_t278_x2ˍt_t_
_t278_x3ˍt_t_
_t278_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t278_x1_t_ _t278_x2_t_ _t278_x3_t_ _t278_x2ˍt_t_ _t278_x3ˍt_t_ _t278_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t278_x1_t__t278_x2_t__t278_x3_t__t278_x2ˍt_t__t278_x3ˍt_t__t278_x1ˍt_t_]

# Polynomial System
poly_system = [
    -9.215945037690364 + _t278_x2_t_^3,
    3.4365809367377445 + 3(_t278_x2_t_^2)*_t278_x2ˍt_t_,
    -18.502040041111535 + _t278_x3_t_^3,
    8.20359647746737 + 3(_t278_x3_t_^2)*_t278_x3ˍt_t_,
    -2.212310841233303 + _t278_x1_t_^3,
    1.0679037105521554 + 3(_t278_x1_t_^2)*_t278_x1ˍt_t_,
    _t278_x2ˍt_t_ + _t278_x1_t_*_tpb_,
    _t278_x3ˍt_t_ + _t278_x1_t_*_tpc_,
    _t278_x1ˍt_t_ + _t278_x2_t_*_tpa_
]

