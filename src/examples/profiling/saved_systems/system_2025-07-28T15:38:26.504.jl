# Polynomial system saved on 2025-07-28T15:38:26.504
using Symbolics
using StaticArrays

# Metadata
# num_variables: 9
# timestamp: 2025-07-28T15:38:26.504
# num_equations: 9

# Variables
varlist_str = """
_tpa_
_tpb_
_tpc_
_t22_x1_t_
_t22_x2_t_
_t22_x3_t_
_t22_x2ˍt_t_
_t22_x3ˍt_t_
_t22_x1ˍt_t_
"""
@variables _tpa_ _tpb_ _tpc_ _t22_x1_t_ _t22_x2_t_ _t22_x3_t_ _t22_x2ˍt_t_ _t22_x3ˍt_t_ _t22_x1ˍt_t_
varlist = [_tpa__tpb__tpc__t22_x1_t__t22_x2_t__t22_x3_t__t22_x2ˍt_t__t22_x3ˍt_t__t22_x1ˍt_t_]

# Polynomial System
poly_system = [
    -21.90686239679946 + _t22_x2_t_^3,
    8.680460120516006 + 3(_t22_x2_t_^2)*_t22_x2ˍt_t_,
    -50.53478261009836 + _t22_x3_t_^3,
    22.732160756315665 + 3(_t22_x3_t_^2)*_t22_x3ˍt_t_,
    -6.309783261084283 + _t22_x1_t_^3,
    2.8663159845393373 + 3(_t22_x1_t_^2)*_t22_x1ˍt_t_,
    _t22_x2ˍt_t_ + _t22_x1_t_*_tpb_,
    _t22_x3ˍt_t_ + _t22_x1_t_*_tpc_,
    _t22_x1ˍt_t_ + _t22_x2_t_*_tpa_
]

